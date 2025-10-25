defmodule DotaDeck.Scraper do
  alias DotaDeck.Scraper.{HeroScraper, ResponsesIngester, Mp3Downloader}
  alias DotaDeck.Data.{Hero, StagingClip}
  alias DotaDeck.Repo
  import NaiveDateTime
  require Logger

  def create_heroes() do
    HeroScraper.scrape()
    |> create_heroes()
  end

  def create_staging_clips() do
    Repo.all(DotaDeck.Data.Hero)
    |> ResponsesIngester.build_staging_clips()
    |> create_staging_clips()
  end

  def download_audio() do
    Repo.all(StagingClip.undownloaded())
    |> Repo.preload(:hero)
    |> Mp3Downloader.download_all()
    |> update_staging_clips()
  end

  defp create_heroes(heroes) do
    apply_timestamps_and_insert_all(
      Hero,
      heroes,
      [:inserted_at, :updated_at],
      on_conflict: :nothing
    )
  end

  defp create_staging_clips(staging_clips) do
    apply_timestamps_and_insert_all(
      StagingClip,
      staging_clips,
      [:inserted_at, :updated_at],
      on_conflict: :nothing
    )
  end

  defp update_staging_clips(staging_clips) do
    apply_timestamps_and_insert_all(
      StagingClip,
      staging_clips,
      [:updated_at],
      on_conflict: {:replace_all_except, [:id, :hero_id]}
    )
  end

  defp apply_timestamps_and_insert_all(schema, records, keys, opts) do
    now = utc_now() |> truncate(:second)
    on_conflict = Keyword.get(opts, :on_conflict, :nothing)
    conflict_target = Keyword.get(opts, :conflict_target, :id)
    # Function to dynamically set the timestamps
    add_ts_fn = fn map ->
      Enum.reduce(keys, map, fn key, acc -> Map.put(acc, key, now) end)
    end

    records
    |> Enum.map(add_ts_fn)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(schema, chunk, on_conflict: on_conflict, conflict_target: conflict_target)
    end)
  end
end
