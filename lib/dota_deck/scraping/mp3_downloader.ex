defmodule DotaDeck.Scraping.MP3Downloader do
  @base_url "https://dota2.fandom.com/wiki"

  alias DotaDeck.Scraping.HeroList

  def run do
    HeroList.fetch_heroes()
    |> Task.async_stream(&retrieve_all_audio_for_hero/1, max_concurrency: 8, timeout: :infinity)
    |> Stream.run()
  end

  defp retrieve_all_audio_for_hero(hero_name) do
    url = "#{@base_url}/#{hero_name}/Responses"
    static_dir = Path.join([:code.priv_dir(:dota_deck), "static", "audio"])
    hero_path = "#{static_dir}/#{hero_name}"
    hero_dir = File.mkdir_p!(hero_path)

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: html}} ->
        parsed_html = html |> Floki.parse_document!()

        parsed_html
        |> extract_audio_urls()
        |> Task.async_stream(fn url -> download_audio(hero_path, hero_name, url) end,
          max_concurrency: 8,
          timeout: :infinity
        )
        |> Stream.run()

      {:ok, %HTTPoison.Response{status_code: status}} ->
        IO.warn("Failed to fetch #{hero_name}: HTTP #{status}")

      {:error, reason} ->
        IO.warn("Error fetching #{hero_name}: #{inspect(reason)}")
    end
  end

  def log_urls(urls) do
    IO.warn(Enum.map(urls, fn url -> url end))
    urls
  end

  defp extract_audio_urls(html) do
    html
    |> Floki.find("audio.ext-audiobutton source")
    |> Floki.attribute("src")
  end

  defp download_audio(hero_path, hero, url) do
    case result = HTTPoison.get(url, [], recv_timeout: 60_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # fix up devbox
        File.write!("#{hero_path}/#{build_filename(hero, url)}", body)

      {:ok, resp} ->
        IO.warn("Failed #{url}: #{resp.status_code}")

      {:error, reason} ->
        IO.warn("Error downloading #{url}: #{inspect(reason)}")
    end
  end

  defp build_filename(hero, url) do
    # example URL - split by / and then deconstruct
    # https://static.wikia.nocookie.net/dota2_gamepedia/images/a/a3/Vo_elder_titan_elder_happy_06.mp3/revision/latest?cb=20201011124127
    [_, _, file_path | _] = Path.split(url) |> Enum.reverse()
    "#{hero}-#{file_path}"
  end
end
