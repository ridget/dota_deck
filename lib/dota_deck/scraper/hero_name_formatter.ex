defmodule DotaDeck.Scraper.HeroNameFormatter do
  def to_url_path_segment(name) do
    name |> Recase.to_snake() |> title_snake_case_conversion()
  end

  # special cases
  def title_snake_case_conversion(name = "anti_mage") when is_binary(name) do
    "Anti-Mage"
  end

  def title_snake_case_conversion(name = "queen_of_pain") when is_binary(name) do
    "Queen_of_Pain"
  end

  def title_snake_case_conversion(name = "keeper_of_the_light") when is_binary(name) do
    "Keeper_of_the_Light"
  end

  def title_snake_case_conversion(text) when is_binary(text) do
    Regex.replace(~r/(^|[_\s])([^\s_])/u, text, fn
      _, sep, char -> sep <> String.upcase(char)
    end)
  end
end
