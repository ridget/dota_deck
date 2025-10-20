defmodule DotaDeck.Ingestion.Processor do
  @audio_dir Path.join([:code.priv_dir(:dota_deck), "static", "audio"])
  require Logger

  alias DotaDeck.{
    Repo,
    Clip
  }

  alias DotaDeck.Ingestion.{
    EmbeddingGenerator,
    VoiceLineMetadata
  }

  alias DotaDeck.Scraper.StagingClip

  alias DotaDeck.MLModels.{
    SpeechTranscription,
    Embedding
  }

  def process_clips(max_concurrency \\ 2) do
    Repo.all(StagingClip.downloaded_and_unprocessed())
    |> Task.async_stream(&process_clip/1,
      max_concurrency: max_concurrency,
      timeout: :infinity
    )
    |> Enum.each(fn
      {:ok, {:ok, path}} -> Logger.info("Processed #{path}")
      {:ok, {:error, path, reason}} -> Logger.error("Error with #{path}: #{inspect(reason)}")
    end)
  end

  # Will talk to this later
  # {:ok, metadata} <- VoiceLineMetadata.predict(staging_clip),

  defp process_clip(
         %StagingClip{downloaded: true, processed: false, filepath: path} = staging_clip
       ) do
    with %{chunks: [%{text: tx} | _]} <- SpeechTranscription.predict(@audio_dir <> "/" <> path),
         trimmed_text <- String.trim(tx),
         {:ok, metadata} <- VoiceLineMetadata.predict(staging_clip, trimmed_text),
         text_to_embed <- EmbeddingGenerator.generate(staging_clip, metadata),
         %{embedding: emb} <-
           Embedding.predict(text_to_embed) do
      Repo.insert!(%Clip{
        file_path: path,
        transcript: trimmed_text,
        embedding: emb,
        hero_name: staging_clip.hero_name
      })

      {:ok, path}
    else
      err -> {:error, path, err}
    end
  end
end
