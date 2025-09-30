defmodule DotaDeck.Search do
  alias DotaDeck.{Embedding, Repo, Clip}
  import Ecto.Query
  import Pgvector.Ecto.Query

  def search(query) do
    %{embedding: emb} = Embedding.search(query)
    by_embedding(emb)
  end

  defp by_embedding(embedding, limit \\ 10) do
    Repo.all(from c in Clip, order_by: l2_distance(c.embedding, ^embedding), limit: ^limit)
  end
end
