defmodule Connex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :connex,
      version: "1.0.0",
      elixir: "~> 1.4",
      description: "Pooling and sharding connections",
      package: [
        maintainers: ["melpon", "kenichirow"],
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/gumi/connex"},
      ],
      docs: [main: "Connex"],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      source_url: "https://github.com/gumi/connex",
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:redix, "~> 0.6.1", optional: true},
      {:ex_doc, "~> 0.18.1", only: :dev, runtime: false},
    ]
  end
end
