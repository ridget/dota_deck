defmodule DotaDeck.Scraping.HeroList do
  alias DotaDeck.Scraping.TitleSnakeCaseConversion
  @url "https://liquipedia.net/dota2/Portal:Heroes"

  def fetch_heroes do
    {:ok, %HTTPoison.Response{body: html}} = HTTPoison.get(@url)
    {:ok, document} = html |> Floki.parse_document()

    document
    |> Floki.find("div.heroes-panel__hero-card__title a")
    |> Enum.map(&Floki.text/1)
    |> Enum.map(&Recase.to_snake/1)
    |> Enum.map(&TitleSnakeCaseConversion.convert/1)
  end
end
