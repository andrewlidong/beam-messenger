defmodule MessengerWeb.ConversationsControllerTest do
  use MessengerWeb.ConnCase

  alias Messenger.Conversations

  import Messenger.AccountsFixtures

  describe "index" do
    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/conversations")
      assert redirected_to(conn) == ~p"/login"
    end

    test "lists user conversations when authenticated", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create a conversation
      {:ok, _conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      conn = 
        conn
        |> login_user(user1)
        |> get(~p"/conversations")

      assert html_response(conn, 200) =~ "Messages"
      # Should show the other user's name for private conversations
      assert html_response(conn, 200) =~ user2.username
    end

    test "shows empty state when no conversations", %{conn: conn} do
      user = user_fixture()

      conn = 
        conn
        |> login_user(user)
        |> get(~p"/conversations")

      assert html_response(conn, 200) =~ "No conversations"
    end
  end

  describe "show" do
    test "requires authentication", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      conn = get(conn, ~p"/conversations/#{conversation.id}")
      assert redirected_to(conn) == ~p"/login"
    end

    test "shows conversation when user is participant", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      # Add a message
      {:ok, _message} = Conversations.create_conversation_message(
        conversation.id,
        user1.id,
        %{"text" => "Hello!"}
      )

      conn = 
        conn
        |> login_user(user1)
        |> get(~p"/conversations/#{conversation.id}")

      assert html_response(conn, 200) =~ user2.username
      assert html_response(conn, 200) =~ "Hello!"
    end

    test "redirects when user is not participant", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      {:ok, conversation} = Conversations.create_private_conversation(user1.id, user2.id)

      conn = 
        conn
        |> login_user(user3)
        |> get(~p"/conversations/#{conversation.id}")

      assert redirected_to(conn) == ~p"/conversations"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "don't have access"
    end
  end

  describe "new_group" do
    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/conversations/new-group")
      assert redirected_to(conn) == ~p"/login"
    end

    test "shows group creation form when authenticated", %{conn: conn} do
      user = user_fixture()
      
      conn = 
        conn
        |> login_user(user)
        |> get(~p"/conversations/new-group")

      assert html_response(conn, 200) =~ "Create New Group"
      assert html_response(conn, 200) =~ "Group Name"
    end
  end

  describe "create_group" do
    test "requires authentication", %{conn: conn} do
      conn = post(conn, ~p"/conversations/groups", %{
        "group" => %{"name" => "Test Group"}
      })
      assert redirected_to(conn) == ~p"/login"
    end

    test "creates group and redirects when valid", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()

      conn = 
        conn
        |> login_user(user1)
        |> post(~p"/conversations/groups", %{
          "group" => %{
            "name" => "Test Group",
            "description" => "A test group",
            "participant_ids" => [user2.id]
          }
        })

      assert %{id: conversation_id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/conversations/#{conversation_id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Group created successfully"

      # Verify group was created
      conversation = Conversations.get_conversation!(conversation_id)
      assert conversation.name == "Test Group"
      assert conversation.type == "group"
      assert conversation.created_by_id == user1.id
    end

    test "renders form with errors when invalid", %{conn: conn} do
      user = user_fixture()

      conn = 
        conn
        |> login_user(user)
        |> post(~p"/conversations/groups", %{
          "group" => %{"name" => ""}
        })

      assert html_response(conn, 200) =~ "Create New Group"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Failed to create group"
    end
  end

  describe "create_private" do
    test "requires authentication", %{conn: conn} do
      user = user_fixture()
      
      conn = post(conn, ~p"/conversations/private", %{"user_id" => user.id})
      assert redirected_to(conn) == ~p"/login"
    end

    test "creates private conversation and redirects", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()

      conn = 
        conn
        |> login_user(user1)
        |> post(~p"/conversations/private", %{"user_id" => user2.id})

      assert %{id: conversation_id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/conversations/#{conversation_id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Conversation started successfully"

      # Verify conversation was created
      conversation = Conversations.get_conversation!(conversation_id)
      assert conversation.type == "private"
      assert Conversations.participant?(conversation_id, user1.id)
      assert Conversations.participant?(conversation_id, user2.id)
    end
  end

  # Helper function to log in a user
  defp login_user(conn, user) do
    token = Messenger.Accounts.generate_user_session_token(user)
    
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:current_user, user)
    |> Plug.Conn.assign(:current_user, user)
  end
end