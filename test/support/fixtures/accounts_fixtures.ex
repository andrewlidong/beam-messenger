defmodule Messenger.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Messenger.Accounts` context.
  """

  alias Messenger.Accounts

  @doc """
  Returns a valid user password.
  """
  def valid_user_password, do: "password123456"

  @doc """
  Generates a unique username.
  """
  def unique_username, do: "user#{System.unique_integer([:positive])}"

  @doc """
  Generates a unique email.
  """
  def unique_email, do: "user#{System.unique_integer([:positive])}@example.com"

  @doc """
  Generates a user attributes map.
  """
  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      username: unique_username(),
      email: unique_email(),
      password: valid_user_password()
    })
  end

  @doc """
  Creates a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    # Reload the user from the database to ensure all fields are populated
    user = Accounts.get_user!(user.id)
    
    # Remove the password as it's not stored in the database
    %{user | password: nil}
  end

  @doc """
  Sets up the conn with an authenticated user session.
  """
  def log_in_user(%{conn: conn, user: user}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  @doc """
  Sets up the conn with an authenticated user session.
  """
  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  @doc """
  Extracts the user token from the conn.
  """
  def extract_user_token(fun) do
    {:ok, captured_token} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured_token, "[TOKEN]")
    token
  end
end
