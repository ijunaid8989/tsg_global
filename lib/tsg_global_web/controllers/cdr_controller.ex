defmodule TsgGlobalWeb.CDRController do
  use TsgGlobalWeb, :controller

  alias TsgGlobal.RatingService

  action_fallback TsgGlobalWeb.FallbackController

  def create(conn, %{"file" => %Plug.Upload{} = file}) do
    with {:ok, cdrs} <- RatingService.import(file.path),
         {:ok, _stats} <- RatingService.insert_ratings(cdrs) do
      send_resp(
        conn,
        :accepted,
        "File contents was imported."
      )
    end
  end
end
