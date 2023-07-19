defmodule Connex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :connex,
      version: "1.0.9",
      elixir: "~> 1.8",
      description: "Pooling and sharding connections",
      package: [
        maintainers: ["melpon", "kenichirow"],
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/gumi/connex"}
      ],
      docs: [main: "Connex"],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/gumi/connex",
      aliases: [test: &mix_test/1]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :telemetry]
    ]
  end

  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:redix, "~> 0.10", optional: true},
      {:gomomento, "0.5.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:env, "~> 0.2.0", only: :test}
    ]
  end

  defp mix_test(args) do
    System.put_env("CONNEX_REDIS_HOST", "localhost")
    Mix.Task.run("test", args)
  end
end
