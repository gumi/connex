defmodule Connex.Mixfile do
  use Mix.Project

  def project do
    [app: :connex,
     version: "1.0.0",
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
     {:redix, "~> 0.6.1", optional: true}]
  end
end
