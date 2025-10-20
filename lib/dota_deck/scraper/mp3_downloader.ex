defmodule DotaDeck.Scraper.MP3Downloader do
  alias DotaDeck.Repo
  alias DotaDeck.Scraper.StagingClip

  require Logger

  def run do
    Repo.all(StagingClip.undownloaded())
    |> Task.async_stream(&download_and_mark_as_downloaded/1,
      max_concurrency: 8,
      timeout: :infinity
    )
    |> Stream.run()
  end

  def download_and_mark_as_downloaded(
        %StagingClip{hero_name: hero_name, audio_url: audio_url, downloaded: false} = staging_clip
      ) do
    static_dir = Path.join(["priv", "static", "audio"])
    File.mkdir_p!("#{static_dir}/#{hero_name}")

    filepath = "#{hero_name}/#{build_filename(audio_url)}"

    case download_audio_file("#{static_dir}/#{filepath}", audio_url) do
      :ok ->
        case StagingClip.changeset(staging_clip, %{downloaded: true, filepath: filepath})
             |> Repo.update() do
          {:ok, updated_clip} ->
            Logger.info("Successfully downloaded and marked: #{updated_clip.audio_url}")
            {:ok, updated_clip}

          {:error, changeset} ->
            Logger.error("Failed to update StagingClip for #{audio_url}: #{inspect(changeset)}")
            {:error, staging_clip}
        end

      {:error, reason} ->
        Logger.warning("Failed to download or write audio for #{audio_url}: #{inspect(reason)}")
        {:error, staging_clip}
    end
  end

  defp download_audio_file(path, audio_url) do
    case HTTPoison.get(audio_url, [], recv_timeout: 60_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        File.write!(path, body)

        :ok

      {:ok, resp} ->
        # FIX: Use audio_url, remove body, and return {:error, reason}
        Logger.warning("Failed HTTP status for #{audio_url}: #{resp.status_code}",
          path: path
        )

        {:error, {:http_status_error, resp.status_code}}

      {:error, reason} ->
        # FIX: Use audio_url, remove body, and return {:error, reason}
        Logger.warning("Error downloading #{audio_url}: #{inspect(reason)}",
          path: path
        )

        {:error, {:http_error, reason}}
    end
  end

  defp build_filename(url) do
    # example URL - split by / and then deconstruct
    # https://static.wikia.nocookie.net/dota2_gamepedia/images/a/a3/Vo_elder_titan_elder_happy_06.mp3/revision/latest?cb=20201011124127
    [_, _, file_path | _] = Path.split(url) |> Enum.reverse()
    file_path
  end
end
