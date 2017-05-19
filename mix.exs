defmodule Connex.Mixfile do
  use Mix.Project

  def project do
    [app: :connex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:poolboy, "~> 1.5"},
     {:exredis, "~> 0.2.5", optional: true}]
  end
end
