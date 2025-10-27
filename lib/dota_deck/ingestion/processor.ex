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

  defp process_clip(
         %{downloaded: true, processed: false, filepath: path, voiceline: voiceline} =
           staging_clip
       ) do
    with %{chunks: [%{text: tx} | _]} <-
           SpeechTranscription.predict(@audio_dir <> "/" <> path),
         trimmed_text = String.trim(tx),
         {:ok, metadata} <- VoiceLineMetadata.predict(staging_clip, trimmed_text),
         context_text_to_embed = EmbeddingGenerator.generate(staging_clip, metadata),
         %{embedding: embedding} <-
           Embedding.batch_generate_embedding(trimmed_text),
         %{embedding: context_embedding} <-
           Embedding.batch_generate_embedding(context_text_to_embed) do
      %{
        filepath: path,
        transcript: trimmed_text,
        original_transcript: voiceline,
        context_embedding: context_embedding,
        embedding: embedding,
        context_raw_embedding: context_text_to_embed,
        hero_id: staging_clip.hero_id
      }
    else
      err ->
        {:error, path, err}
    end
  end
end
