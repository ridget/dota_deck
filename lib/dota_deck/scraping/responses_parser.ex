defmodule DotaDeck.Scraping.ResponsesParser do
  @base_url "https://dota2.fandom.com/wiki"

  import Meeseeks.XPath

  def build_responses(hero_name) do
    url = "#{@base_url}/#{hero_name}/Responses"
    row = %{hero_name: hero_name}

    {:ok, %HTTPoison.Response{status_code: 200, body: html}} =
      HTTPoison.get(url, [], follow_redirect: true)

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: html}} ->
        source_nodes =
          Meeseeks.all(
            html,
            xpath("//source[ancestor::li/ancestor::ul/preceding-sibling::h2[1]]")
          )

        for source_node <- source_nodes do
          # Required Audio Source URL
          audio_url = Meeseeks.attr(source_node, "src")

          # Find the headline (h2) for the current section by finding the LAST preceding h2
          headline_node =
            Meeseeks.one(source_node, xpath("ancestor::ul[1]/preceding-sibling::h2[last()]"))

          headline_text =
            if headline_node do
              Meeseeks.text(headline_node) |> String.trim()
            else
              nil
            end

          hero_link_node =
            Meeseeks.all(
              source_node,
              xpath("./ancestor::span[1]/following-sibling::span[@class='pixelart']/a")
            )
            |> List.first()

          hero_title =
            if hero_link_node do
              # Correctly extracts the title attribute from the <a> element
              Meeseeks.attr(hero_link_node, "title")
            else
              nil
            end

          # context_p_node =
          #   Meeseeks.one(source_node, xpath("ancestor::ul[1]/preceding-sibling::p[1]"))

          # b_context =
          #   if context_p_node do
          #     context_p_node |> Meeseeks.one(xpath("./i/text()")) |> Meeseeks.own_text()
          #   else
          #     nil
          #   end

          context_p_node =
            Meeseeks.one(source_node, xpath("ancestor::ul[1]/preceding-sibling::p[1]"))

          b_context =
            if context_p_node do
              # 1. Select the <i> element node
              i_node = context_p_node |> Meeseeks.one(xpath("./i"))
              # 2. Extract and trim the text from the <i> element node
              i_node |> Meeseeks.text() |> String.trim()
            else
              nil
            end

          ability_name =
            if context_p_node do
              context_p_node |> Meeseeks.one(xpath("./b//a/text()"))
            else
              nil
            end

          %{
            headline: headline_text,
            audio_url: audio_url,
            # Will be nil if not present
            b_context: b_context,
            ability_name: ability_name,
            hero_interaction: hero_title
          }
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        IO.warn("Failed to fetch #{hero_name}: HTTP #{status}")

      {:error, reason} ->
        IO.warn("Error fetching #{hero_name}: #{inspect(reason)}")
    end
  end

  # Helper function to safely extract and trim text from a single node
  defp extract_and_trim(nodes) do
    nodes
    |> List.first()
    |> case do
      nil ->
        nil

      node ->
        # Use Meeseeks.text/1 for robust text extraction (will handle text nodes or element nodes)
        Meeseeks.text(node) |> String.trim()
    end
  end
end
