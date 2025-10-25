defmodule DotaDeck.Data do
  alias DotaDeck.Data.Clip
  alias DotaDeck.Repo

  def search_clips(embedding, hero_name \\ nil) do
    Clip.find_by_embedding(embedding, hero_name)
    |> Repo.all()
  end
end
