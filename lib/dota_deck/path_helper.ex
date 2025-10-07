defmodule DotaDeck.PathHelper do
  def to_static_url_path(filepath) do
    # Remove the "priv/static" prefix
    url_path = String.replace_prefix(filepath, "priv/static", "")

    # Ensure it starts with a "/"
    if String.starts_with?(url_path, "/") do
      url_path
    else
      "/" <> url_path
    end
  end
end
