defmodule SolventAMQP.MixProject do
  use Mix.Project

  def project do
    [
      app: :solvent_amqp,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SolventAMQP.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 3.1"},
      {:solvent, github: "Cantido/solvent"}
    ]
  end
end
