defmodule DotaDeck.Scraper.ScrapingPipeline do
  alias DotaDeck.Scraper.{ResponsesParser, StagingClip}
  alias DotaDeck.Repo
  import NaiveDateTime
  require Logger

  def fetch_and_insert_responses(heroes) do
    heroes
    |> fetch_responses()
    |> process_and_insert_staging_clips()
  end

  defp fetch_responses(heroes) do
    heroes
    |> Task.async_stream(&ResponsesParser.fetch_and_parse/1,
      timeout: :infinity,
      max_concurrency: 5
    )
    |> Enum.flat_map(fn
      {:ok, results} ->
        results

      {:exit, reason} ->
        Logger.error("A scraping task failed with reason: #{inspect(reason)}")
        []
    end)
  end

  defp process_and_insert_staging_clips(responses) do
    now = utc_now() |> truncate(:second)

    responses
    |> Enum.map(&add_timestamps(&1, now))
    |> Enum.chunk_every(1000)
    |> Enum.each(&insert_clip_chunk/1)
  end

  defp add_timestamps(map, now), do: Map.merge(map, %{inserted_at: now, updated_at: now})

  defp insert_clip_chunk(responses) do
    Repo.insert_all(StagingClip, responses)
  end
end
