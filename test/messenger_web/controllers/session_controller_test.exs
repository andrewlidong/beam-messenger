defmodule MessengerWeb.SessionControllerTest do
  use MessengerWeb.ConnCase, async: true

  import Messenger.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, MessengerWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{conn: conn, user: user_fixture()}
  end

  describe "GET /login" do
    test "renders login form when user is not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      assert response =~ "Sign in to BEAM Messenger"
      assert response =~ "Username or Email"
      assert response =~ "Password"
      assert response =~ "Remember me"
    end

    test "redirects if user is already authenticated", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(~p"/login")
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /login" do
    test "logs the user in with valid username credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
    end

    test "logs the user in with valid email credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
    end

    test "returns error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username" => user.username, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Invalid username or password"
      assert is_nil(get_session(conn, :user_token))
    end

    test "returns error message with non-existent user", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username" => "nonexistent", "password" => "any_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Invalid username or password"
      assert is_nil(get_session(conn, :user_token))
    end

    test "returns error with invalid parameters", %{conn: conn} do
      conn = post(conn, ~p"/login", %{"invalid" => "params"})
      response = html_response(conn, 200)
      assert response =~ "Invalid login parameters"
      assert is_nil(get_session(conn, :user_token))
    end

    test "remembers user when remember_me is enabled", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_messenger_web_user_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "does not remember user when remember_me is disabled", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password()
          }
        })

      refute conn.resp_cookies["_messenger_web_user_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "writes user token cookie for WebSocket authentication", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert conn.resp_cookies["user_token"]
      assert redirected_to(conn) == "/"
    end
  end

  describe "DELETE /logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/logout")
      assert redirected_to(conn) == ~p"/login"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/logout")
      assert redirected_to(conn) == ~p"/login"
      refute get_session(conn, :user_token)
    end

    test "clears remember me cookie", %{conn: conn, user: user} do
      conn =
        conn
        |> put_resp_cookie("_messenger_web_user_remember_me", "test_token", [])
        |> log_in_user(user)
        |> delete(~p"/logout")

      # Check that the cookie is set with max_age: 0 (deleted)
      assert conn.resp_cookies["_messenger_web_user_remember_me"]
      assert conn.resp_cookies["_messenger_web_user_remember_me"].max_age == 0
    end

    test "clears user token cookie", %{conn: conn, user: user} do
      conn =
        conn
        |> put_resp_cookie("user_token", "test_token", [])
        |> log_in_user(user)
        |> delete(~p"/logout")

      # Check that the cookie is set with max_age: 0 (deleted)
      assert conn.resp_cookies["user_token"]
      assert conn.resp_cookies["user_token"].max_age == 0
    end
  end

  describe "session management" do
    test "session has live_socket_id for LiveView", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      assert get_session(conn, :live_socket_id) =~ "users_sessions:"
    end

    test "session is renewed on login", %{conn: conn, user: user} do
      session_before = conn.private.plug_session
      conn = log_in_user(conn, user)
      session_after = conn.private.plug_session
      refute session_before == session_after
    end
  end

  describe "redirect behavior" do
    test "redirects to stored return_to path if present", %{conn: conn, user: user} do
      conn =
        conn
        |> put_session(:user_return_to, "/chat/general")
        |> post(~p"/login", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == "/chat/general"
      refute get_session(conn, :user_return_to)
    end

    test "redirects to default path if no return_to is set", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/login", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == "/"
    end
  end
end
