defmodule LojaVirtual.Pipelines.OrdersNewPipeline do
  @moduledoc """
  =============================================================================
  BROADWAY PIPELINE: Processador de Pagamentos (Pagamento Worker)
  =============================================================================

  📌 O QUE É BROADWAY?
  ---------------------
  Broadway é uma biblioteca Elixir para construir pipelines de processamento
  de dados concorrentes e tolerantes a falhas. Pense nele como uma "fábrica"
  que processa mensagens de forma eficiente, com múltiplos trabalhadores.

  📌 FLUXO DESTE PIPELINE:
  ------------------------
  1. CONSOME mensagens do tópico Kafka: "orders.new"
     (Pedidos recém-criados aguardando pagamento)

  2. PROCESSA o pagamento (simulado com 95% de sucesso)

  3. PUBLICA para o tópico: "orders.paid"
     (Se o pagamento for aprovado)

  📌 CONCEITOS IMPORTANTES DO BROADWAY:
  -------------------------------------
  - Producer: Busca mensagens da fonte (Kafka, RabbitMQ, SQS, etc.)
  - Processor: Processa cada mensagem individualmente
  - Batcher: Agrupa mensagens para processamento em lote (opcional)

  📌 ANALOGIA COM O MUNDO REAL:
  -----------------------------
  Imagine um caixa de supermercado:
  - Producer = Esteira que traz os produtos
  - Processor = O caixa processando cada item
  - Batcher = Empacotador que junta tudo em sacolas

  Consumes: orders.new
  Publishes: orders.paid
  """
  use Broadway

  require Logger

  alias Broadway.Message
  alias LojaVirtual.Kafka.{Topics, Producer, Config}
  alias LojaVirtual.Repo
  alias LojaVirtual.Schemas.Order

  # =============================================================================
  # INICIALIZAÇÃO DO PIPELINE
  # =============================================================================

  @doc """
  Inicia o pipeline Broadway.

  Esta função é chamada automaticamente pelo Supervisor da aplicação
  (definido em application.ex). O Broadway gerencia todo o ciclo de vida
  dos processos internamente.
  """
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      # Nome único para este pipeline (permite referenciá-lo em outras partes do código)
      name: __MODULE__,

      # =========================================================================
      # CONFIGURAÇÃO DO PRODUCER (Busca mensagens do Kafka)
      # =========================================================================
      producer: [
        module: {
          # BroadwayKafka.Producer é o adaptador que conecta Broadway ao Kafka
          BroadwayKafka.Producer,
          [
            # Endereço do broker Kafka (dinâmico via variável de ambiente)
            hosts: Config.hosts(),

            # Consumer Group: Kafka usa grupos para distribuir trabalho
            # Múltiplas instâncias com o mesmo group_id compartilham as partições
            # Isso permite escalabilidade horizontal!
            group_id: "pagamento_group",

            # Tópico(s) que este pipeline vai consumir
            topics: [Topics.orders_new()],

            # Commit automático do offset quando a mensagem é processada
            # Offset = posição da última mensagem lida (Kafka guarda isso)
            offset_commit_on_ack: true,

            # Intervalo de polling: A cada 1000ms busca novas mensagens
            receive_interval: 1000
          ]
        },
        # Número de processos buscando mensagens
        # 1 é suficiente para cenários simples
        concurrency: 1
      ],

      # =========================================================================
      # CONFIGURAÇÃO DOS PROCESSORS (Processam mensagens individualmente)
      # =========================================================================
      processors: [
        default: [
          # 2 processos paralelos processando mensagens
          # Cada processo chama handle_message/3
          # Aumentar = mais throughput, mas mais uso de recursos
          concurrency: 2
        ]
      ],

      # =========================================================================
      # CONFIGURAÇÃO DOS BATCHERS (Agrupam mensagens processadas)
      # =========================================================================
      batchers: [
        default: [
          # Acumula até 10 mensagens antes de chamar handle_batch/4
          batch_size: 10,

          # OU dispara o batch após 2 segundos (o que vier primeiro)
          # Útil para não deixar mensagens "presas" esperando o batch encher
          batch_timeout: 2000
        ]
      ]
    )
  end

  # =============================================================================
  # CALLBACKS DO BROADWAY
  # =============================================================================

  @doc """
  Callback: Processa cada mensagem individualmente.

  📌 PARÂMETROS:
  - _processor: Nome do processor (geralmente :default)
  - message: Struct Broadway.Message contendo os dados da mensagem
  - _context: Metadados do Broadway

  📌 RETORNO:
  - message: Mensagem processada com sucesso (vai para o batcher)
  - Message.failed(message, reason): Marca como falha (vai para handle_failed/2)

  📌 IMPORTANTE:
  Esta função é chamada de forma CONCORRENTE pelos processors.
  No nosso caso, 2 processos chamam esta função em paralelo.
  """
  @impl true
  def handle_message(_processor, %Message{data: data} = message, _context) do
    Logger.info("[Pagamento] Processing payment")

    # Tenta decodificar o JSON da mensagem Kafka
    # O padrão {:ok, _} e {:error, _} é chamado de "tagged tuple" - muito comum em Elixir
    case Jason.decode(data) do
      {:ok, order_data} ->
        # Processa o pagamento (função privada definida abaixo)
        process_payment(order_data)
        # Retorna a mensagem para indicar sucesso
        message

      {:error, reason} ->
        Logger.error("[Pagamento] Decode error: #{inspect(reason)}")
        # Message.failed/2 marca a mensagem como falha
        # Ela será enviada para handle_failed/2
        Message.failed(message, reason)
    end
  end

  @doc """
  Callback: Processa um lote de mensagens já processadas.

  📌 QUANDO É CHAMADO?
  Quando batch_size (10) mensagens são acumuladas OU batch_timeout (2s) expira.

  📌 USO COMUM:
  - Inserir múltiplos registros no banco de uma vez
  - Enviar notificações em lote
  - Gerar relatórios agregados

  📌 NESTE PIPELINE:
  Apenas logamos o tamanho do batch. Em produção, você poderia
  fazer operações mais complexas aqui.
  """
  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    Logger.info("[Pagamento] Processed batch of #{length(messages)} orders")
    # Retorna as mensagens para confirmar o processamento
    messages
  end



  @doc """
  Callback: Trata mensagens que falharam.

  📌 QUANDO É CHAMADO?
  Quando Message.failed/2 é chamado em handle_message/3.

  📌 BOAS PRÁTICAS:
  - Logar o erro para debugging
  - Enviar para uma Dead Letter Queue (DLQ)
  - Notificar equipe de suporte
  - Tentar reprocessamento (com limite de tentativas)
  """
  @impl true
  def handle_failed(messages, _context) do
    # Itera sobre cada mensagem falha usando list comprehension
    for message <- messages do
      Logger.error("[Pagamento] Failed message: #{inspect(message.data)}")
    end
    # Retorna as mensagens (obrigatório)
    messages
  end

  # =============================================================================
  # FUNÇÕES PRIVADAS (LÓGICA DE NEGÓCIO)
  # =============================================================================

  @doc false
  # Pattern matching no argumento: extrai "id" do map e captura o map completo
  defp process_payment(%{"id" => order_id} = order_data) do
    # Simula o tempo de processamento do gateway de pagamento
    # Em produção, aqui você chamaria uma API como PagSeguro, Stripe, etc.
    Process.sleep(100)

    # Simula 95% de taxa de sucesso nos pagamentos
    # :rand.uniform(100) gera número aleatório de 1 a 100
    if :rand.uniform(100) <= 95 do
      # Pagamento aprovado!

      # 1. Atualiza o status no banco de dados
      update_order_status(order_id, :paid)

      # 2. Enriquece o evento com timestamp do pagamento
      # Map.merge/2 combina dois maps (o segundo sobrescreve chaves duplicadas)
      paid_event = Map.merge(order_data, %{
        "status" => "paid",
        "paid_at" => DateTime.utc_now() |> DateTime.to_iso8601()
      })

      # 3. Publica o evento no próximo tópico da pipeline
      # Isso dispara o OrdersPaidPipeline (Router Worker)
      Producer.publish(Topics.orders_paid(), order_id, paid_event)

      Logger.info("[Pagamento] Payment successful for order #{order_id}")
    else
      # Pagamento recusado (5% das vezes)
      # Em produção, você trataria isso de forma diferente:
      # - Notificar o cliente
      # - Publicar em um tópico "orders.payment_failed"
      # - Implementar retry com backoff
      Logger.warning("[Pagamento] Payment failed for order #{order_id}")
    end
  end

  @doc false
  # Atualiza o status do pedido no banco de dados PostgreSQL
  defp update_order_status(order_id, status) do
    # Repo.get/2 busca um registro pelo ID
    # Retorna nil se não encontrar
    case Repo.get(Order, order_id) do
      nil ->
        Logger.warning("[Pagamento] Order #{order_id} not found")

      order ->
        # Ecto.Changeset.change/2 cria um changeset simples
        # Diferente do changeset do schema, não aplica validações
        # Útil para atualizações internas controladas
        order
        |> Ecto.Changeset.change(%{status: status, paid_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end
end
