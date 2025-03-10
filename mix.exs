defmodule BacklightAutomation.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :backlight_automation,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # dev
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:credo_single_line_functions,
       github: "Baradoy/credo_single_line_functions",
       tag: "v0.1.0",
       only: [:dev, :test],
       runtime: false},
      {:dialyxir, "~> 1.4.0", only: [:dev, :test], runtime: false},
      # eveyrthing else
      {:input_event, "~> 1.4"}
    ]
  end
end
