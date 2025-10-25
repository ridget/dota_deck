defmodule DotaDeck.Ingestion.Processor do
  @audio_dir Path.join([:code.priv_dir(:dota_deck), "static", "audio"])

  require Logger

  alias DotaDeck.Ingestion.{
    EmbeddingGenerator,
    VoiceLineMetadata
  }

  alias DotaDeck.Models.{
    SpeechTranscription,
    Embedding
  }

  def process_clips(staging_clips, max_concurrency \\ 1) do
    staging_clips
    |> Task.async_stream(&process_clip/1,
      max_concurrency: max_concurrency,
      timeout: :infinity
    )
    |> Enum.flat_map(fn
      {:ok, clip} ->
        [clip]

      {:error, path, reason} ->
        Logger.error("Error with #{path}: #{inspect(reason)}")
        []
    end)
  end

  defp process_clip(%{downloaded: true, processed: false, filepath: path} = staging_clip) do
    with %{chunks: [%{text: tx} | _]} <-
           SpeechTranscription.predict(@audio_dir <> "/" <> path),
         trimmed_text = String.trim(tx),
         {:ok, metadata} <- VoiceLineMetadata.predict(staging_clip, trimmed_text),
         text_to_embed = EmbeddingGenerator.generate(staging_clip, metadata),
         %{embedding: emb} <-
           Embedding.batch_generate_embedding(text_to_embed) do
      %{
        filepath: path,
        transcript: trimmed_text,
        embedding: emb,
        raw_embedding: text_to_embed,
        hero_id: staging_clip.hero_id
      }
    else
      err ->
        {:error, path, err}
    end
  end
end
