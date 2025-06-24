defmodule Messenger.Repo.Migrations.UpdateMessagesForConversations do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all)
      add :sender_id, references(:users, on_delete: :delete_all)
      add :message_type, :string, default: "text"
      add :reply_to_id, references(:messages, on_delete: :nilify_all)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:sender_id])
    create index(:messages, [:conversation_id, :timestamp])
    create index(:messages, [:reply_to_id])
  end
end
