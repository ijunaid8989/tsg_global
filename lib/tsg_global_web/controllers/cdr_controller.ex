defmodule TsgGlobalWeb.CDRController do
  use TsgGlobalWeb, :controller

  alias TsgGlobal.RatingService

  action_fallback TsgGlobalWeb.FallbackController

  @doc """
  We are supporting 2 type of params in here for create as

  1. when a file has been uploaded %{"file" => %Plug.Upload{content_type: "text/csv", filename: "cdrs.csv", path: "/tmp/plug-1652/multipart-1652618903-171279885495035-6"}
  2. when cdrs are gving in form of a list such as below

    {
      "cdrs": [
          {
              "client_code": "CLT2",
              "client_name": "Client2",
              "source_number": "12159538568",
              "destination_number": "17066135090",
              "direction": "OUTBOUND",
              "service_type": "SMS",
              "success": "TRUE",
              "carrier": "Carrier C",
              "timestamp": "01/01/2021 00:01:33"

          }
      ]
    }

  RatingService.process/1 is responsible for handling that and return either processed cdrs or error tuples.
  """

  @spec create(any, map()) :: {:error, atom | %{__changeset__: map}} | Plug.Conn.t()
  def create(conn, params) do
    with {:ok, cdrs} <- RatingService.process(params),
         :ok <- RatingService.insert_ratings(cdrs) do
      conn
      |> put_status(201)
      |> json(%{message: "CDRs had been rated and saved. (Invalid ones are ignored)"})
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
