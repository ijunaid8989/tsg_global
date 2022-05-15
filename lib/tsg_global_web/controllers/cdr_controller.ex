defmodule TsgGlobalWeb.CDRController do
  use TsgGlobalWeb, :controller

  alias TsgGlobal.RatingService

  action_fallback TsgGlobalWeb.FallbackController

  def create(conn, %{"file" => %Plug.Upload{} = file}) do
    with {:ok, cdrs} <- RatingService.import(file.path),
         {:ok, _stats} <- RatingService.insert_ratings(cdrs) do
      send_resp(
        conn,
        :created,
        "CDRs had been rated and saved. (Invalid ones are ignored)"
      )
    end
  end

  def create(conn, %{"cdrs" => cdrs}) do
    with {:ok, cdrs} <- RatingService.validate_cdrs(cdrs),
         {:ok, _stats} <- RatingService.insert_ratings(cdrs) do
      send_resp(
        conn,
        :created,
        "CDRs had been rated and saved. (Invalid ones are ignored)"
      )
    end
  end
end
