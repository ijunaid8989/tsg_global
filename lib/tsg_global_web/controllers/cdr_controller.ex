defmodule TsgGlobalWeb.CDRController do
  use TsgGlobalWeb, :controller

  alias TsgGlobal.RatingService

  action_fallback TsgGlobalWeb.FallbackController

  @spec create(any, map) :: {:error, atom | %{__changeset__: map}} | Plug.Conn.t()
  def create(conn, params) do
    with {:ok, cdrs} <- RatingService.process(params),
         {:ok, _stats} <- RatingService.insert_ratings(cdrs) do
      send_resp(
        conn,
        :created,
        "CDRs had been rated and saved. (Invalid ones are ignored)"
      )
    end
  end
end
