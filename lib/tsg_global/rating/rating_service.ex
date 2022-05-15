defmodule TsgGlobal.RatingService do
  @moduledoc """
  The Rating context.
  """

  import Ecto.Query, warn: false
  alias TsgGlobal.Repo

  alias NimbleCSV.RFC4180, as: CSV

  alias TsgGlobal.Rating.CDR

  def import(file_path \\ "priv/csvs/cdrs.csv") do
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
  end

  def insert_ratings(cdrs) do
    {valid, invalid} =
      cdrs
      |> Enum.filter(&(&1.success == true))
      |> Enum.reduce({[], []}, fn cdr, {cdr_with_rating, invalid_service_type} = _acc ->
        case get_service_rate(
               cdr.client_code,
               DateTime.to_unix(cdr.timestamp),
               cdr.direction,
               cdr.service_type
             )
             |> IO.inspect() do
          {:error, "ratings not available"} -> {cdr_with_rating, [cdr | invalid_service_type]}
          rate -> {[Map.put(cdr, :rating, rate) | cdr_with_rating], invalid_service_type}
        end
      end)
      |> IO.inspect()
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

  @doc """
  Creates a cdr.

  ## Examples

      iex> create_cdr(%{field: value})
      {:ok, %CDR{}}

      iex> create_cdr(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cdr(attrs \\ %{}) do
    %CDR{}
    |> CDR.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cdr.

  ## Examples

      iex> update_cdr(cdr, %{field: new_value})
      {:ok, %CDR{}}

      iex> update_cdr(cdr, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cdr(%CDR{} = cdr, attrs) do
    cdr
    |> CDR.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cdr.

  ## Examples

      iex> delete_cdr(cdr)
      {:ok, %CDR{}}

      iex> delete_cdr(cdr)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cdr(%CDR{} = cdr) do
    Repo.delete(cdr)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cdr changes.

  ## Examples

      iex> change_cdr(cdr)
      %Ecto.Changeset{data: %CDR{}}

  """
  def change_cdr(%CDR{} = cdr, attrs \\ %{}) do
    CDR.changeset(cdr, attrs)
  end

  defp bool?("TRUE"), do: true
  defp bool?(_any), do: false

  # This could have been done through Timex very easily as well but I didnt want to take that road ;)
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
