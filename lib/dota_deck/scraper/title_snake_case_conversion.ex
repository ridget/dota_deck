defmodule DotaDeck.Scraper.TitleSnakeCaseConversion do
  def convert(text = "anti_mage") when is_binary(text) do
    "Anti-Mage"
  end

  def convert(text = "queen_of_pain") when is_binary(text) do
    "Queen_of_Pain"
  end

  def convert(text = "keeper_of_the_light") when is_binary(text) do
    "Keeper_of_the_Light"
  end

  def convert(text) when is_binary(text) do
    Regex.replace(~r/(^|[_\s])([^\s_])/u, text, fn
      _, sep, char -> sep <> String.upcase(char)
    end)
  end
end
