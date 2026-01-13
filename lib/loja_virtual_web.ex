defmodule LojaVirtualWeb do
  @moduledoc """
  =============================================================================
  Configuração do módulo Web - API REST Pura
  =============================================================================

  Este módulo configura o comportamento base para controllers e rotas.
  O projeto está configurado como uma API REST pura (sem frontend Phoenix).

  📌 FRONTEND SEPARADO:
  ---------------------
  O frontend será desenvolvido separadamente (React, Vue, Next.js, etc.)
  e consumirá esta API via HTTP/JSON.

  📌 USO:
  -------
      use LojaVirtualWeb, :controller
      use LojaVirtualWeb, :router
  """

  @doc """
  Retorna os caminhos para arquivos estáticos permitidos.
  Mantemos apenas o essencial para APIs.
  """
  def static_paths, do: ~w(robots.txt)

  @doc """
  Configuração base para o Router.
  """
  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  @doc """
  Configuração base para Channels (WebSockets).
  Mantido para futura comunicação real-time com frontend.
  """
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  @doc """
  Configuração base para Controllers.

  📌 NOTA: Apenas formato JSON habilitado (API pura).
  """
  def controller do
    quote do
      # Apenas JSON, sem HTML
      use Phoenix.Controller, formats: [:json]

      use Gettext, backend: LojaVirtualWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  @doc """
  Rotas verificadas em tempo de compilação.
  """
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: LojaVirtualWeb.Endpoint,
        router: LojaVirtualWeb.Router,
        statics: LojaVirtualWeb.static_paths()
    end
  end

  @doc """
  Macro que despacha para a configuração apropriada.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
