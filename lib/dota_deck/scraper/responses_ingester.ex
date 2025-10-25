defmodule DotaDeck.Scraper.ResponsesIngester do
  alias DotaDeck.Scraper.ResponsesParser
  require Logger

  def build_staging_clips(heroes) do
    heroes
    |> fetch_responses()
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

  # defp process_and_insert_staging_clips(responses) do
  #   now = utc_now() |> truncate(:second)

  #   responses
  #   |> Enum.chunk_every(1000)
  #   |> Enum.each(&insert_clip_chunk/1)
  # end

  # defp add_timestamps(map, now), do: Map.merge(map, %{inserted_at: now, updated_at: now})
end
