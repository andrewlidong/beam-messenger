defmodule Messenger.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :type, :string, null: false
      add :name, :string
      add :description, :text
      add :is_active, :boolean, default: true
      add :created_by_id, references(:users, on_delete: :nothing)
      add :last_message_at, :utc_datetime
      add :last_message_text, :text

      timestamps(type: :utc_datetime)
    end

    create index(:conversations, [:type])
    create index(:conversations, [:created_by_id])
    create index(:conversations, [:last_message_at])
    create index(:conversations, [:is_active])
  end
end
