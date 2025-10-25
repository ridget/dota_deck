defmodule DotaDeck.Scraper.HeroScraper do
  @url "https://liquipedia.net/dota2/Portal:Heroes"

  def scrape do
    {:ok, %HTTPoison.Response{body: html}} = HTTPoison.get(@url)

    html
    |> Floki.parse_document!()
    |> Floki.find("div.heroes-panel__hero-card__title a")
    |> Enum.map(fn hero_fragment -> %{name: Floki.text(hero_fragment)} end)
  end
end
