defmodule Want.MixProject do
  use Mix.Project

  @source_url "https://github.com/wrren/want.erl"
  @version    "1.17.1"

  def project do
    [
      app:          :want,
      version:      @version,
      elixir:       "~> 1.10",
      deps:         deps(),
      description:  description(),
      package:      package(),
      docs:         docs()
    ]
  end

  def deps do
    [
      {:ex_doc,     "~> 0.34.2",  only: :dev, runtime: false},
      {:dialyxir,   "~> 1.2",     only: [:dev], runtime: false}
    ]
  end

  def description do
    """
    Type conversion library for Erlang and Elixir.
    """
  end

  defp docs() do
    [
      main:       "readme",
      name:       "Want",
      source_ref: "v#{@version}",
      canonical:  "http://hexdocs.pm/want",
      source_url: @source_url,
      extras:     ["README.md", "CHANGELOG.md", "LICENSE"]
    ]
  end

  def package do
    [
      name:         "want",
      maintainers:  ["Warren Kenny"],
      licenses:     ["MIT"],
      links:        %{"GitHub" => @source_url}
    ]
  end
end
