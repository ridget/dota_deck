defmodule DotaDeckWeb.Plugs.NoCacheAudio do
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: path} = conn, _opts) do
    if String.starts_with?(path, "/audio/") do
      conn
      |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate, proxy-revalidate")
      |> put_resp_header("pragma", "no-cache")
      |> put_resp_header("expires", "0")
    else
      conn
    end
  end
end
