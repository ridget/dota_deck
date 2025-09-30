defmodule DotaDeck.SpeechTranscription do
  @hf_model_repo "openai/whisper-small.en"

  def serving(opts \\ []) do
    opts = Keyword.validate!(opts, [:defn_options, batch_size: 3, language: nil, task: nil])

    {model, featurizer, tokenizer, generation_config} = load()

    Bumblebee.Audio.speech_to_text_whisper(
      model,
      featurizer,
      tokenizer,
      generation_config,
      compile: [batch_size: opts[:batch_size]],
      task: opts[:task],
      language: opts[:language],
      defn_options: opts[:defn_options]
    )
  end

  def predict(path) when is_binary(path) do
    Nx.Serving.batched_run(SpeechTranscription, {:file, path})
  end

  defp load() do
    {:ok, model} = Bumblebee.load_model({:hf, @hf_model_repo})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, @hf_model_repo})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @hf_model_repo})

    {:ok, generation_config} =
      Bumblebee.load_generation_config({:hf, @hf_model_repo})

    {model, featurizer, tokenizer, generation_config}
  end
end
