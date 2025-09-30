defmodule DotaDeck.Embedding do
  @hf_model_repo "sentence-transformers/all-MiniLM-L6-v2"

  def serving(opts \\ []) do
    opts =
      Keyword.validate!(opts, [
        :defn_options,
        batch_size: 3,
        sequence_length: 64
      ])

    {model, tokenizer} = load()

    Bumblebee.Text.text_embedding(
      model,
      tokenizer,
      compile: [sequence_length: opts[:sequence_length], batch_size: opts[:batch_size]],
      defn_options: opts[:defn_options]
    )
  end

  def predict(text) do
    Nx.Serving.batched_run(Embedding, text)
  end

  def search(query) do
    Nx.Serving.run(serving(defn_options: [compiler: EXLA]), query)
  end

  defp load() do
    {:ok, model} =
      Bumblebee.load_model({:hf, @hf_model_repo})

    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @hf_model_repo})
    {model, tokenizer}
  end
end
