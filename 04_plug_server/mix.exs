defmodule PlugServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :plug_server,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PlugServer.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},  # Plug + Cowboy 웹서버
      {:jason, "~> 1.4"}         # JSON 파서
    ]
  end
end
