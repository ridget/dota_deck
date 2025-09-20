defmodule DotaDeckWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use DotaDeckWeb, :html

  embed_templates "page_html/*"
end
