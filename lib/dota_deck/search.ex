defmodule DotaDeck.Search do
  alias DotaDeck.Repo
  alias DotaDeck.Data.Clip
  alias DotaDeck.Models.Embedding

  def search(query, hero_name \\ nil) do
    %{embedding: embedding} = Embedding.generate_embedding(query)

    clips =
      Clip.find_by_embedding(embedding, hero_name)
      |> Repo.all()

    Repo.preload(clips, :hero)
  end
end
