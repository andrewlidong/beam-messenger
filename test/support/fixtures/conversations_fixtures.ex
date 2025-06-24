defmodule Messenger.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Messenger.Conversations` context.
  """

  alias Messenger.Conversations

  @doc """
  Generate a private conversation between two users.
  """
  def private_conversation_fixture(user1_id, user2_id) do
    {:ok, conversation} = Conversations.create_private_conversation(user1_id, user2_id)
    conversation
  end

  @doc """
  Generate a group conversation.
  """
  def group_conversation_fixture(creator_id, attrs \\ %{}) do
    name = Map.get(attrs, :name, "Test Group #{System.unique_integer()}")
    description = Map.get(attrs, :description, "A test group")
    participant_ids = Map.get(attrs, :participant_ids, [])

    {:ok, conversation} = Conversations.create_group_conversation(
      creator_id,
      name,
      description,
      participant_ids
    )
    
    conversation
  end

  @doc """
  Generate a message in a conversation.
  """
  def conversation_message_fixture(conversation_id, sender_id, attrs \\ %{}) do
    text = Map.get(attrs, :text, "Test message #{System.unique_integer()}")
    message_type = Map.get(attrs, :message_type, "text")

    {:ok, message} = Conversations.create_conversation_message(
      conversation_id,
      sender_id,
      %{"text" => text, "message_type" => message_type}
    )
    
    message
  end

  @doc """
  Generate a conversation participant.
  """
  def conversation_participant_fixture(conversation_id, user_id, attrs \\ %{}) do
    role = Map.get(attrs, :role, "member")
    
    {:ok, participant} = Conversations.create_conversation_participant(
      conversation_id,
      user_id,
      role
    )
    
    participant
  end
end