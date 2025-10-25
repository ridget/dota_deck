defmodule DotaDeck.Scraper.Mp3Downloader do
  alias DotaDeck.Scraper.HeroNameFormatter
  require Logger

  def download_all(staging_clips) do
    staging_clips
    |> Task.async_stream(&download/1,
      max_concurrency: 8,
      timeout: :infinity
    )
    |> Enum.flat_map(fn
      {:ok, updated_clip} ->
        [updated_clip]

      {:error, _reason} ->
        []

      _ ->
        # Discard other errors/mismatches
        []
    end)
  end

  def download(
        %DotaDeck.Data.StagingClip{
          audio_url: audio_url,
          hero: %{name: hero_name},
          downloaded: false
        } = staging_clip
      ) do
    static_dir = Path.join(["priv", "static", "audio"])
    hero_path_segment = HeroNameFormatter.to_url_path_segment(hero_name)
    File.mkdir_p!("#{static_dir}/#{hero_path_segment}")

    filepath = "#{hero_path_segment}/#{build_filename(audio_url)}"

    case download_audio_file("#{static_dir}/#{filepath}", audio_url) do
      :ok ->
        updated_clip = %{staging_clip | downloaded: true, filepath: filepath}

        updated_clip
        |> Map.from_struct()
        |> Map.drop([:updated_at, :hero, :__meta__])

      {:error, reason} ->
        Logger.warning("Failed to download or write audio for #{audio_url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp download_audio_file(path, audio_url) do
    case HTTPoison.get(audio_url, [], recv_timeout: 60_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        File.write!(path, body)

        :ok

      {:ok, resp} ->
        Logger.warning("Failed HTTP status for #{audio_url}: #{resp.status_code}",
          path: path
        )

        {:error, {:http_status_error, resp.status_code}}

      {:error, reason} ->
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
