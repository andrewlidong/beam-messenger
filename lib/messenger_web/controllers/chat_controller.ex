defmodule MessengerWeb.ChatController do
  use MessengerWeb, :controller
  
  alias Messenger.Chat
  alias Messenger.Chat.Message
  
  @doc """
  Lists all available chat rooms.
  """
  def index(conn, _params) do
    # In a real app, you'd fetch rooms from a database
    # For now, we'll use a hardcoded list of rooms
    rooms = [
      %{id: "general", name: "General", description: "General discussion"},
      %{id: "random", name: "Random", description: "Random topics"},
      %{id: "tech", name: "Tech", description: "Technology discussions"}
    ]
    
    render(conn, :index, rooms: rooms)
  end
  
  @doc """
  Shows a specific chat room and its message history.
  """
  def show(conn, %{"id" => room_id}) do
    # Fetch recent messages for this room
    messages = Chat.list_recent_messages(room_id)
    
    # Get current user from session (if authenticated)
    current_user = get_session(conn, :current_user)
    
    # Generate a token for the user (anonymous or authenticated)
    user_id = if current_user, do: current_user.id, else: "guest_#{System.unique_integer([:positive])}"
    username = if current_user, do: current_user.username, else: "Guest_#{user_id}"
    
    token = Phoenix.Token.sign(
      MessengerWeb.Endpoint, 
      "user socket", 
      %{"user_id" => user_id, "username" => username}
    )
    
    render(conn, :show, 
      room_id: room_id, 
      messages: messages, 
      token: token, 
      user_id: user_id, 
      username: username
    )
  end
  
  @doc """
  Renders the form for creating a new chat room.
  """
  def new(conn, _params) do
    # In a real app, you'd use a changeset for a Room schema
    # For now, we'll just render the form
    render(conn, :new)
  end
  
  @doc """
  Creates a new chat room.
  """
  def create(conn, %{"room" => room_params}) do
    # In a real app, you'd create a room in the database
    # For now, we'll just redirect to the room with the given ID
    
    # Simple validation
    case room_params do
      %{"id" => room_id} when is_binary(room_id) and room_id != "" ->
        conn
        |> put_flash(:info, "Room created successfully.")
        |> redirect(to: ~p"/chat/#{room_id}")
        
      _ ->
        conn
        |> put_flash(:error, "Room ID is required.")
        |> render(:new)
    end
  end
  
  @doc """
  Fetches message history for a room.
  Used for AJAX requests to load more messages.
  """
  def history(conn, %{"room_id" => room_id, "before" => before_timestamp}) do
    # Parse the timestamp
    {:ok, timestamp} = NaiveDateTime.from_iso8601(before_timestamp)
    
    # In a real app, you'd fetch messages before this timestamp
    # For now, we'll just return the recent messages
    messages = Chat.list_recent_messages(room_id)
    
    render(conn, :history, messages: messages)
  end
  
  @doc """
  Joins a room (for authenticated users).
  """
  def join(conn, %{"room_id" => room_id}) do
    # In a real app, you'd record that the user joined this room
    
    conn
    |> put_flash(:info, "Joined room successfully.")
    |> redirect(to: ~p"/chat/#{room_id}")
  end
  
  @doc """
  Leaves a room (for authenticated users).
  """
  def leave(conn, %{"room_id" => room_id}) do
    # In a real app, you'd record that the user left this room
    
    conn
    |> put_flash(:info, "Left room successfully.")
    |> redirect(to: ~p"/chat")
  end
end
