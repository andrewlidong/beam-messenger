defmodule MessengerWeb.ConversationChannel do
  @moduledoc """
  Channel for handling private conversations and group chats.
  """
  use Phoenix.Channel
  
  alias Messenger.{Conversations, Accounts}
  alias MessengerWeb.Presence

  @doc """
  Handles joining a conversation.
  """
  def join("conversation:" <> conversation_id, _params, socket) do
    user_id = socket.assigns.user_id
    
    # Verify user is a participant in this conversation
    case Conversations.participant?(conversation_id, user_id) do
      true ->
        socket = assign(socket, :conversation_id, conversation_id)
        send(self(), :after_join)
        {:ok, socket}
      false ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Rejects joining any other topics.
  """
  def join(_topic, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @doc """
  Handles post-join actions like setting up presence and sending message history.
  """
  def handle_info(:after_join, socket) do
    conversation_id = socket.assigns.conversation_id
    user_id = socket.assigns.user_id
    username = socket.assigns.username || "User"
    
    # Track user presence in this conversation
    {:ok, _} = Presence.track(socket, user_id, %{
      username: username,
      online_at: inspect(System.system_time(:second)),
      typing: false
    })
    
    # Send current presence state to the new joiner
    push(socket, "presence_state", Presence.list(socket))
    
    # Send recent message history
    messages = Conversations.list_conversation_messages(conversation_id, 50)
    push(socket, "message_history", %{messages: format_messages(messages)})
    
    # Broadcast that user joined
    broadcast!(socket, "user_joined", %{user_id: user_id, username: username})
    
    {:noreply, socket}
  end

  @doc """
  Handles new message events from clients.
  """
  def handle_in("new_message", %{"text" => text}, socket) do
    conversation_id = socket.assigns.conversation_id
    user_id = socket.assigns.user_id
    username = socket.assigns.username || "User"
    
    case Conversations.create_conversation_message(conversation_id, user_id, %{"text" => text}) do
      {:ok, message} ->
        message_data = %{
          id: message.id,
          conversation_id: conversation_id,
          sender_id: user_id,
          username: username,
          text: text,
          timestamp: DateTime.to_unix(message.timestamp, :millisecond),
          message_type: message.message_type
        }
        
        broadcast!(socket, "new_message", message_data)
        {:reply, {:ok, message_data}, socket}
        
      {:error, _changeset} ->
        {:reply, {:error, %{reason: "failed to send message"}}, socket}
    end
  end

  @doc """
  Handles typing indicator events.
  """
  def handle_in("typing", %{"typing" => typing}, socket) do
    user_id = socket.assigns.user_id
    
    # Update presence with typing status
    {:ok, _} = Presence.update(socket, user_id, fn existing_meta ->
      Map.put(existing_meta, :typing, typing)
    end)
    
    broadcast!(socket, "user_typing", %{
      user_id: user_id,
      typing: typing
    })
    
    {:reply, :ok, socket}
  end

  @doc """
  Handles message read receipts.
  """
  def handle_in("mark_read", %{"message_id" => message_id}, socket) do
    user_id = socket.assigns.user_id
    
    # In a real app, you'd update the read status in the database
    # For now, just broadcast the read receipt
    broadcast!(socket, "message_read", %{
      user_id: user_id,
      message_id: message_id
    })
    
    {:reply, :ok, socket}
  end

  @doc """
  Handles termination of the channel.
  """
  def terminate(_reason, socket) do
    user_id = socket.assigns.user_id
    broadcast!(socket, "user_left", %{user_id: user_id})
    :ok
  end

  # Helper function to format messages for the client
  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      %{
        id: message.id,
        conversation_id: message.conversation_id,
        sender_id: message.sender_id,
        username: if(message.sender, do: message.sender.username, else: "Unknown"),
        text: message.text,
        timestamp: DateTime.to_unix(message.timestamp, :millisecond),
        message_type: message.message_type
      }
    end)
  end
end