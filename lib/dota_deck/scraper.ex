defmodule DotaDeck.Scraper do
  alias DotaDeck.Scraper.{HeroList, ScrapingPipeline, MP3Downloader}

  def fetch_and_insert() do
    HeroList.fetch_heroes()
    |> Enum.take(5)
    |> ScrapingPipeline.fetch_and_insert_responses()
  end

  def download() do
    MP3Downloader.run()
  end
end
