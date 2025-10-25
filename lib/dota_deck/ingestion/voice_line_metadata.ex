defmodule DotaDeck.Ingestion.VoiceLineMetadata do
  require Logger
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Field Description
  - emotion: A concise, comma-separated list of the core emotions conveyed by the line (e.g., sarcastic, humorous, aggressive, joyful).
  - intent: A concise, comma-separated list of the line's purpose in gameplay (e.g., taunt, farewell, warning, initiation, thank, regret).
  - theme: A concise, comma-separated list of abstract concepts or events the line references (e.g., victory, death, power, betrayal, travel).
  - summary: A brief, 3-5 word summary of the line's function in the game of DOTA 2.
  """
  @primary_key false
  embedded_schema do
    field :emotion, :string
    field :intent, :string
    field :theme, :string
    field :summary, :string
  end

  def predict(staging_clip, transcript) do
    input_data = """
    --- INPUT DATA ---
    Hero Name: #{safe_value(staging_clip.hero.name)}
    Context Category: #{safe_value(staging_clip.headline)}
    Voiceline Transcript: #{safe_value(transcript)}
    Target Hero Interaction: #{safe_value(staging_clip.hero_interaction)}
    Ability Name: #{safe_value(staging_clip.ability_name)}
    Item Name: #{safe_value(staging_clip.item_name)}
    Additional Context: #{safe_value(staging_clip.context)}
    --- END INPUT ---
    """

    result =
      Instructor.chat_completion(
        model: "mistral:7b",
        response_model: __MODULE__,
        mode: :json,
        max_retries: 3,
        messages: [
          %{
            role: "user",
            content: """
            You are an expert prompt engineer and an expert semantic analyzer for Dota 2 voice lines.

            Your task is to analyze raw voice lines and their structured metadata.
            You MUST generate four new, critical semantic fields: emotion, intent, theme, and a brief contextual summary.

            STRICT GENERATION RULES:
            1.  You MUST generate a value for all four fields.
            2.  You must NEVER return 'null', 'nil', an empty string, or an equivalent placeholder.
            3.  If the provided input data is insufficient to confidently infer a value, use the following defaults:
            -   emotion: 'Neutral'
            -   intent: 'Statement'
            -   theme: 'General Gameplay'

            OUTPUT CONSTRAINT:
            Output only a single JSON object. Do not include any other text, explanation, or preamble.

            Analyze the following input data:

            #{input_data}
            """
          }
        ]
      )

    Logger.info(
      "LLM voiceline metadata result: #{inspect(result)}, input_data: #{inspect(input_data)}"
    )

    result
  end

  defp safe_value(nil), do: "None"
  defp safe_value(field), do: field
end
