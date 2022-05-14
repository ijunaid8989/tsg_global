defmodule TsgGlobalWeb.CDRView do
  use TsgGlobalWeb, :view
  alias TsgGlobalWeb.CDRView

  def render("index.json", %{cdrs: cdrs}) do
    %{data: render_many(cdrs, CDRView, "cdr.json")}
  end

  def render("show.json", %{cdr: cdr}) do
    %{data: render_one(cdr, CDRView, "cdr.json")}
  end

  def render("cdr.json", %{cdr: cdr}) do
    %{
      id: cdr.id,
      client_code: cdr.client_code,
      client_name: cdr.client_name,
      source_number: cdr.source_number,
      destination_number: cdr.destination_number,
      direction: cdr.direction,
      service_type: cdr.service_type,
      success: cdr.success,
      carrier: cdr.carrier,
      timestamp: cdr.timestamp,
      rating: cdr.rating
    }
  end
end
