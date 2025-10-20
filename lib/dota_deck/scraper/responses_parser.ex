defmodule DotaDeck.Scraper.ResponsesParser do
  @moduledoc """
  Parses the Axe responses page from the Dota 2 Wiki.
  """

  @base_url "https://dota2.fandom.com/wiki"

  import Meeseeks.XPath
  require Logger

  def fetch_and_parse(hero_name) do
    url = "#{@base_url}/#{hero_name}/Responses"

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        extract_data(body, hero_name)

      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.warning("Failed to fetch #{hero_name}: HTTP #{status}", hero_name: hero_name)
        []

      {:error, reason} ->
        Logger.error("Error fetching #{hero_name}: #{inspect(reason)}", hero_name: hero_name)
        []
    end
  end

  defp extract_data(doc, hero_name) do
    possible_lis =
      Meeseeks.all(doc, xpath("li[.//span//audio[@class='ext-audiobutton']]"))
      |> Enum.uniq_by(&Meeseeks.html/1)

    Enum.map(possible_lis, fn li ->
      # we use the li tag as the context node and use that to find its nearest preceeding contextual neighbours
      headline =
        Meeseeks.one(li, xpath("../preceding-sibling::h2[last()]")) |> Meeseeks.text()

      # always get the last preceeding p context that doesnt house a small i tag (these contain less useful context)
      p =
        Meeseeks.one(
          li,
          xpath("../preceding-sibling::p[not(count(*) = 1 and name(*[1]) = 'small')][last()]")
        )

      context = p |> Meeseeks.text()

      audio_url = Meeseeks.one(li, xpath(".//source")) |> Meeseeks.attr("src")

      # ability names are only present if theres an associated contextual p element but those arent always ability related
      ability_name =
        if p do
          ability =
            Meeseeks.one(
              p,
              xpath("./b/span[@class='image-link']/a[last()]")
            )

          ability |> Meeseeks.text()
        else
          nil
        end

      hero_interaction =
        Meeseeks.one(li, xpath(".//span[@class='pixelart']/a")) |> Meeseeks.attr("title")

      item_name =
        Meeseeks.one(li, xpath(".//span[not(@class='pixelart')]/a/img")) |> Meeseeks.attr("alt")

      item_text =
        if item_name do
          Regex.replace(~r/\s*\(\d+\)$/, item_name, "") |> String.trim()
        else
          nil
        end

      voiceline =
        Meeseeks.one(li, xpath("text()[last()]")) |> Meeseeks.text()

      %{
        headline: headline,
        context: context,
        audio_url: audio_url,
        hero_interaction: hero_interaction,
        voiceline: voiceline,
        hero_name: hero_name,
        ability_name: ability_name,
        item_name: item_text
      }
    end)
  end
end
