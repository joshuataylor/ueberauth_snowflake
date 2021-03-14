defmodule UeberauthSnowflake.Mixfile do
  use Mix.Project

  @project_description """
  Snowflake strategy for Überauth
  """

  @version "0.3.1"
  @source_url "https://github.com/joshuataylor/ueberauth_snowflake"

  def project do
    [
      app: :ueberauth_snowflake,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      description: @project_description,
      source_url: @source_url,
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ueberauth, "~> 0.6"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:snowflake_elixir, github: "joshuataylor/snowflake_elixir"},
      {:cloak_ecto, "~> 1.1"}
    ]
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md": [title: "README"]
      ]
    ]
  end

  defp package do
    [
      name: :ueberauth_snowflake,
      maintainers: ["Josh Taylor"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
