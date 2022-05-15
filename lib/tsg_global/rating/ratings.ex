defmodule TsgGlobal.Ratings do
  use GenServer

  @ratings :ratings

  alias NimbleCSV.RFC4180, as: CSV

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec init(any) :: {:ok, any, {:continue, :initialize}}
  def init(args) do
    :ets.new(@ratings, [
      :duplicate_bag,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, args, {:continue, :initialize}}
  end

  def handle_continue(:initialize, state) do
    insert_ratings()

    {:noreply, state}
  end

  defp insert_ratings() do
    ratings =
      File.stream!("priv/csvs/sell_rates.csv")
      |> CSV.parse_stream()
      |> Stream.map(fn [
                         client_code,
                         price_start_date,
                         sms_fee,
                         mms_fee,
                         voice_fee,
                         direction
                       ] ->
        %{
          client_code: String.downcase(client_code),
          price_start_date: format_datetime(price_start_date),
          sms_fee: String.to_float(sms_fee),
          mms_fee: String.to_float(mms_fee),
          voice_fee: String.to_float(voice_fee),
          direction: String.downcase(direction)
        }
      end)
      |> Enum.to_list()
      |> Enum.group_by(&{&1.direction, &1.client_code})
      |> Enum.reduce([], fn rate, ratings = _acc ->
        {{_direction, _client_code}, rates} = rate

        case length(rates) > 1 do
          true ->
            date_sorted_rates =
              Enum.sort_by(rates, & &1.price_start_date, {:asc, DateTime})
              |> Enum.with_index()

            rating_list =
              Enum.map(date_sorted_rates, fn {_map, index} ->
                {rating, ^index} = Enum.at(date_sorted_rates, index)

                {rating.client_code, DateTime.to_unix(rating.price_start_date),
                 manage_end_datetime(Enum.at(date_sorted_rates, index + 1)), rating.direction,
                 [
                   %{
                     "sms" => rating.sms_fee,
                     "mms" => rating.mms_fee,
                     "voice" => rating.voice_fee
                   }
                 ]}
              end)

            [rating_list | ratings]

          false ->
            rating = List.first(rates)

            [
              {rating.client_code, DateTime.to_unix(rating.price_start_date),
               DateTime.utc_now() |> DateTime.to_unix(), rating.direction,
               [%{"sms" => rating.sms_fee, "mms" => rating.mms_fee, "voice" => rating.voice_fee}]}
              | ratings
            ]
        end
      end)
      |> List.flatten()

    :ets.insert(@ratings, ratings)
  end

  defp format_datetime(date) do
    case DateTime.from_iso8601(date <> "T00:00:00Z") do
      {:ok, datetime, _offset} -> datetime
      _error -> DateTime.utc_now()
    end
  end

  defp manage_end_datetime(nil),
    do: DateTime.utc_now() |> DateTime.add(60 * 24 * 60 * 60, :second) |> DateTime.to_unix()

  defp manage_end_datetime({rating, _index}), do: DateTime.to_unix(rating.price_start_date)
end
