defmodule TsgGlobalWeb.CDRControllerTest do
  use TsgGlobalWeb.ConnCase

  import TsgGlobal.RatingFixtures

  alias TsgGlobal.Rating.CDR

  @create_attrs %{
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
  }
  @update_attrs %{
    carrier: "some updated carrier",
    client_code: "some updated client_code",
    client_name: "some updated client_name",
    destination_number: "some updated destination_number",
    direction: "some updated direction",
    rating: 456.7,
    service_type: "some updated service_type",
    source_number: "some updated source_number",
    success: false,
    timestamp: ~U[2022-05-14 07:38:00Z]
  }
  @invalid_attrs %{
    carrier: nil,
    client_code: nil,
    client_name: nil,
    destination_number: nil,
    direction: nil,
    rating: nil,
    service_type: nil,
    source_number: nil,
    success: nil,
    timestamp: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all cdrs", %{conn: conn} do
      conn = get(conn, Routes.cdr_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create cdr" do
    test "renders cdr when data is valid", %{conn: conn} do
      conn = post(conn, Routes.cdr_path(conn, :create), cdr: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.cdr_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "carrier" => "some carrier",
               "client_code" => "some client_code",
               "client_name" => "some client_name",
               "destination_number" => "some destination_number",
               "direction" => "some direction",
               "rating" => 120.5,
               "service_type" => "some service_type",
               "source_number" => "some source_number",
               "success" => true,
               "timestamp" => "2022-05-13T07:38:00Z"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.cdr_path(conn, :create), cdr: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update cdr" do
    setup [:create_cdr]

    test "renders cdr when data is valid", %{conn: conn, cdr: %CDR{id: id} = cdr} do
      conn = put(conn, Routes.cdr_path(conn, :update, cdr), cdr: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.cdr_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "carrier" => "some updated carrier",
               "client_code" => "some updated client_code",
               "client_name" => "some updated client_name",
               "destination_number" => "some updated destination_number",
               "direction" => "some updated direction",
               "rating" => 456.7,
               "service_type" => "some updated service_type",
               "source_number" => "some updated source_number",
               "success" => false,
               "timestamp" => "2022-05-14T07:38:00Z"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, cdr: cdr} do
      conn = put(conn, Routes.cdr_path(conn, :update, cdr), cdr: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete cdr" do
    setup [:create_cdr]

    test "deletes chosen cdr", %{conn: conn, cdr: cdr} do
      conn = delete(conn, Routes.cdr_path(conn, :delete, cdr))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.cdr_path(conn, :show, cdr))
      end
    end
  end

  defp create_cdr(_) do
    cdr = cdr_fixture()
    %{cdr: cdr}
  end
end
