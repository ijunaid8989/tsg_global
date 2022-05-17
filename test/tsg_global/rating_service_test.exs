defmodule TsgGlobal.RatingServiceTest do
  use TsgGlobal.DataCase

  alias TsgGlobal.RatingService

  @path "./test/support/fixtures"

  describe "TsgGlobal.RatingService" do
    test "when a valid CSV is given, process/1" do
      resp =
        %{
          "file" => %Plug.Upload{
            content_type: "text/csv",
            filename: "valid.csv",
            path: "#{@path}/valid.csv"
          }
        }
        |> RatingService.process()

      assert {:ok, cdrs} = resp
      assert is_list(cdrs) == true
    end

    test "when valid list of cdrs is given, process/1" do
      resp =
        %{
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
          ]
        }
        |> RatingService.process()

      assert {:ok, cdrs} = resp
      assert is_list(cdrs) == true
    end

    test "when neither a file nor a cdrs list is provided, process/1" do
      assert {:error, :invalid_params} == RatingService.process(%{"fake" => "stuff"})
    end

    test "when an invalid csv is provided to parse/1" do
      file = %Plug.Upload{
        content_type: "text/csv",
        filename: "invalid.csv",
        path: "#{@path}/invalid.csv"
      }

      assert {:error, :csv_file_error} == RatingService.parse(file.path)
    end

    test "returns an invalid changeset when an invalid cdr is given (service_type is missing), validate_cdrs/1" do
      resp =
        [
          %{
            "carrier" => "Carrier C",
            "client_code" => "CLT2",
            "client_name" => "Client2",
            "destination_number" => "17066135090",
            "direction" => "OUTBOUND",
            "source_number" => "12159538568",
            "success" => "TRUE",
            "timestamp" => "01/01/2021 00:01:44"
          }
        ]
        |> RatingService.validate_cdrs()

      assert {:error, changeset} = resp
      assert changeset.valid? == false

      assert [service_type: {"can't be blank", [validation: :required]}] == changeset.errors
    end
  end
end
