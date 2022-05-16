defmodule TsgGlobalWeb.CDRControllerTest do
  use TsgGlobalWeb.ConnCase, async: true

  alias TsgGlobal.RatingService

  @success_message "CDRs had been rated and saved. (Invalid ones are ignored)"

  @invalid_csv "The file is not a valid CSV file."

  @invalid_params "Params are not valid."

  setup %{conn: conn} do
    [
      url: "/api/rating",
      path: "./test/support/fixtures",
      conn: put_req_header(conn, "accept", "application/json")
    ]
  end

  describe "TsgGlobalWeb.CDRController.create" do
    test "when a valid file has been uploaded", %{url: url, path: path, conn: conn} do
      upload = %Plug.Upload{path: "#{path}/valid.csv", filename: "valid.csv"}

      resp =
        conn
        |> post(url, %{:file => upload})
        |> json_response(201)

      assert @success_message == resp["message"]
    end

    test "when an invalid csv file was uploaded", %{url: url, path: path, conn: conn} do
      upload = %Plug.Upload{path: "#{path}/invalid.csv", filename: "invalid.csv"}

      resp =
        conn
        |> post(url, %{:file => upload})
        |> json_response(400)

      assert @invalid_csv == resp["errors"]["detail"]
    end

    test "when a valid cdr json is sent through params", %{url: url, conn: conn} do
      resp =
        conn
        |> post(url, %{
          "cdrs" => [
            %{
              "carrier" => "Carrier C",
              "client_code" => "CLT2",
              "client_name" => "Client2",
              "destination_number" => "17066135090",
              "direction" => "OUTBOUND",
              "service_type" => "SMS",
              "source_number" => "12159538568",
              "success" => "TRUE",
              "timestamp" => "01/01/2021 00:01:33"
            }
          ]
        })
        |> json_response(201)

      assert @success_message == resp["message"]
    end

    test "when an invalid cdr json is given i.e client_code is missing", %{url: url, conn: conn} do
      resp =
        conn
        |> post(url, %{
          "cdrs" => [
            %{
              "carrier" => "Carrier C",
              "client_name" => "Client2",
              "destination_number" => "17066135090",
              "direction" => "OUTBOUND",
              "service_type" => "SMS",
              "source_number" => "12159538568",
              "success" => "TRUE",
              "timestamp" => "01/01/2021 00:01:33"
            }
          ]
        })
        |> json_response(422)

      assert %{"client_code" => ["can't be blank"]} == resp["errors"]
    end
  end

  describe "TsgGlobalWeb.CDRController.show" do
    setup do
      RatingService.validate_cdrs([
        %{
          "carrier" => "Carrier C",
          "client_code" => "CLT2",
          "client_name" => "Client2",
          "destination_number" => "17066135090",
          "direction" => "OUTBOUND",
          "service_type" => "SMS",
          "source_number" => "12159538568",
          "success" => "TRUE",
          # rating: 0.02
          "timestamp" => "01/01/2021 00:01:33"
        },
        %{
          "carrier" => "Carrier C",
          "client_code" => "CLT2",
          "client_name" => "Client2",
          "destination_number" => "17066135090",
          "direction" => "OUTBOUND",
          "service_type" => "SMS",
          "source_number" => "12159538568",
          "success" => "TRUE",
          # rating: 0.02
          "timestamp" => "01/01/2021 00:01:34"
        },
        %{
          "carrier" => "Carrier C",
          "client_code" => "CLT2",
          "client_name" => "Client2",
          "destination_number" => "17066135090",
          "direction" => "OUTBOUND",
          "service_type" => "SMS",
          "source_number" => "12159538568",
          "success" => "TRUE",
          # rating: 0.02
          "timestamp" => "01/01/2021 00:01:35"
        },
        %{
          "carrier" => "Carrier C",
          "client_code" => "CLT2",
          "client_name" => "Client2",
          "destination_number" => "17066135090",
          "direction" => "OUTBOUND",
          "service_type" => "MMS",
          "source_number" => "12159538568",
          "success" => "TRUE",
          # rating: 0.03
          "timestamp" => "01/01/2021 00:01:34"
        },
        %{
          "carrier" => "Carrier C",
          "client_code" => "CLT2",
          "client_name" => "Client2",
          "destination_number" => "17066135090",
          "direction" => "OUTBOUND",
          "service_type" => "MMS",
          "source_number" => "12159538568",
          "success" => "TRUE",
          # rating: 0.03
          "timestamp" => "01/01/2021 00:01:44"
        }
      ])
      |> elem(1)
      |> RatingService.insert_ratings()

      :ok
    end

    test "get monthly service charges for client_code, year and month", %{url: url, conn: conn} do
      resp =
        conn
        |> get(url, %{"client_code" => "CLT2", "year" => "2021", "month" => "01"})
        |> json_response(200)

      assert %{
               "charges_by_service" => [
                 %{"count" => 2, "service_type" => "mms", "total_price" => 0.06},
                 %{"count" => 3, "service_type" => "sms", "total_price" => 0.06}
               ],
               "count" => 5,
               "total" => 0.12
             } == resp["data"]
    end

    test "when params are not given for montly charges", %{url: url, conn: conn} do
      resp =
        conn
        |> get(url, %{"client_code" => "CLT2"})
        |> json_response(400)

      assert %{"detail" => @invalid_params} == resp["errors"]
    end
  end
end
