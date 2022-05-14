defmodule TsgGlobal.RatingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TsgGlobal.Rating` context.
  """

  @doc """
  Generate a cdr.
  """
  def cdr_fixture(attrs \\ %{}) do
    {:ok, cdr} =
      attrs
      |> Enum.into(%{
        carrier: "some carrier",
        client_code: "some client_code",
        client_name: "some client_name",
        destination_number: "some destination_number",
        direction: "some direction",
        rating: 120.5,
        service_type: "some service_type",
        source_number: "some source_number",
        success: true,
        timestamp: ~U[2022-05-13 07:38:00Z]
      })
      |> TsgGlobal.Rating.create_cdr()

    cdr
  end
end
