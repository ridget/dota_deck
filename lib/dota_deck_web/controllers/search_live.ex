defmodule DotaDeckWeb.SearchLive do
  use DotaDeckWeb, :live_view

  alias DotaDeck.Search

  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: [], loading: false)}
  end

  def handle_event("search", %{"q" => query}, socket) do
    # Mark loading state
    socket = assign(socket, loading: true, query: query)

    results = Search.search(query)

    {:noreply,
     assign(socket,
       results: results,
       loading: false,
       version: Integer.to_string(:os.system_time(:millisecond))
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="search-container">
      <form phx-submit="search">
        <input
          type="text"
          name="q"
          value={@query}
          placeholder="Search voice lines..."
          autocomplete="off"
        />
        <button type="submit" disabled={@loading}>Search</button>
      </form>

      <%= if @loading do %>
        <p>Loading...</p>
      <% end %>

      <div class="results">
        <%= for clip <- @results do %>
          <div class="clip">
            <h3>{"Unknown Hero"}</h3>
            <p>{clip.transcript}</p>
    <audio controls id={"hero-audio-control-" <> clip.file_path} phx-hook="AudioReload">
    <source src={DotaDeckWeb.Endpoint.static_path(clip.file_path) <> "?" <> @version} type="audio/mpeg" />
              Your browser does not support the audio element.
            </audio>
          </div>
        <% end %>

        <%= if Enum.empty?(@results) and not @loading do %>
          <p>No results found</p>
        <% end %>
      </div>
    </div>
    """
  end
end
