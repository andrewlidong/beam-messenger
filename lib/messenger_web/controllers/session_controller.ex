defmodule MessengerWeb.SessionController do
  use MessengerWeb, :controller

  alias Messenger.Accounts
  alias MessengerWeb.UserAuth

  @doc """
  Renders the login form.
  """
  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  @doc """
  Processes login attempts and creates a new session if credentials are valid.
  """
  def create(conn, %{"user" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate_by_username_and_password(username, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user)

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> render(:new, error_message: "Invalid username or password")
    end
  end

  # Alternative login with email
  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_by_email_and_password(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user)

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:new, error_message: "Invalid email or password")
    end
  end

  # Fallback for invalid parameters
  def create(conn, _) do
    conn
    |> put_flash(:error, "Invalid login parameters")
    |> render(:new, error_message: "Invalid login parameters")
  end

  @doc """
  Logs the user out by clearing the session.
  """
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
