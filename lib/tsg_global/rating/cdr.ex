defmodule TsgGlobal.Rating.CDR do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cdrs" do
    field(:carrier, :string)
    field(:client_code, :string)
    field(:client_name, :string)
    field(:destination_number, :string)
    field(:direction, :string)
    field(:rating, :float)
    field(:service_type, :string)
    field(:source_number, :string)
    field(:success, :boolean, default: false)
    field(:timestamp, :utc_datetime)
  end

  @doc false
  def changeset(cdr, attrs) do
    cdr
    |> cast(attrs, [
      :client_code,
      :client_name,
      :source_number,
      :destination_number,
      :direction,
      :service_type,
      :success,
      :carrier,
      :timestamp,
      :rating
    ])
    |> validate_required([
      :client_code,
      :client_name,
      :source_number,
      :destination_number,
      :direction,
      :service_type,
      :success,
      :carrier
    ])
  end
end
