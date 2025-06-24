defmodule Messenger.Conversations do
  @moduledoc """
  The Conversations context handles private messages, group chats, and conversation management.
  """

  import Ecto.Query, warn: false
  alias Messenger.Repo
  alias Messenger.Conversations.Conversation
  alias Messenger.Conversations.ConversationParticipant
  alias Messenger.Chat.Message
  alias Messenger.Accounts.User

  @doc """
  Returns the list of conversations for a user.
  """
  def list_user_conversations(user_id) do
    from(c in Conversation,
      join: cp in ConversationParticipant,
      on: cp.conversation_id == c.id,
      where: cp.user_id == ^user_id and cp.is_active == true,
      order_by: [desc: c.last_message_at],
      preload: [participants: :user, created_by: []]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single conversation.
  """
  def get_conversation!(id), do: Repo.get!(Conversation, id)

  @doc """
  Gets a conversation with participants preloaded.
  """
  def get_conversation_with_participants!(id) do
    Conversation
    |> Repo.get!(id)
    |> Repo.preload([participants: :user, created_by: []])
  end

  @doc """
  Creates a private conversation between two users.
  """
  def create_private_conversation(user1_id, user2_id) do
    # Check if conversation already exists
    case get_private_conversation(user1_id, user2_id) do
      nil ->
        Repo.transaction(fn ->
          # Create conversation
          {:ok, conversation} = 
            %Conversation{}
            |> Conversation.changeset(%{
              type: "private",
              created_by_id: user1_id,
              is_active: true
            })
            |> Repo.insert()

          # Add participants
          {:ok, _} = create_conversation_participant(conversation.id, user1_id)
          {:ok, _} = create_conversation_participant(conversation.id, user2_id)

          conversation
        end)

      existing_conversation ->
        {:ok, existing_conversation}
    end
  end

  @doc """
  Creates a group conversation.
  """
  def create_group_conversation(creator_id, name, description \\ nil, participant_ids \\ []) do
    Repo.transaction(fn ->
      # Create conversation
      {:ok, conversation} = 
        %Conversation{}
        |> Conversation.changeset(%{
          type: "group",
          name: name,
          description: description,
          created_by_id: creator_id,
          is_active: true
        })
        |> Repo.insert()

      # Add creator as admin
      {:ok, _} = create_conversation_participant(conversation.id, creator_id, "admin")

      # Add other participants
      Enum.each(participant_ids, fn user_id ->
        create_conversation_participant(conversation.id, user_id)
      end)

      conversation
    end)
  end

  @doc """
  Gets an existing private conversation between two users.
  """
  def get_private_conversation(user1_id, user2_id) do
    from(c in Conversation,
      join: cp1 in ConversationParticipant,
      on: cp1.conversation_id == c.id,
      join: cp2 in ConversationParticipant,
      on: cp2.conversation_id == c.id,
      where: c.type == "private" and
             cp1.user_id == ^user1_id and cp1.is_active == true and
             cp2.user_id == ^user2_id and cp2.is_active == true,
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a conversation participant.
  """
  def create_conversation_participant(conversation_id, user_id, role \\ "member") do
    %ConversationParticipant{}
    |> ConversationParticipant.changeset(%{
      conversation_id: conversation_id,
      user_id: user_id,
      role: role,
      joined_at: DateTime.utc_now(),
      is_active: true
    })
    |> Repo.insert()
  end

  @doc """
  Updates the last message info for a conversation.
  """
  def update_conversation_last_message(conversation_id, message_text) do
    conversation = get_conversation!(conversation_id)
    
    conversation
    |> Conversation.changeset(%{
      last_message_at: DateTime.utc_now(),
      last_message_text: message_text
    })
    |> Repo.update()
  end

  @doc """
  Lists messages for a conversation.
  """
  def list_conversation_messages(conversation_id, limit \\ 50) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [desc: m.timestamp],
      limit: ^limit,
      preload: [:sender]
    )
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Creates a message in a conversation.
  """
  def create_conversation_message(conversation_id, sender_id, attrs) do
    message_attrs = 
      attrs
      |> Map.put("conversation_id", conversation_id)
      |> Map.put("sender_id", sender_id)
      |> Map.put("timestamp", DateTime.utc_now())

    result = 
      %Message{}
      |> Message.conversation_changeset(message_attrs)
      |> Repo.insert()

    case result do
      {:ok, message} ->
        # Update conversation's last message
        update_conversation_last_message(conversation_id, message.text)
        {:ok, message}
      error ->
        error
    end
  end

  @doc """
  Checks if a user is a participant in a conversation.
  """
  def participant?(conversation_id, user_id) do
    from(cp in ConversationParticipant,
      where: cp.conversation_id == ^conversation_id and
             cp.user_id == ^user_id and
             cp.is_active == true
    )
    |> Repo.exists?()
  end

  @doc """
  Gets other participants in a private conversation (excluding the given user).
  """
  def get_other_participant(conversation_id, user_id) do
    from(cp in ConversationParticipant,
      join: u in User,
      on: u.id == cp.user_id,
      where: cp.conversation_id == ^conversation_id and 
             cp.user_id != ^user_id and
             cp.is_active == true,
      select: u,
      limit: 1
    )
    |> Repo.one()
  end
end