defmodule LojaVirtual.Pipelines.OrdersPaidPipeline do
  @moduledoc """
  =============================================================================
  BROADWAY PIPELINE: Roteador de Pedidos (Router Worker)
  =============================================================================

  📌 PROPÓSITO DESTE PIPELINE:
  ----------------------------
  Este é um pipeline de "roteamento" - ele NÃO processa os pedidos em si,
  mas DECIDE para onde cada pedido deve ir baseado no seu tipo.

  📌 FLUXO DO PIPELINE:
  ---------------------
  1. CONSOME mensagens do tópico: "orders.paid"
     (Pedidos que já tiveram o pagamento aprovado)

  2. ANALISA o tipo do pedido:
     - "pronto": Produto já pronto no estoque
     - "personalizado": Produto precisa ser preparado/customizado

  3. ROTEIA para o tópico apropriado:
     - Pronto → "stock.product.check" (verificar estoque de produtos)
     - Personalizado → "stock.ingredient.check" (verificar ingredientes)

  📌 PADRÃO DE ARQUITETURA:
  -------------------------
  Este é um exemplo do padrão "Router" em arquitetura de mensageria.
  Vantagens:
  - Desacoplamento: Cada worker só conhece seu próprio domínio
  - Flexibilidade: Fácil adicionar novos tipos de pedido
  - Escalabilidade: Cada downstream pode escalar independentemente

  📌 ANALOGIA COM O MUNDO REAL:
  -----------------------------
  Pense em um centro de distribuição:
  - Pacote chega → Funcionário olha a etiqueta → Manda para a esteira certa
  - Aqui: Pedido chega → Verificamos o tipo → Enviamos para o tópico certo

  Consumes: orders.paid
  Publishes: stock.product.check OR stock.ingredient.check
  """
  use Broadway

  require Logger

  alias Broadway.Message
  alias LojaVirtual.Kafka.{Topics, Producer, Config}

  # =============================================================================
  # INICIALIZAÇÃO DO PIPELINE
  # =============================================================================

  @doc """
  Inicia o pipeline de roteamento.

  📌 NOTA SOBRE CONFIGURAÇÃO:
  Este pipeline é mais simples que o de pagamento:
  - Não usa batchers (não há necessidade de agrupar roteamentos)
  - Processamento rápido (apenas decisão de roteamento)
  """
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,

      # =========================================================================
      # PRODUCER: Consome do tópico "orders.paid"
      # =========================================================================
      producer: [
        module: {
          BroadwayKafka.Producer,
          [
            hosts: Config.hosts(),

            # Consumer group diferente do pipeline de pagamento
            # Isso significa que este processo é INDEPENDENTE
            # Cada grupo mantém seu próprio offset
            group_id: "router_group",

            topics: [Topics.orders_paid()],

            # Commita o offset automaticamente quando Broadway
            # confirma que a mensagem foi processada
            offset_commit_on_ack: true
          ]
        },
        concurrency: 1
      ],

      # =========================================================================
      # PROCESSORS: Roteamento é rápido, 2 workers são suficientes
      # =========================================================================
      processors: [
        default: [concurrency: 2]
      ]

      # 📌 NOTA: Não temos batchers aqui!
      # Roteamento é uma operação instantânea, não faz sentido agrupar.
      # Cada mensagem é roteada imediatamente após o processamento.
    )
  end

  # =============================================================================
  # CALLBACK DE PROCESSAMENTO
  # =============================================================================

  @doc """
  Processa cada pedido pago e roteia para o destino apropriado.

  📌 FLUXO:
  1. Decodifica a mensagem JSON
  2. Chama route_order/1 que decide o destino
  3. Retorna a mensagem para confirmar o processamento
  """
  @impl true
  def handle_message(_processor, %Message{data: data} = message, _context) do
    case Jason.decode(data) do
      {:ok, order_data} ->
        # O roteamento propriamente dito acontece aqui
        route_order(order_data)
        message

      {:error, reason} ->
        Logger.error("[Router] Decode error: #{inspect(reason)}")
        Message.failed(message, reason)
    end
  end

  # =============================================================================
  # FUNÇÕES DE ROTEAMENTO (Pattern Matching em ação!)
  # =============================================================================

  @doc false
  @doc """
  Roteia pedidos do tipo "PRONTO" (produtos prontos no estoque).

  📌 PATTERN MATCHING:
  Esta cláusula só é executada quando:
  - O map contém a chave "id"
  - O map contém a chave "type" com valor "pronto"

  Elixir tenta as cláusulas na ordem em que são definidas.
  A primeira que "encaixa" no padrão é executada.

  📌 EXEMPLO DE PEDIDO PRONTO:
  - Camiseta já confeccionada
  - Livro em estoque
  - Eletrônico na prateleira
  """
  defp route_order(%{"id" => order_id, "type" => "pronto"} = order_data) do
    Logger.info("[Router] Order #{order_id} is PRONTO -> stock.product.check")

    # Publica para o tópico de verificação de estoque de produtos
    # O worker que consome este tópico irá verificar se o produto
    # está disponível no estoque
    Producer.publish(Topics.stock_product_check(), order_id, order_data)
  end

  @doc false
  @doc """
  Roteia pedidos do tipo "PERSONALIZADO" (precisam ser preparados).

  📌 DIFERENÇA DO TIPO PRONTO:
  Produtos personalizados precisam de ingredientes/materiais para serem
  fabricados. Por isso, vão para um tópico diferente.

  📌 EXEMPLO DE PEDIDO PERSONALIZADO:
  - Pizza com ingredientes escolhidos
  - Camiseta com estampa customizada
  - Móvel sob medida
  """
  defp route_order(%{"id" => order_id, "type" => "personalizado"} = order_data) do
    Logger.info("[Router] Order #{order_id} is PERSONALIZADO -> stock.ingredient.check")

    # Publica para o tópico de verificação de ingredientes
    # Este tópico geralmente leva a um pipeline de "cozinha" ou "fabricação"
    Producer.publish(Topics.stock_ingredient_check(), order_id, order_data)
  end

  @doc false
  @doc """
  Cláusula "catch-all" - captura qualquer pedido que não encaixou acima.

  📌 IMPORTÂNCIA DO CATCH-ALL:
  Se um pedido chegar com um tipo desconhecido (ex: "type" => "dropship"),
  esta cláusula evita um erro de "no function clause matching".

  📌 EM PRODUÇÃO, VOCÊ DEVERIA:
  - Publicar em uma Dead Letter Queue (DLQ)
  - Enviar alerta para equipe de desenvolvimento
  - Retornar Message.failed/2 para retry ou análise

  📌 O UNDERSCORE (_):
  O _ em Elixir significa "não me importo com este valor".
  Aqui, captura qualquer dado que não encaixou nos padrões anteriores.
  """
  defp route_order(data) do
    Logger.error("[Router] Invalid order data: #{inspect(data)}")
    # Em produção, considere publicar em uma DLQ
  end
end
