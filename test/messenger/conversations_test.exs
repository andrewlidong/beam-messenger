defmodule Messenger.ConversationsTest do
  use Messenger.DataCase

  alias Messenger.Conversations
  alias Messenger.Conversations.{Conversation, ConversationParticipant}

  import Messenger.AccountsFixtures

  describe "conversations" do
    test "create_private_conversation/2 creates a new private conversation" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)
      assert conversation.type == "private"
      assert conversation.created_by_id == user1.id
      assert conversation.is_active == true

      # Check participants were created
      participants = Repo.all(ConversationParticipant)
      assert length(participants) == 2
      assert Enum.any?(participants, &(&1.user_id == user1.id))
      assert Enum.any?(participants, &(&1.user_id == user2.id))
    end

    test "create_private_conversation/2 returns existing conversation if it already exists" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create first conversation
      {:ok, conversation1} = Conversations.create_private_conversation(user1.id, user2.id)
      
      # Try to create again
      {:ok, conversation2} = Conversations.create_private_conversation(user1.id, user2.id)
      
      assert conversation1.id == conversation2.id
    end

    test "create_group_conversation/4 creates a new group conversation" do
      creator = user_fixture()
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:ok, conversation} = Conversations.create_group_conversation(
        creator.id, 
        "Test Group", 
        "A test group", 
        [user1.id, user2.id]
      )

      assert conversation.type == "group"
      assert conversation.name == "Test Group"
      assert conversation.description == "A test group"
      assert conversation.created_by_id == creator.id

      # Check participants were created (creator + 2 users)
      participants = Repo.all(ConversationParticipant)
      assert length(participants) == 3
      
      # Creator should be admin
      creator_participant = Enum.find(participants, &(&1.user_id == creator.id))
      assert creator_participant.role == "admin"
    end

    test "list_user_conversations/1 returns conversations for a user" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      # Create private conversation
      {:ok, private_convo} = Conversations.create_private_conversation(user1.id, user2.id)
      
      # Create group conversation
      {:ok, group_convo} = Conversations.create_group_conversation(
        user1.id, 
        "Test Group", 
        nil, 
        [user2.id, user3.id]
      )

      conversations = Conversations.list_user_conversations(user1.id)
      
      assert length(conversations) == 2
      conversation_ids = Enum.map(conversations, & &1.id)
      assert private_convo.id in conversation_ids
      assert group_convo.id in conversation_ids
    end

    test "participant?/2 returns true if user is a participant" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      assert Conversations.participant?(conversation.id, user1.id) == true
      assert Conversations.participant?(conversation.id, user2.id) == true
      assert Conversations.participant?(conversation.id, user3.id) == false
    end

    test "get_other_participant/2 returns the other user in a private conversation" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      other_participant = Conversations.get_other_participant(conversation.id, user1.id)
      assert other_participant.id == user2.id

      other_participant = Conversations.get_other_participant(conversation.id, user2.id)
      assert other_participant.id == user1.id
    end
  end

  describe "conversation messages" do
    test "create_conversation_message/3 creates a message in a conversation" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      assert {:ok, message} = Conversations.create_conversation_message(
        conversation.id,
        user1.id,
        %{"text" => "Hello!"}
      )

      assert message.conversation_id == conversation.id
      assert message.sender_id == user1.id
      assert message.text == "Hello!"
      assert message.message_type == "text"
    end

    test "create_conversation_message/3 updates conversation last_message_at" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)
      assert conversation.last_message_at == nil

      {:ok, _message} = Conversations.create_conversation_message(
        conversation.id,
        user1.id,
        %{"text" => "Hello!"}
      )

      updated_conversation = Conversations.get_conversation!(conversation.id)
      assert updated_conversation.last_message_at != nil
      assert updated_conversation.last_message_text == "Hello!"
    end

    test "list_conversation_messages/2 returns messages for a conversation" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      # Create some messages
      {:ok, msg1} = Conversations.create_conversation_message(
        conversation.id, user1.id, %{"text" => "First message"}
      )
      {:ok, msg2} = Conversations.create_conversation_message(
        conversation.id, user2.id, %{"text" => "Second message"}
      )

      messages = Conversations.list_conversation_messages(conversation.id)

      assert length(messages) == 2
      # Messages should be in chronological order (oldest first)
      assert List.first(messages).id == msg1.id
      assert List.last(messages).id == msg2.id
    end
  end
end