{:ok, whisper_model} = Bumblebee.load_model({:hf, "openai/whisper-small.en"})
{:ok, whisper_featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-small.en"})
{:ok, whisper_tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-small.en"})

whisper_serving =
  Bumblebee.Audio.speech_to_text_whisper(
    whisper_model,
    whisper_featurizer,
    whisper_tokenizer,
    compile: [batch_size: 1],
    defn_options: [compiler: EXLA]
  )

{:ok, embed_model} = Bumblebee.load_model({:hf, "sentence-transformers/all-MiniLM-L6-v2"})
{:ok, embed_tokenizer} = Bumblebee.load_tokenizer({:hf, "sentence-transformers/all-MiniLM-L6-v2"})

embedding_serving =
  Bumblebee.Text.text_embedding(
    embed_model,
    embed_tokenizer,
    defn_options: [compiler: EXLA]
  )
