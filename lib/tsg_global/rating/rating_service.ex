defmodule TsgGlobal.RatingService do
  @moduledoc """
  The Rating context.
  """

  import Ecto.Query, warn: false
  alias TsgGlobal.Repo
  alias Ecto.Multi

  alias NimbleCSV.RFC4180, as: CSV

  alias TsgGlobal.Rating.CDR

  @spec import(any) :: {:ok, list()} | {:error, atom()}
  def import(file_path \\ "priv/csvs/cdrs.csv") do
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

  @spec validate_cdrs(any) :: {:error, %{__changeset__: map}} | {:ok, list()}
  def validate_cdrs(cdrs) do
    cdrs =
      Enum.map(cdrs, fn cdr ->
        %{
          client_code: String.downcase(cdr["client_code"]),
          client_name: cdr["client_name"],
          source_number: cdr["source_number"],
          destination_number: cdr["destination_number"],
          direction: String.downcase(cdr["direction"]),
          service_type: String.downcase(cdr["service_type"]),
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

  @spec insert_ratings(list()) :: {:ok, map()} | {:error, atom()}
  def insert_ratings(cdrs) do
    {valid, _invalid} =
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

    case length(valid) > 0 do
      true ->
        Multi.new()
        |> Multi.insert_all(:insert_all, CDR, valid, on_conflict: :nothing)
        |> Repo.transaction()

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

  @doc """
  Returns the list of cdrs.

  ## Examples

      iex> list_cdrs()
      [%CDR{}, ...]

  """
  def list_cdrs do
    Repo.all(CDR)
  end

  @doc """
  Gets a single cdr.

  Raises `Ecto.NoResultsError` if the Cdr does not exist.

  ## Examples

      iex> get_cdr!(123)
      %CDR{}

      iex> get_cdr!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cdr!(id), do: Repo.get!(CDR, id)

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
