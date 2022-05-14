defmodule TsgGlobal.Repo.Migrations.CreateCdrs do
  use Ecto.Migration

  def change do
    create table(:cdrs) do
      add :client_code, :string
      add :client_name, :string
      add :source_number, :string
      add :destination_number, :string
      add :direction, :string
      add :service_type, :string
      add :success, :boolean, default: false, null: false
      add :carrier, :string
      add :timestamp, :utc_datetime
      add :rating, :float

      timestamps()
    end
  end
end
