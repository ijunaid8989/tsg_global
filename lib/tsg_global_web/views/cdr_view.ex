defmodule TsgGlobalWeb.CDRView do
  use TsgGlobalWeb, :view

  def render("show.json", %{data: data}) do
    %{data: data}
  end
end
