defmodule TsgGlobal.Ratings do
  use GenServer

  @ratings :ratings

  alias NimbleCSV.RFC4180, as: CSV

  def start_link do
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
        {
          client_code,
          Date.from_iso8601(price_start_date) |> elem(1),
          String.to_float(sms_fee),
          String.to_float(mms_fee),
          String.to_float(voice_fee),
          direction
        }
      end)
      |> Enum.to_list()

    :ets.insert(@ratings, ratings)
  end
end
