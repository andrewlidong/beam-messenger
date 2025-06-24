defmodule Messenger.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :contact_user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, default: "pending"
      add :requested_at, :utc_datetime
      add :accepted_at, :utc_datetime
      add :blocked_at, :utc_datetime
      add :nickname, :string
      add :is_favorite, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:contacts, [:user_id])
    create index(:contacts, [:contact_user_id])
    create index(:contacts, [:status])
    create unique_index(:contacts, [:user_id, :contact_user_id])
  end
end
