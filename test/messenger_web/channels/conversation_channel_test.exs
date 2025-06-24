defmodule MessengerWeb.ConversationChannelTest do
  use MessengerWeb.ChannelCase

  alias MessengerWeb.ConversationChannel
  alias Messenger.Conversations

  import Messenger.AccountsFixtures

  setup do
    user1 = user_fixture()
    user2 = user_fixture()
    {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

    {:ok, conversation: conversation, user1: user1, user2: user2}
  end

  describe "join" do
    test "can join conversation if user is a participant", %{conversation: conversation, user1: user1} do
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user1)
      })

      assert {:ok, _reply, _socket} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )
    end

    test "cannot join conversation if user is not a participant", %{conversation: conversation} do
      other_user = user_fixture()
      
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(other_user)
      })

      assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )
    end

    test "cannot join invalid conversation topic" do
      user = user_fixture()
      
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user)
      })

      assert {:error, %{reason: "unauthorized"}} = subscribe_and_join(
        socket,
        ConversationChannel,
        "invalid:topic"
      )
    end
  end

  describe "handle_in new_message" do
    test "broadcasts message to conversation participants", %{conversation: conversation, user1: user1} do
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user1)
      })

      {:ok, _reply, socket} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )

      ref = push(socket, "new_message", %{"text" => "Hello there!"})

      assert_reply ref, :ok, %{
        text: "Hello there!",
        sender_id: sender_id,
        conversation_id: conversation_id
      }
      
      assert sender_id == user1.id
      assert String.to_integer(conversation_id) == conversation.id

      assert_broadcast "new_message", %{
        text: "Hello there!",
        sender_id: ^sender_id,
        conversation_id: ^conversation_id
      }
    end

    test "persists message to database", %{conversation: conversation, user1: user1} do
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user1)
      })

      {:ok, _reply, socket} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )

      ref = push(socket, "new_message", %{"text" => "Hello there!"})
      assert_reply ref, :ok

      # Check message was saved to database
      messages = Conversations.list_conversation_messages(conversation.id)
      assert length(messages) == 1
      
      message = List.first(messages)
      assert message.text == "Hello there!"
      assert message.sender_id == user1.id
      assert message.conversation_id == conversation.id
    end
  end

  describe "handle_in typing" do
    test "broadcasts typing indicator", %{conversation: conversation, user1: user1} do
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user1)
      })

      {:ok, _reply, socket} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )

      ref = push(socket, "typing", %{"typing" => true})
      assert_reply ref, :ok

      assert_broadcast "user_typing", %{
        user_id: user_id,
        typing: true
      }
      
      assert user_id == user1.id
    end
  end

  describe "handle_in mark_read" do
    test "broadcasts read receipt", %{conversation: conversation, user1: user1} do
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user1)
      })

      {:ok, _reply, socket} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )

      ref = push(socket, "mark_read", %{"message_id" => "123"})
      assert_reply ref, :ok

      assert_broadcast "message_read", %{
        user_id: user_id,
        message_id: "123"
      }
      
      assert user_id == user1.id
    end
  end

  describe "presence" do
    test "tracks user presence when joining", %{conversation: conversation, user1: user1} do
      {:ok, socket} = connect(MessengerWeb.UserSocket, %{
        "token" => generate_user_token(user1)
      })

      {:ok, _reply, socket} = subscribe_and_join(
        socket,
        ConversationChannel,
        "conversation:#{conversation.id}"
      )

      # Should receive presence_state
      assert_push "presence_state", %{}
      
      # Should broadcast user_joined
      assert_broadcast "user_joined", %{
        user_id: user_id,
        username: username
      }
      
      assert user_id == user1.id
      assert username == user1.username
    end
  end

  # Helper function to generate user tokens for testing
  defp generate_user_token(user) do
    Phoenix.Token.sign(
      MessengerWeb.Endpoint,
      "user socket",
      %{"user_id" => user.id, "username" => user.username}
    )
  end
end