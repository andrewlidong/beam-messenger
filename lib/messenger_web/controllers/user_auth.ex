defmodule MessengerWeb.UserAuth do
  @moduledoc """
  Authentication module for Messenger.

  Handles user authentication, session management, and related plugs.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Messenger.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want the remember me functionality, change this.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_messenger_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  # Plug callbacks for use in router pipelines
  def init(opts), do: opts

  def call(conn, opts) do
    case opts do
      :fetch_current_user -> fetch_current_user(conn, [])
      :require_authenticated_user -> require_authenticated_user(conn, [])
      :redirect_if_user_is_authenticated -> redirect_if_user_is_authenticated(conn, [])
      _ -> conn
    end
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session to avoid fixation attacks.
  It sets a `:user_token` in the session, which is used to authenticate API requests.
  It also sets a cookie with the user token for WebSocket authentication.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> put_resp_cookie("user_token", token, sign: true, max_age: @max_age)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole session
  # to avoid fixation attacks. If there is any data in the session you
  # may want to preserve after log in/log out, you must explicitly
  # fetch the session data before clearing and then immediately set it after clearing.
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. It also invalidates the user token.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      MessengerWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> delete_resp_cookie("user_token")
    |> redirect(to: "/login")
  end

  @doc """
  Authenticates the user by looking into the session and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If not authenticated, redirects to login page.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.

  If authenticated, redirects to the main page.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
