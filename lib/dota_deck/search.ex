defmodule DotaDeck.Search do
  alias DotaDeck.Repo
  alias DotaDeck.Data.Clip
  alias DotaDeck.Models.Embedding

  @default_limit 25
  @rrf_k 60.0

  def search(query, hero_id \\ nil) do
    %{embedding: embedding} = Embedding.generate_embedding(query)

    clips =
      Clip.find_by_embedding(embedding, hero_id)
      |> Repo.all()

    Repo.preload(clips, :hero)
  end

  def hybrid_search(query, hero_id \\ nil) do
    %{embedding: embedding} = Embedding.generate_embedding(query)

    rff_search(query, embedding, hero_id)
  end

  def rff_search(query, embedding_vector, hero_id, limit \\ @default_limit) do
    cte_limit = 4 * @default_limit

    hero_filter =
      case hero_id do
        nil -> ""
        _ -> "WHERE hero_id = $4"
      end

    hero_filter_keyword =
      case hero_id do
        nil -> ""
        _ -> "AND c.hero_id = $4"
      end

    sql = """
    WITH semantic_search AS (
        SELECT id, RANK () OVER (ORDER BY embedding <=> $2) AS rank
        FROM clips
        #{hero_filter}
        ORDER BY embedding <=> $2
        LIMIT #{cte_limit}
    ),
    keyword_search AS (
        SELECT 
            c.id, 
            RANK () OVER (ORDER BY ts_rank_cd(
                setweight(to_tsvector('english', c.transcript), 'B') || 
                setweight(to_tsvector('english', h.name), 'A'),
                query
            ) DESC) AS rank
        FROM clips c
        INNER JOIN heroes h ON h.id = c.hero_id
        , plainto_tsquery('english', $1) query
        WHERE (
            setweight(to_tsvector('english', c.transcript), 'B') || 
            setweight(to_tsvector('english', h.name), 'A')
        ) @@ query
        #{hero_filter_keyword}
        ORDER BY ts_rank_cd(
            setweight(to_tsvector('english', c.transcript), 'B') || 
            setweight(to_tsvector('english', h.name), 'A'),
            query
        ) DESC
        LIMIT #{cte_limit}
    )
    SELECT
        c.*,
        COALESCE(1.0 / (#{@rrf_k} + semantic_search.rank), 0.0) +
        COALESCE(1.0 / (#{@rrf_k} + keyword_search.rank), 0.0) AS score
    FROM semantic_search
    FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
    INNER JOIN clips c ON c.id = COALESCE(semantic_search.id, keyword_search.id)
    ORDER BY score DESC
    LIMIT $3
    """

    params =
      case hero_id do
        nil -> [query, embedding_vector, limit]
        id when is_integer(id) -> [query, embedding_vector, limit, id]
      end

    case Repo.query(sql, params) do
      {:ok, result} ->
        clips = map_result_to_clips(result)
        Repo.preload(clips, :hero)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp map_result_to_clips(result) do
    clip_fields = Clip.__schema__(:fields)

    column_names = Enum.map(result.columns, &String.to_atom/1)

    Enum.map(result.rows, fn row ->
      data = Enum.zip(column_names, row) |> Enum.into(%{})
      clip_data = Map.take(data, clip_fields)
      struct(Clip, clip_data)
    end)
  end
end
