defmodule ExLine.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_line,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExLine",
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      # Plug is only needed for ExLine.Webhook.Plug / BodyReader; keep it optional
      # so non-Plug consumers (CLI, scripts) are not forced to pull it in.
      {:plug, "~> 1.16", optional: true},
      {:mox, "~> 1.1", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  # Dialyzer verifies our published @specs. The PLT is cached under priv/plts so
  # CI can restore it instead of rebuilding (the slow part) every run.
  defp dialyzer do
    [
      plt_local_path: "priv/plts",
      plt_core_path: "priv/plts",
      plt_add_apps: [:plug],
      flags: [:error_handling, :extra_return, :missing_return, :unknown]
    ]
  end
end
