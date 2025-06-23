defmodule Messenger.Accounts do
  @moduledoc """
  The Accounts context.
  
  This module provides functions for managing user accounts in the application.
  It handles user registration, authentication, and CRUD operations for user accounts.
  
  Note: This module requires the bcrypt_elixir package.
  Add the following to your dependencies in mix.exs:
  
  {:bcrypt_elixir, "~> 3.0"}
  """

  import Ecto.Query, warn: false
  alias Messenger.Repo
  alias Messenger.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user.
  
  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by their username.
  
  Returns `nil` if no user with that username exists.

  ## Examples

      iex> get_user_by_username("johndoe")
      %User{}

      iex> get_user_by_username("nonexistent")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by their email.
  
  Returns `nil` if no user with that email exists.

  ## Examples

      iex> get_user_by_email("john@example.com")
      %User{}

      iex> get_user_by_email("nonexistent@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's password.

  ## Examples

      iex> update_user_password(user, "valid_current_password", %{password: "new_password"})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid_current_password", %{password: "new_password"})
      {:error, :invalid_current_password}

      iex> update_user_password(user, "valid_current_password", %{password: "inv"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(%User{} = user, current_password, attrs) do
    if valid_password?(user, current_password) do
      user
      |> User.password_changeset(attrs)
      |> Repo.update()
    else
      {:error, :invalid_current_password}
    end
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user registration changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  @doc """
  Authenticates a user by username and password.

  ## Examples

      iex> authenticate_by_username_and_password("johndoe", "correct_password")
      {:ok, %User{}}

      iex> authenticate_by_username_and_password("johndoe", "invalid_password")
      {:error, :invalid_credentials}

      iex> authenticate_by_username_and_password("nonexistent", "password")
      {:error, :invalid_credentials}

  """
  def authenticate_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = get_user_by_username(username)
    authenticate_user(user, password)
  end

  @doc """
  Authenticates a user by email and password.

  ## Examples

      iex> authenticate_by_email_and_password("john@example.com", "correct_password")
      {:ok, %User{}}

      iex> authenticate_by_email_and_password("john@example.com", "invalid_password")
      {:error, :invalid_credentials}

      iex> authenticate_by_email_and_password("nonexistent@example.com", "password")
      {:error, :invalid_credentials}

  """
  def authenticate_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    authenticate_user(user, password)
  end

  defp authenticate_user(user, password) do
    cond do
      user && valid_password?(user, password) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        # Perform a dummy check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Validates if the provided password matches the user's password hash.

  ## Examples

      iex> valid_password?(user, "correct_password")
      true

      iex> valid_password?(user, "invalid_password")
      false

  """
  def valid_password?(%User{password_hash: password_hash}, password)
      when is_binary(password_hash) and is_binary(password) do
    Bcrypt.verify_pass(password, password_hash)
  end

  @doc """
  Generates a session token for a user.
  """
  def generate_user_session_token(%User{} = user) do
    Phoenix.Token.sign(
      MessengerWeb.Endpoint,
      "user socket",
      %{"user_id" => user.id, "username" => user.username}
    )
  end

  @doc """
  Verifies a user session token.
  """
  def verify_user_session_token(token, max_age \\ 1_209_600) do
    Phoenix.Token.verify(
      MessengerWeb.Endpoint,
      "user socket",
      token,
      max_age: max_age
    )
  end

  # ------------------------------------------------------------------
  # Session-token helpers expected by MessengerWeb.UserAuth
  # ------------------------------------------------------------------

  @doc """
  Retrieves the user associated with the given session `token`.

  It decodes & verifies the signed token and fetches the user from the DB.
  Returns `nil` if the token is invalid, expired, or the user cannot be found.
  """
  def get_user_by_session_token(token) when is_binary(token) do
    with {:ok, %{"user_id" => user_id}} <- verify_user_session_token(token) do
      get_user(user_id)
    else
      _ -> nil
    end
  end

  @doc """
  Placeholder for deleting a session token.

  Since we use stateless, signed tokens (Phoenix.Token), there is no
  server-side token store to invalidate.  We simply return `:ok` so that
  the `UserAuth` module can treat the call as successful.
  """
  @spec delete_session_token(String.t()) :: :ok
  def delete_session_token(_token), do: :ok
end
