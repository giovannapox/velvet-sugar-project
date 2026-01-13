defmodule LojaVirtual.Pipelines.ShippingReadyPipeline do
  @moduledoc """
  =============================================================================
  BROADWAY PIPELINE: Processador de Entregas (Entrega Worker)
  =============================================================================

  📌 PROPÓSITO DESTE PIPELINE:
  ----------------------------
  Este é o ÚLTIMO estágio do fluxo de pedidos. Aqui simulamos todo o
  processo de entrega, desde o envio até a confirmação de recebimento.

  📌 FLUXO DO PIPELINE:
  ---------------------
  1. CONSOME mensagens do tópico: "shipping.ready"
     (Pedidos prontos para serem enviados - estoque já separado)

  2. ATUALIZA status para "shipped" (em trânsito)

  3. SIMULA tempo de entrega (delivery time)

  4. ATUALIZA status para "delivered" (entregue)

  📌 PROCESSAMENTO ASSÍNCRONO:
  ----------------------------
  Este pipeline usa Task.start/1 para processar entregas de forma assíncrona.
  Isso significa que a mensagem é "confirmada" imediatamente no Kafka,
  enquanto a simulação de entrega acontece em background.

  ⚠️ CUIDADO EM PRODUÇÃO:
  Esta abordagem é simplificada para estudos. Em produção real:
  - Use Task.Supervisor para gerenciar processos
  - Implemente retry em caso de falha
  - Considere usar um scheduler para entregas programadas

  📌 ANALOGIA COM O MUNDO REAL:
  -----------------------------
  Pense no motoboy saindo para entregar:
  - Pedido enviado: Status "Em trânsito" (shipped)
  - Tempo de viagem: O motoboy está a caminho
  - Pedido entregue: Cliente recebeu, status "Entregue" (delivered)

  Consumes: shipping.ready
  Final stage: Updates order to delivered
  """
  use Broadway

  require Logger

  alias Broadway.Message
  alias LojaVirtual.Repo
  alias LojaVirtual.Schemas.Order
  alias LojaVirtual.Kafka.{Topics, Config}

  # =============================================================================
  # INICIALIZAÇÃO DO PIPELINE
  # =============================================================================

  @doc """
  Inicia o pipeline de entregas.

  📌 DESTAQUE: concurrency: 5 nos processors
  Diferente dos outros pipelines que usam 2, aqui usamos 5.
  Por quê? Porque entregas são mais lentas (simulam viagem).
  Mais workers = mais entregas simultâneas = melhor throughput.

  📌 ANALOGIA:
  É como ter 5 motoboys em vez de 2.
  Mais entregadores = mais pedidos entregues por hora.
  """
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,

      # =========================================================================
      # PRODUCER: Consome do tópico "shipping.ready"
      # =========================================================================
      producer: [
        module: {
          BroadwayKafka.Producer,
          [
            hosts: Config.hosts(),

            # Grupo específico para o serviço de entrega
            group_id: "entrega_group",

            # Tópico final do fluxo - pedidos prontos para sair
            topics: [Topics.shipping_ready()],

            offset_commit_on_ack: true
          ]
        },
        concurrency: 1
      ],

      # =========================================================================
      # PROCESSORS: Mais workers para lidar com entregas "lentas"
      # =========================================================================
      processors: [
        default: [
          # 5 processos paralelos = 5 entregas simultâneas
          # Cada um representa um "entregador virtual"
          concurrency: 5
        ]
      ]

      # 📌 NOTA: Sem batchers
      # Cada entrega é individual (não faz sentido "batchear" entregas)
    )
  end

  # =============================================================================
  # CALLBACK DE PROCESSAMENTO
  # =============================================================================

  @doc """
  Processa cada pedido pronto para entrega.

  📌 PROCESSAMENTO ASSÍNCRONO COM Task.start/1:
  ---------------------------------------------
  Diferente dos outros pipelines, aqui usamos Task.start/1 para
  processar a entrega em background. Isso tem implicações importantes:

  VANTAGEM:
  - A mensagem Kafka é confirmada (acked) imediatamente
  - O pipeline não "trava" esperando entregas terminarem
  - Maior throughput

  DESVANTAGEM:
  - Se a Task falhar, já confirmamos a mensagem
  - Perdemos o rastreamento direto do Broadway
  - Precisamos de mecanismos próprios de retry

  📌 ALTERNATIVAS MAIS ROBUSTAS:
  - Task.Supervisor: Supervisiona Tasks e permite restart
  - Oban: Biblioteca de job queue com retry, scheduling, etc.
  - Manter síncrono: Se consistência for mais importante que velocidade
  """
  @impl true
  def handle_message(_processor, %Message{data: data} = message, _context) do
    case Jason.decode(data) do
      {:ok, order_data} ->
        # Task.start/1 inicia um processo leve (lightweight process)
        # que executa a função anonimamente em background
        # O retorno é {:ok, pid} (ignorado aqui)
        Task.start(fn -> process_delivery(order_data) end)

        # Retorna a mensagem imediatamente (não espera a Task terminar)
        message

      {:error, reason} ->
        Logger.error("[Entrega] Decode error: #{inspect(reason)}")
        Message.failed(message, reason)
    end
  end

  # =============================================================================
  # LÓGICA DE ENTREGA
  # =============================================================================

  @doc false
  @doc """
  Processa uma entrega completa (com email do cliente).

  📌 FLUXO DA ENTREGA:
  1. Log de início
  2. Atualiza status para :shipped (em trânsito)
  3. Simula tempo de viagem (500ms a 2.5s)
  4. Atualiza status para :delivered (entregue)
  5. Log de conclusão

  📌 PATTERN MATCHING NOS ARGUMENTOS:
  A cláusula exige que o map tenha:
  - "id" -> capturado em order_id
  - "customer_email" -> capturado em email

  Se o map não tiver customer_email, a próxima cláusula é tentada.
  """
  defp process_delivery(%{"id" => order_id, "customer_email" => email}) do
    Logger.info("[Entrega] Processing delivery for order #{order_id}")

    # ETAPA 1: Marcar como "em trânsito"
    # O pedido saiu para entrega
    update_order_status(order_id, :shipped, DateTime.utc_now())

    # ETAPA 2: Simular tempo de entrega
    # :rand.uniform(2000) gera número de 1 a 2000
    # + 500 garante mínimo de 500ms
    # Resultado: entre 500ms e 2500ms de "viagem"
    Process.sleep(:rand.uniform(2000) + 500)

    # ETAPA 3: Marcar como "entregue"
    # O cliente recebeu o pedido
    update_order_delivered(order_id, DateTime.utc_now())

    # 📌 EM PRODUÇÃO:
    # Aqui você enviaria um email de confirmação, SMS, push notification, etc.
    Logger.info("[Entrega] Order #{order_id} delivered to #{email}")
  end

  @doc false
  @doc """
  Processa entrega sem email do cliente (fallback).

  📌 CLÁUSULA DE FALLBACK:
  Se o pedido não tiver customer_email, ainda assim precisamos
  processar a entrega. Esta cláusula captura esses casos.

  📌 MENOS ESPECÍFICA:
  Esta cláusula vem DEPOIS da mais específica. Elixir tenta as
  cláusulas em ordem, então a mais específica tem prioridade.
  """
  defp process_delivery(%{"id" => order_id}) do
    # Versão simplificada: apenas atualiza para shipped
    # Não simula tempo de entrega nem marca como delivered
    update_order_status(order_id, :shipped, DateTime.utc_now())
  end

  # =============================================================================
  # FUNÇÕES DE ATUALIZAÇÃO NO BANCO
  # =============================================================================

  @doc false
  @doc """
  Atualiza o status do pedido para "shipped" (em trânsito).

  📌 CAMPOS ATUALIZADOS:
  - status: :shipped
  - shipped_at: timestamp do momento do envio

  📌 TRATAMENTO DE NIL:
  Se o pedido não for encontrado (foi deletado?), simplesmente ignoramos.
  Em produção, você deveria logar isso e talvez publicar em uma DLQ.
  """
  defp update_order_status(order_id, status, timestamp) do
    case Repo.get(Order, order_id) do
      # Pedido não encontrado - retorna :ok e ignora
      nil -> :ok

      # Pedido encontrado - atualiza
      order ->
        order
        # Ecto.Changeset.change/2 cria changeset sem validações
        # Útil para atualizações internas controladas
        |> Ecto.Changeset.change(%{status: status, shipped_at: timestamp})
        |> Repo.update()
    end
  end

  @doc false
  @doc """
  Marca o pedido como entregue.

  📌 CAMPOS ATUALIZADOS:
  - status: :delivered
  - delivered_at: timestamp do momento da entrega

  📌 POR QUE UMA FUNÇÃO SEPARADA?
  Separamos update_order_status e update_order_delivered para:
  1. Clareza de intenção (nomes descritivos)
  2. Facilitar manutenção (cada função faz uma coisa)
  3. Permitir lógica específica (ex: enviar notificação só na entrega)

  📌 PRINCÍPIO: Funções pequenas e focadas são mais fáceis de entender e testar.
  """
  defp update_order_delivered(order_id, timestamp) do
    case Repo.get(Order, order_id) do
      nil -> :ok

      order ->
        order
        |> Ecto.Changeset.change(%{status: :delivered, delivered_at: timestamp})
        |> Repo.update()

        # 📌 EM PRODUÇÃO, aqui você poderia:
        # - Enviar email de confirmação
        # - Disparar evento para sistema de reviews
        # - Atualizar métricas de entrega
        # - Liberar pagamento para vendedor (marketplace)
    end
  end
end
