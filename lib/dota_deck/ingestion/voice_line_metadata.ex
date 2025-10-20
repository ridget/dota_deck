defmodule DotaDeck.Ingestion.VoiceLineMetadata do
  @model "mistral:7b"

  alias DotaDeck.Scraper.StagingClip

  defmodule Metadata do
    use Ecto.Schema
    use Instructor

    @llm_doc """
    ## Field Description
    - sentiment: The complex emotional tone, including primary and secondary emotions.
    - interaction_type: The social function and target, e.g., Taunt, Command, directed at allies.
    - themes: Key abstract concepts or underlying ideas (e.g., death, victory, magic).
    - primary_sentiment: primary emotion
    - secondary_sentiment: secondary emotion
    - intents: Real-world conversational purposes (e.g., "joking," "frustration," "celebration").
    - inferred_archetype: The implied character's role (e.g., Scholar, Berserker, Trickster).
    - keywords: 8-12 concise words for robust literal and semantic search.
    """
    @primary_key false
    embedded_schema do
      field :emotion, :string
      field :intent, :string
      field :theme, :string
      field :summary, :string
    end
  end

  def predict(%StagingClip{} = staging_clip, transcript) do
    Instructor.chat_completion(
      model: @model,
      response_model: DotaDeck.Ingestion.VoiceLineMetadata.Metadata,
      mode: :json,
      max_retries: 3,
      messages: [
        %{
          role: "user",
          content: """
          You are an expert semantic analyzer for Dota 2 voice lines. Your task is to analyze the provided raw voice line and its structured metadata, and then generate four new, critical semantic fields: Emotion, Intent, Theme, and a brief Contextual Summary.

          Strictly use the following input data to infer the output:

          --- INPUT DATA ---
          Hero Name: #{staging_clip.hero_name |> format_field}
          Context Category: #{staging_clip.headline |> format_field}
          Voiceline Transcript: #{transcript |> format_field}
          Target Hero Interaction: #{staging_clip.hero_interaction |> format_field}
          Ability Name: #{staging_clip.ability_name |> format_field}
          Item Name: #{staging_clip.item_name |> format_field}
          Additional Context: #{staging_clip.context |> format_field}
          --- END INPUT ---

          Output only a JSON object containing the four generated fields. Do not include any other text or explanation.

          JSON Schema:
          {
            "emotion": "A concise, comma-separated list of the core emotions conveyed by the line (e.g., sarcastic, humorous, aggressive, joyful).",
            "intent": "A concise, comma-separated list of the line's purpose in gameplay (e.g., taunt, farewell, warning, initiation, thank, regret).",
            "theme": "A concise, comma-separated list of abstract concepts or events the line references (e.g., victory, death, power, betrayal, travel).",
            "summary": "A brief, 3-5 word summary of the line's function in the game."
          }
          """
        }
      ]
    )
  end

  defp format_field(nil) do
    "None"
  end

  defp format_field(field) do
    field
  end
end
