defmodule TsgGlobalWeb.CDRController do
  use TsgGlobalWeb, :controller

  alias TsgGlobal.RatingService

  action_fallback TsgGlobalWeb.FallbackController

  @spec create(any, map()) :: {:error, atom | %{__changeset__: map}} | Plug.Conn.t()
  def create(conn, params) do
    with {:ok, cdrs} <- RatingService.process(params),
         :ok <- RatingService.insert_ratings(cdrs) do
      send_resp(
        conn,
        :created,
        "CDRs had been rated and saved. (Invalid ones are ignored)"
      )
    end
  end

  @spec show(any, map()) :: {:error, :invalid_params} | Plug.Conn.t()
  def show(conn, %{"client_code" => client_code, "year" => year, "month" => month}) do
    with {:ok, stats} <- RatingService.monthly_charges(client_code, year, month) do
      render(conn, :show, data: stats)
    end
  end

  def show(_conn, _params),
    do: {:error, :invalid_params}
end
