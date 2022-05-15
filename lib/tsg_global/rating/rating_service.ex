defmodule TsgGlobal.RatingService do
  @moduledoc """
  The Rating context.
  """

  @batch_size 65535

  import Ecto.Query, warn: false
  alias TsgGlobal.Repo

  alias NimbleCSV.RFC4180, as: CSV

  alias TsgGlobal.Rating.CDR

  @doc """
  By pass the coming params from controller, we are supporting 2 type of params for CDRs.

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

  the process method would justify, if the file given then goes to CSV parse otherwise it would go to validate the coming cdrs if they are valid or not.

  if none of the above case is given, it would send a tuple of invalid params.
  """
  @spec process(map) :: {:error, atom() | %{__changeset__: map}} | {:ok, list}
  def process(%{"file" => %Plug.Upload{} = file}), do: parse(file.path)

  def process(%{"cdrs" => cdrs}), do: validate_cdrs(cdrs)

  def process(_params), do: {:error, :invalid_params}

  @doc """
  Method takes a file path as params, but has a default param as well for the cdrs csv.

  The purpose of the method is to parse the CSV file, and convert them to a list of maps where each map would consider

    1. client_code
    2. client_name
    3. source_number
    4. destination_number
    5. direction
    6. service_type
    7. success
    8. carrier
    9. timestamp

  String fields are being downcased before saving to DB. and if timestamp is not given, it would default it to `DateTime.utc_now()`.

  It also handles the error tuple for CSV, if the CSV is missing a header or else, It would through a tuple CSV file error.
  """
  @spec parse(any) :: {:ok, list()} | {:error, atom()}
  def parse(file_path \\ "priv/csvs/cdrs.csv") do
    cdrs =
      File.stream!(file_path)
      |> CSV.parse_stream()
      |> Stream.map(fn [
                         client_code,
                         client_name,
                         source_number,
                         destination_number,
                         direction,
                         service_type,
                         success,
                         carrier,
                         timestamp
                       ] ->
        %{
          client_code: String.downcase(client_code),
          client_name: client_name,
          source_number: source_number,
          destination_number: destination_number,
          direction: String.downcase(direction),
          service_type: String.downcase(service_type),
          success: bool?(success),
          carrier: carrier,
          timestamp: parse_datetime(timestamp)
        }
      end)
      |> Enum.to_list()

    {:ok, cdrs}
  rescue
    _error ->
      {:error, :csv_file_error}
  end

  @doc """
  Method takes a list of cdrs as below,

  ## Example
  %{"cdrs" =>
    [
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
  }

  It first formats and downcase every string and fill up the timestamp if missing or format if given and by pass each CDR entity to Changeset to validate all keys presence.

  if any of the map is not validated through changeset, it would return an error tuple with changeset for fallback return error otheriwse it would return a list of cdrs.
  """
  @spec validate_cdrs(list()) :: {:error, %{__changeset__: map}} | {:ok, list()}
  def validate_cdrs(cdrs) do
    cdrs =
      Enum.map(cdrs, fn cdr ->
        %{
          client_code: String.downcase(cdr["client_code"] || ""),
          client_name: cdr["client_name"],
          source_number: cdr["source_number"],
          destination_number: cdr["destination_number"],
          direction: String.downcase(cdr["direction"] || ""),
          service_type: String.downcase(cdr["service_type"] || ""),
          success: bool?(cdr["success"]),
          carrier: cdr["carrier"],
          timestamp: parse_datetime(cdr["timestamp"])
        }
      end)

    Enum.map(cdrs, &CDR.changeset(%CDR{}, &1))
    |> Enum.filter(&(&1.valid? == false))
    |> case do
      [] ->
        {:ok, cdrs}

      list ->
        {:error, List.first(list)}
    end
  end

  @doc """
  Method is responsible for adding the rating for each cdr, this is how it proceed,
  1. It ignores all those cdrs which are not succeeded as true
  2. then the reducer start with a tuple of 2 empty lists, where one is holding all valid CDRs and one for invalid CDRs.
  3. While quering the ETS table of ranking for rates, get_service_rate/4 goes by client_code, timestamp of CDR, direction service type.
  4. get_service_rate query ETS table and fetch rates against client code and date is being checked between the start and end date of selling rates period.

  If this nothing found for the time period, direction, and client_code as well as service type, we are assuring that we are not offering that service so it will be ignored
  and will go to invalid list of cdrs.

  if available then from ETS map for rates, we provide service_type, i.e "sms", "mms", "voice", it gives rates if service not found it return an error tuple instead.

  Once all ratings are concluded, we are doing a Repo.insert_all for that, with on_conflict: :nothing as we have defined a unique index on

  `[:client_code, :source_number, :destination_number, :direction, :service_type, :timestamp]`

  with given cdrs.csv it look as these above values cannot be duplicated.

  here is a use case to verify rates.

  the outbound rates for clt1 are

    CLT1,2020-01-01,0.01 {sms},0.01,0.01,OUTBOUND
    CLT1,2021-01-01,0.02 {sms},0.01,0.02,OUTBOUND

  in below maps, these are 2 records which for first one, it fall in 2020-01-01 to 2021-01-01 so rate for sms is 0.01

  and in 2nd map its 0.02

    Below maps are results of reducer's valid_cdrs
    %{
      carrier: "Carrier A",
      client_code: "clt1",
      client_name: "Client1",
      destination_number: "18552322012",
      direction: "outbound",
      rating: 0.01,
      service_type: "sms",
      source_number: "15048587135",
      success: true,
      timestamp: ~U[2020-12-31 23:59:48Z]
    },
    %{
      carrier: "Carrier C",
      client_code: "clt1",
      client_name: "Client1",
      destination_number: "12705575114",
      direction: "outbound",
      rating: 0.02,
      service_type: "sms",
      source_number: "19285515376",
      success: true,
      timestamp: ~U[2021-01-01 00:02:18Z]
    },

  ## NOTE IMP

  This problem can be solved by multiple solutions, such as
  1. Queue processing, i.e Kafka, RabbitMQ, Oban
  2. Broadway, Flow or GenStage
  3. Task.async_stream/3

  As its stated that `average customer daily makes few million transactions` the very first 2 solution can be an overkill for that purpose.
  The Below method of Repo.insert_all() is doing a trick of Batch size accepted by PostgreSQL and inserting chunk by chunk to DB.

  If requests may increase we can go to Task.async_stream() with max_concurrency: 10 (or 8 depends on Cores)
  """
  @spec insert_ratings(list()) :: :ok | {:error, atom()}
  def insert_ratings(cdrs) do
    {valid_cdrs, _invalid} =
      cdrs
      |> Enum.filter(&(&1.success == true))
      |> Enum.reduce({[], []}, fn cdr, {cdr_with_rating, invalid_service_type} = _acc ->
        case get_service_rate(
               cdr.client_code,
               DateTime.to_unix(cdr.timestamp),
               cdr.direction,
               cdr.service_type
             ) do
          {:error, "ratings not available"} ->
            {cdr_with_rating, [cdr | invalid_service_type]}

          rate ->
            {[Map.put(cdr, :rating, rate) | cdr_with_rating], invalid_service_type}
        end
      end)

    case length(valid_cdrs) > 0 do
      true ->
        # NOTE IMP See above Docs

        # 1
        list_of_chunks = Enum.chunk_every(valid_cdrs, @batch_size)

        Repo.checkout(
          fn ->
            Enum.each(list_of_chunks, fn rows ->
              Repo.insert_all(CDR, rows, on_conflict: :nothing)
            end)
          end,
          timeout: :infinity
        )

        # 2 Repo.insert_all(CDR, valid_cdrs, on_conflict: :nothing)
        :ok

      false ->
        {:error, :invalid_cdrs}
    end
  end

  defp get_service_rate(client_code, date, direction, service_type) do
    :ets.select(
      :ratings,
      [
        {{:"$1", :"$2", :"$3", :"$4", :"$5"},
         [
           {:andalso,
            {:andalso, {:andalso, {:==, :"$1", client_code}, {:==, :"$4", direction}},
             {:>=, {:const, date}, :"$2"}}, {:"=<", {:const, date}, :"$3"}}
         ], [:"$5"]}
      ]
    )
    |> case do
      [] -> {:error, "ratings not available"}
      [[rates]] -> rates[service_type]
    end
  end

  # mention about pg_trgm and to_tsvector but we have an index on this

  def monthly_charges(client_code, year, month) do
    charges_by_service =
      CDR
      |> group_by([cdr], cdr.service_type)
      |> select([cdr], %{
        service_type: cdr.service_type,
        total_price: sum(cdr.rating),
        count: count("*")
      })
      |> where([cdr], cdr.client_code == ^client_code)
      |> where(
        [cdr],
        fragment("date_part('month', ?)", cdr.timestamp) == ^String.to_integer(month)
      )
      |> where([cdr], fragment("date_part('year', ?)", cdr.timestamp) == ^String.to_integer(year))
      |> Repo.all()

    total =
      Enum.map(charges_by_service, & &1.total_price)
      |> Enum.sum()
      |> ceils()

    total_units =
      Enum.map(charges_by_service, & &1.count)
      |> Enum.sum()

    {:ok, %{total: total, count: total_units, charges_by_service: charges_by_service}}
  end

  defp ceils(0), do: 0

  defp ceils(n), do: Float.ceil(n, 2)

  defp bool?("TRUE"), do: true
  defp bool?(_any), do: false

  # This could have been done through Timex very easily as well but I didnt want to take that road ;)
  defp parse_datetime(nil), do: DateTime.utc_now()

  defp parse_datetime(datetime) do
    ~r[(?<day>\d{1,2})/(?<month>\d{1,2})/(?<year>\d{4}) (?<hour>\d{1,2}):(?<minutes>\d{1,2}):(?<seconds>\d{1,2})]
    |> Regex.named_captures(datetime)
    |> case do
      nil ->
        DateTime.utc_now()

      %{
        "day" => day,
        "hour" => hour,
        "minutes" => minutes,
        "month" => month,
        "seconds" => seconds,
        "year" => year
      } ->
        "#{year}-#{month}-#{day}T#{hour}:#{minutes}:#{seconds}Z"
        |> DateTime.from_iso8601()
        |> elem(1)
    end
  end
end
