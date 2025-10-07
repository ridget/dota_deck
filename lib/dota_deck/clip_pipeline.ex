defmodule DotaDeck.ClipPipeline do
  alias DotaDeck.{Repo, Clip, SpeechTranscription, Embedding, PathHelper}

  def process_clips(audio_paths, max_concurrency \\ 2) do
    audio_paths
    |> Task.async_stream(&process_clip/1,
      max_concurrency: max_concurrency,
      timeout: :infinity
    )
    |> Enum.each(fn
      {:ok, {:ok, path}} -> IO.puts("Processed #{path}")
      {:ok, {:error, path, reason}} -> IO.puts("Error with #{path}: #{inspect(reason)}")
    end)
  end

  def process_clip(path) do
    with %{chunks: [%{text: tx} | _]} <- SpeechTranscription.predict(path),
         %{embedding: emb} <- Embedding.predict(tx) do
      Repo.insert!(%Clip{
        file_path: PathHelper.to_static_url_path(path),
        transcript: tx,
        embedding: emb
      })

      {:ok, path}
    else
      err -> {:error, path, err}
    end
  end
end
