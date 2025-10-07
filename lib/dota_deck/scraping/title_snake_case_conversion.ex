defmodule DotaDeck.Scraping.TitleSnakeCaseConversion do
  def convert(text) when is_binary(text) do
    Regex.replace(~r/(^|[_\s])([^\s_])/u, text, fn
      _, sep, char -> sep <> String.upcase(char)
    end)
  end
end
