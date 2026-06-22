defmodule ExLine.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_line,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExLine",
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  # Compile test/support (shared test helpers like ExLine.Conformance) in :test.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      # JWT signing for the channel-access-token JWT-assertion / v2.1 endpoints
      # (ExLine.ChannelAccessToken.Assertion). Pure-Elixir, no native build.
      {:jose, "~> 1.11"},
      # Plug is only needed for ExLine.Webhook.Plug / BodyReader; keep it optional
      # so non-Plug consumers (CLI, scripts) are not forced to pull it in.
      {:plug, "~> 1.16", optional: true},
      {:mox, "~> 1.1", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      # Conformance testing: validate builder output against LINE's official
      # OpenAPI spec (open_api_spex parses OpenAPI 3.0 natively; yaml_elixir reads
      # the vendored .yml into a map).
      {:open_api_spex, "~> 3.22", only: :test},
      {:yaml_elixir, "~> 2.12", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "guides/channel_access_token.md"]
    ]
  end

  # Dialyzer verifies our published @specs. The PLT is cached under priv/plts so
  # CI can restore it instead of rebuilding (the slow part) every run.
  defp dialyzer do
    [
      plt_local_path: "priv/plts",
      plt_core_path: "priv/plts",
      plt_add_apps: [:plug, :jose],
      flags: [:error_handling, :extra_return, :missing_return, :unknown]
    ]
  end
end
