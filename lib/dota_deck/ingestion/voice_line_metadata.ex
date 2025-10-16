defmodule DotaDeck.Ingestion.VoiceLineMetadata do
  @model "mistral:7b"

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
      field :interaction_type, :string
      field :themes, {:array, :string}, default: []
      field :keywords, {:array, :string}, default: []
      field :intents, {:array, :string}, default: []
      field :inferred_archetype, :string
      field :primary_sentiment, :string
      field :secondary_sentiment, :string
    end
  end

  def predict(hero_name, context, transcription, ability \\ nil) do
    Instructor.chat_completion(
      model: @model,
      response_model: DotaDeck.Ingestion.VoiceLineMetadata.Metadata,
      mode: :json,
      max_retries: 3,
      messages: [
        %{
          role: "user",
          content: """
          You are an expert linguistic and psychological analysis system specializing in inferring context and personality from dialogue of Dota 2 heroes.
          Your task is to analyze transcribed video game voice lines from Dota 2.

          Given a short transcribed voice line, perform a deep analysis based solely on the provided text and hero name and the context and ability under which it would be used in game with Dota 2.
          Use your knowledge of Dota 2, the character speaking or the specific in-game situation to guide your response.

          Your goal is to return highly structured and useful metadata for an emotional and contextual search system.

          Perform the following analysis:

          Sentiment: Analyze the complex emotional tone. Describe the primary and any secondary emotions.

          Interaction Type: Identify the social function or intent of the line. Is it directed at enemies, allies, or the self? Classify its purpose (e.g., Taunt, Command, Question, Observation, Lament, Boast, Encouragement).

          Themes: List the key abstract concepts or ideas present in the line. Themes are the underlying concepts (e.g., death, victory, magic), not the emotion of the delivery.

          Intents: Suggest real-world intents for conversational use. e.g., "joking", "frustration", "celebration"

          Inferred Archetype: Based only on the vocabulary, syntax, and tone, describe the implied character archetype (e.g., Wise Scholar, Bloodthirsty Berserker, Cynical Trickster, Noble Knight).

          Search Keywords: Provide 8-12 concise keywords. Include a mix of literal words, emotional concepts, and use-case descriptors for robust semantic search.
          <hero>
            #{hero_name}
          </hero>
          <context>
            #{context}
          </context>
          <ability>
            #{ability}
          </ability>
          <transcription>
            #{transcription}
          </transcription>
          """
        }
      ]
    )
  end
end
