defmodule DotaDeck.Ingestion.Processor do
  @audio_dir Path.join([:code.priv_dir(:dota_deck), "static", "audio"])

  alias DotaDeck.{
    Repo,
    Clip
  }

  alias DotaDeck.Ingestion.{
    PathHelper,
    VoiceLineMetadata,
    HeroNameExtractor
  }

  alias DotaDeck.MLModels.{
    SpeechTranscription,
    Embedding
  }

  def process_clips(max_concurrency \\ 2) do
    load_hero_clip_paths()
    |> Task.async_stream(
      fn {hero_name, path} -> process_clip(hero_name, path) end,
      max_concurrency: max_concurrency,
      timeout: :infinity
    )
    |> Enum.each(fn
      {:ok, {:ok, path}} -> Logger.info("Processed #{path}")
      {:ok, {:error, path, reason}} -> Logger.error("Error with #{path}: #{inspect(reason)}")
    end)
  end

  defp process_clip(hero_name, path) do
    with %{chunks: [%{text: tx} | _]} <- SpeechTranscription.predict(path),
         {:ok, metadata} <- VoiceLineMetadata.predict(tx),
         %{embedding: emb} <- Embedding.predict(tx) do
      Repo.insert!(
        %Clip{
          file_path: PathHelper.to_static_url_path(path),
          transcript: tx,
          embedding: emb,
          hero_name: hero_name
        }
        |> Map.merge(metadata)
      )

      {:ok, path}
    else
      err -> {:error, path, err}
    end
  end

  defp load_hero_clip_paths do
    Path.wildcard(Path.join([@audio_dir, "*", "*.mp3"]))
    |> Enum.map(fn full_path ->
      [hero_name | _] =
        full_path
        |> Path.split()
        |> Enum.reverse()
        |> Enum.slice(1, 1)

      # 3. Return the unit of work: {hero_name, full_path}
      {hero_name, full_path}
    end)
  end
end
