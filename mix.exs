defmodule Want.MixProject do
  use Mix.Project

  def project do
    [
      app:          :want,
      version:      "1.8.1",
      elixir:       "~> 1.10",
      deps:         deps(),
      description:  description(),
      package:      package(),
      docs:         docs()
    ]
  end

  def deps do
    [
      {:dialyxir, "~> 1.1", only: :dev},
      {:ex_doc, "~> 0.28.0", only: :dev, runtime: false}
    ]
  end

  def description do
    "Type conversion library for Erlang and Elixir."
  end

  def docs do
    [
      main: "Want"
    ]
  end

  def package do
    [
      name: "want",
      maintainers: ["Warren Kenny"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/wrren/want.erl"}
    ]
  end
end
