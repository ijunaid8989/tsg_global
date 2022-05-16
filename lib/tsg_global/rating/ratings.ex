defmodule TsgGlobal.Ratings do
  @moduledoc """
  Module: TsgGlobal.Ratings

  This module is responsible for 2 jobs. When application will be started, it will look for standard rates cvs file and upload all rates to ETS for future uses, Standards
  rates can be changed as well just keep pressure off the DB, we are loading CSV to ETS, as its reluctantly faster to query.

  The CSV for rates consist of rates for sms, mms and voice, where as same client code can have more than one standard rates but with a time period.

  the :ratings ets table results into this

  ## ratings table

  iex(3)> :ets.tab2list(:ratings)
    [
      {"clt1", 1577836800, 1609459200, "outbound",
      [%{"mms" => 0.01, "sms" => 0.01, "voice" => 0.01}]},
      {"clt1", 1609459200, 1657803278, "outbound",
      [%{"mms" => 0.01, "sms" => 0.02, "voice" => 0.02}]},
      {"clt1", 1577836800, 1652619278, "inbound",
      [%{"mms" => 0.0001, "sms" => 0.0001, "voice" => 0.005}]},
      {"clt3", 1577836800, 1652619278, "outbound",
      [%{"mms" => 0.04, "sms" => 0.01, "voice" => 0.02}]},
      {"clt3", 1577836800, 1652619278, "inbound",
      [%{"mms" => 0.0001, "sms" => 0.0001, "voice" => 0.005}]},
      {"clt2", 1577836800, 1652619278, "outbound",
      [%{"mms" => 0.03, "sms" => 0.02, "voice" => 0.04}]},
      {"clt2", 1577836800, 1652619278, "inbound",
      [%{"mms" => 0.0001, "sms" => 0.0001, "voice" => 0.006}]}
    ]

  each row is saving
  1. client_code
  2. start_date (Unix for better querying as integer)
  3. end_date
  4. direction
  5. a map for rates

  Reason for having an enddate is: one of the existing client_code has to rates with a time period, so it should have an end date as well to justify ratings.

  The below module goes by the index and group by sell rates with client code and direction, if a direction have more than on rates, it will use each one for start and end date.

  in current situation, we have

  {"outbound", "clt1"} => [
    %{
      client_code: "clt1",
      direction: "outbound",
      mms_fee: 0.01,
      price_start_date: ~U[2020-01-01 00:00:00Z],
      sms_fee: 0.01,
      voice_fee: 0.01
    },
    %{
      client_code: "clt1",
      direction: "outbound",
      mms_fee: 0.01,
      price_start_date: ~U[2021-01-01 00:00:00Z],
      sms_fee: 0.02,
      voice_fee: 0.02
    }
  ],

  so clt1 has the end date as the start date of 2nd clts with same direction of outbound.

  this way the records which are between clt1 direction range date would be charged 0.01 and others would be charged 0.02.

  all other client codes which are only one, they have end date to be 60 days ahead of current utc time. so they can cover all those cdrs which dont have timestamp
  and the timestamp would be considered as utc_now/0.

  At first step, it would add the details of sell rates to ETS,

  as next It would use Rating Service to support existing CDRs to be rates accordingly.
  """

  use GenServer

  @ratings :ratings

  alias NimbleCSV.RFC4180, as: CSV
  alias TsgGlobal.RatingService

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

    if Application.get_env(:tsg_global, :mix_env) == :dev do
      RatingService.parse()
      |> elem(1)
      |> RatingService.insert_ratings()
    end

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
