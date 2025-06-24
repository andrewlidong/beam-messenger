defmodule MessengerWeb.ConversationsController do
  use MessengerWeb, :controller
  
  alias Messenger.{Conversations, Accounts}
  
  @doc """
  Lists all conversations for the current user.
  """
  def index(conn, _params) do
    current_user = conn.assigns[:current_user]
    conversations = Conversations.list_user_conversations(current_user.id)
    render(conn, :index, conversations: conversations, current_user: current_user)
  end
  
  @doc """
  Shows a specific conversation and its message history.
  """
  def show(conn, %{"id" => conversation_id}) do
    current_user = conn.assigns[:current_user]
    
    # Verify user is a participant
    case Conversations.participant?(conversation_id, current_user.id) do
      true ->
        conversation = Conversations.get_conversation_with_participants!(conversation_id)
        messages = Conversations.list_conversation_messages(conversation_id, 50)
        
        # Generate token for socket connection
        token = Phoenix.Token.sign(
          MessengerWeb.Endpoint, 
          "user socket", 
          %{"user_id" => current_user.id, "username" => current_user.username}
        )
        
        render(conn, :show, 
          conversation: conversation,
          messages: messages,
          current_user: current_user,
          token: token
        )
        
      false ->
        conn
        |> put_flash(:error, "You don't have access to this conversation.")
        |> redirect(to: ~p"/conversations")
    end
  end
  
  @doc """
  Creates a new private conversation with another user.
  """
  def create_private(conn, %{"user_id" => other_user_id}) do
    current_user = conn.assigns[:current_user]
    
    case Conversations.create_private_conversation(current_user.id, other_user_id) do
      {:ok, conversation} ->
        conn
        |> put_flash(:info, "Conversation started successfully.")
        |> redirect(to: ~p"/conversations/#{conversation.id}")
        
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to start conversation.")
        |> redirect(to: ~p"/conversations")
    end
  end
  
  @doc """
  Shows form for creating a new group conversation.
  """
  def new_group(conn, _params) do
    current_user = conn.assigns[:current_user]
    users = Accounts.list_users()
    render(conn, :new_group, users: users, current_user: current_user)
  end
  
  @doc """
  Creates a new group conversation.
  """
  def create_group(conn, %{"group" => group_params}) do
    current_user = conn.assigns[:current_user]
    
    name = Map.get(group_params, "name", "")
    description = Map.get(group_params, "description", "")
    participant_ids = Map.get(group_params, "participant_ids", [])
    
    case Conversations.create_group_conversation(current_user.id, name, description, participant_ids) do
      {:ok, conversation} ->
        conn
        |> put_flash(:info, "Group created successfully.")
        |> redirect(to: ~p"/conversations/#{conversation.id}")
        
      {:error, _changeset} ->
        users = Accounts.list_users()
        conn
        |> put_flash(:error, "Failed to create group.")
        |> render(:new_group, users: users, current_user: current_user)
    end
  end
end