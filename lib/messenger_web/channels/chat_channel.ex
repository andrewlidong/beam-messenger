defmodule MessengerWeb.ChatChannel do
  @moduledoc """
  Channel for handling real-time chat messaging.
  
  This channel manages chat rooms, tracks user presence, and
  facilitates message broadcasting between connected clients.
  """
  use Phoenix.Channel
  alias MessengerWeb.Presence

  @doc """
  Handles joining a chat room.
  
  When a user joins a chat room, they are subscribed to that room's topic
  and their presence is tracked. A list of existing messages and current users
  is sent back to the client.
  """
  def join("chat:lobby", _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end
  
  def join("chat:" <> room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :room_id, room_id)}
  end

  @doc """
  Rejects joining any other topics.
  """
  def join(_topic, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @doc """
  Handles post-join actions like setting up presence.
  """
  def handle_info(:after_join, socket) do
    # Get user info from socket assigns
    user_id = socket.assigns.user_id || "user_#{System.unique_integer([:positive])}"
    username = socket.assigns.username || "user_#{user_id}"
    
    # Track user presence
    {:ok, _} = Presence.track(socket, user_id, %{
      username: username,
      online_at: inspect(System.system_time(:second))
    })
    
    # Send current presence state to the new joiner
    push(socket, "presence_state", Presence.list(socket))
    
    # Broadcast that a new user has joined
    broadcast!(socket, "user_joined", %{user_id: user_id, username: username})
    
    {:noreply, socket}
  end

  @doc """
  Handles new message events from clients.
  
  When a client sends a new message, it's broadcasted to all users in the room.
  """
  def handle_in("new_message", %{"text" => text}, socket) do
    user_id = socket.assigns.user_id || "anonymous"
    username = socket.assigns.username || "anonymous"
    
    message = %{
      id: System.unique_integer([:positive]),
      user_id: user_id,
      username: username,
      text: text,
      timestamp: :os.system_time(:millisecond)
    }
    
    broadcast!(socket, "new_message", message)
    {:reply, {:ok, message}, socket}
  end

  @doc """
  Handles typing indicator events.
  """
  def handle_in("typing", %{"typing" => typing}, socket) do
    user_id = socket.assigns.user_id || "anonymous"
    broadcast!(socket, "user_typing", %{
      user_id: user_id,
      typing: typing
    })
    {:reply, :ok, socket}
  end

  @doc """
  Handles user status updates.
  """
  def handle_in("status", %{"status" => status}, socket) do
    user_id = socket.assigns.user_id || "anonymous"
    
    # Update presence with new status
    {:ok, _} = Presence.update(socket, user_id, fn existing_meta ->
      Map.put(existing_meta, :status, status)
    end)
    
    {:reply, :ok, socket}
  end

  @doc """
  Handles termination of the channel, updating presence information.
  """
  def terminate(_reason, socket) do
    user_id = socket.assigns.user_id || "anonymous"
    broadcast!(socket, "user_left", %{user_id: user_id})
    :ok
  end
end
