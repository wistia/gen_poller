defmodule GenPoller.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gen_poller,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: [compile: ["compile --warnings-as-errors"]],
      deps: deps(),
      source_url: "https://github.com/wistia/gen_poller",
      package: [
        description: "a simple, generic behaviour for doing stuff on some interval",
        maintainers: ["Wistia"],
        licenses: ["MIT"],
        links: %{"github" => "https://github.com/wistia/gen_poller"}
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
