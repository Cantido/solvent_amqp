defmodule SolventAMQP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:solvent_amqp_incoming, [:set, :public, :named_table])
    :ets.new(:solvent_amqp_outgoing, [:set, :public, :named_table])

    children = [
      # Starts a worker by calling: Solvent.Worker.start_link(arg)
      # {Solvent.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SolventAMQP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
