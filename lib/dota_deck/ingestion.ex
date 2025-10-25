defmodule DotaDeck.Ingestion do
  alias DotaDeck.Data.{StagingClip, Clip}
  alias DotaDeck.Repo
  alias DotaDeck.Ingestion.Processor
  import NaiveDateTime

  def process() do
    Repo.all(StagingClip.downloaded_and_unprocessed())
    |> Repo.preload(:hero)
    |> Enum.chunk_every(5)
    |> Enum.each(fn chunk ->
      chunk
      |> Processor.process_clips()
      |> create_clips()
    end)
  end

  defp create_clips(records) do
    now = utc_now() |> truncate(:second)

    records
    |> Enum.map(fn map ->
      map
      |> Map.put(:inserted_at, now)
      |> Map.put(:updated_at, now)
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(Clip, chunk)
    end)
  end
end
