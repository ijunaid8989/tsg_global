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
        client_code: client_code,
        client_name: client_name,
        source_number: source_number,
        destination_number: destination_number,
        direction: direction,
        service_type: service_type,
        success: bool?(success),
        carrier: carrier,
        timestamp: parse_datetime(timestamp)
      }
    end)
    |> Enum.to_list()
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
