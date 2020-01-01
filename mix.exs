defmodule Want.MixProject do
  use Mix.Project

  def project do
    [
      app:      :want,
      version:  "1.1.0",
      elixir:   "~> 1.0",
      deps:     deps()
    ]
  end

  def deps do
    [{:dialyxir, "~> 0.4", only: [:dev]}]
  end
end
