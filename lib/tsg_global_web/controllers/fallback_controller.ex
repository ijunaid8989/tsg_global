defmodule TsgGlobalWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use TsgGlobalWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(TsgGlobalWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :csv_file_error}) do
    conn
    |> put_status(:bad_request)
    |> put_view(TsgGlobalWeb.ErrorView)
    |> render(:"400", error: "The file is not a valid CSV file.")
  end

  def call(conn, {:error, :invalid_cdrs}) do
    conn
    |> put_status(:bad_request)
    |> put_view(TsgGlobalWeb.ErrorView)
    |> render(:"400", error: "Invalid CDRs detected.")
  end

  def call(conn, {:error, :invalid_params}) do
    conn
    |> put_status(:bad_request)
    |> put_view(TsgGlobalWeb.ErrorView)
    |> render(:"400", error: "Params are not valid.")
  end
end
