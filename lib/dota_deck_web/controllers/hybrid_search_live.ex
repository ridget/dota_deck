defmodule DotaDeckWeb.HybridSearchLive do
  use DotaDeckWeb, :live_view

  alias DotaDeck.Search
  alias DotaDeck.Data.Hero
  alias DotaDeck.Repo

  @impl true
  def mount(_params, _session, socket) do
    heroes = Hero.list_all_heroes() |> Repo.all()

    {:ok,
     assign(socket,
       query: "",
       hero_id: nil,
       results: [],
       loading: false,
       heroes: heroes
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    socket = assign(socket, loading: true, query: query)

    hero_id = socket.assigns.hero_id
    search_query = socket.assigns.query

    results = Search.hybrid_search(search_query, hero_id)

    {:noreply,
     assign(socket,
       results: results,
       loading: false
     )}
  end

  @impl true
  def handle_event("update_hero_id", %{"hero_id" => id_string}, socket) do
    hero_id =
      case Integer.parse(id_string) do
        {id, ""} -> id
        _ -> nil
      end

    socket = assign(socket, loading: true, hero_id: hero_id)

    search_query = socket.assigns.query
    results = Search.hybrid_search(search_query, hero_id)

    {:noreply,
     assign(socket,
       results: results,
       loading: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-gray-200 p-4 sm:p-8 font-sans antialiased">
      <div class="max-w-4xl mx-auto">
        <form
          phx-submit="search"
          class="flex flex-col sm:flex-row gap-4 mb-10 p-4 bg-gray-800/70 border border-yellow-600/30 rounded-lg shadow-2xl"
        >
          <input
            type="text"
            name="q"
            value={@query}
            placeholder="Search voice lines (e.g., 'Radiant', 'Alchemist', 'run')..."
            phx-debounce="400"
            autocomplete="off"
            autofocus
            class="flex-grow p-3 rounded-md bg-gray-700 border border-yellow-700 focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-lg placeholder-gray-400 text-white"
          />

          <select
            name="hero_id"
            phx-change="update_hero_id"
            class="p-3 rounded-md bg-gray-700 border border-yellow-700 focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors text-lg text-white"
          >
            <option
              value=""
              selected={is_nil(@hero_id)}
              class="bg-gray-800 text-gray-400"
            >
              Filter Hero (All Heroes)
            </option>
            <%= for hero <- @heroes do %>
              <option value={hero.id} selected={@hero_id == hero.id} class="bg-gray-800 text-white">
                {hero.name}
              </option>
            <% end %>
          </select>
          <button
            type="submit"
            disabled={@loading}
            class={[
              "px-6 py-3 rounded-md text-lg font-semibold uppercase tracking-wider transition-all duration-300 shadow-md",
              if(@loading,
                do: "bg-gray-600 cursor-not-allowed text-gray-400",
                else:
                  "bg-yellow-700 hover:bg-yellow-600 text-gray-900 border-b-4 border-yellow-800 hover:border-yellow-700 active:translate-y-px active:border-b-2"
              )
            ]}
          >
            <%= if @loading do %>
              Searching...
            <% else %>
              Search
            <% end %>
          </button>
        </form>

        <div class="results">
          <%= if @loading do %>
            <div class="flex justify-center items-center py-10">
              <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-yellow-500">
              </div>
              <p class="ml-4 text-xl text-yellow-500">Summoning voice lines...</p>
            </div>
          <% end %>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <%= for clip <- @results do %>
              <div class="clip p-4 bg-gray-800 rounded-xl shadow-xl border border-gray-700 hover:border-yellow-600/50 transition-all duration-200">
                <h3 class="text-xl font-bold mb-1 text-yellow-500 uppercase tracking-widest border-b border-gray-700 pb-1">
                  {clip.hero.name}
                </h3>

                <p class="text-gray-300 italic mb-3 text-lg">
                  &ldquo;{clip.transcript}&rdquo;
                </p>

                <audio
                  controls
                  id={"hero-audio-control-" <> clip.filepath}
                  phx-hook="AudioReload"
                  class="w-full h-10 [&::-webkit-media-controls-panel]:bg-gray-700 [&::-webkit-media-controls-play-button]:bg-yellow-600 [&::-webkit-media-controls-play-button]:rounded-full [&::-webkit-media-controls-current-time-display]:text-gray-200 [&::-webkit-media-controls-time-remaining-display]:text-gray-400 [&::-webkit-media-controls-timeline]:bg-gray-600 [&::-webkit-media-controls-volume-slider]:bg-yellow-700"
                >
                  <source
                    src={"/audio/#{URI.decode(clip.filepath)}"}
                    type="audio/mpeg"
                  /> Your browser does not support the audio element.
                </audio>
              </div>
            <% end %>
          </div>

          <%= if Enum.empty?(@results) and not @loading and @query != "" do %>
            <div class="text-center py-10">
              <p class="text-xl text-gray-500">
                No voice lines found. The search terms may be lost in the fog of war.
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
