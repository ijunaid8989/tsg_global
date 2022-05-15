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
      add :success, :boolean, default: true, null: false
      add :carrier, :string
      add :timestamp, :utc_datetime
      add :rating, :float
    end

    create index(:cdrs, [:client_code])
  end
end
