defmodule Messenger.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :avatar, :string
    # Virtual field – not persisted, only used for validation/hash generation
    field :password, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  Base changeset used by the more specialised changesets.
  Handles username/email updates and basic validations.
  """
  defp base_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  Changeset for registering a new user (requires password).
  """
  def registration_changeset(user, attrs) do
    user
    |> base_changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> hash_password()
  end

  @doc """
  Generic changeset used by the Accounts context for simple updates where
  only the username and/or e-mail might change. (No password handling.)
  """
  def changeset(user, attrs) do
    user
    |> base_changeset(attrs)
    |> cast(attrs, [:avatar])
  end

  @doc """
  Changeset for updating user profile (username / email only).
  """
  def update_changeset(user, attrs) do
    user
    |> base_changeset(attrs)
    |> cast(attrs, [:avatar])
  end

  @doc """
  Changeset for changing a user's password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> hash_password()
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  alias Bcrypt, as: BCrypt

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:password_hash, BCrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
