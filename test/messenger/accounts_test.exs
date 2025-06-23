defmodule Messenger.AccountsTest do
  use Messenger.DataCase

  alias Messenger.Accounts
  alias Messenger.Accounts.User

  describe "users" do
    @valid_attrs %{
      username: "testuser",
      email: "test@example.com",
      password: "password123456"
    }
    @update_attrs %{
      username: "updateduser",
      email: "updated@example.com"
    }
    @invalid_attrs %{
      username: nil,
      email: nil,
      password: nil
    }
    @short_password_attrs %{
      username: "testuser",
      email: "test@example.com",
      password: "short"
    }
    @invalid_email_attrs %{
      username: "testuser",
      email: "not-an-email",
      password: "password123456"
    }

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.register_user()

      # Return the user as is - don't strip password_hash
      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user(user.id) == user
    end

    test "get_user/1 returns nil for non-existent id" do
      assert Accounts.get_user(999_999) == nil
    end

    test "get_user_by_username/1 returns user with matching username" do
      user = user_fixture()
      assert Accounts.get_user_by_username(user.username) == user
    end

    test "get_user_by_username/1 returns nil for non-existent username" do
      assert Accounts.get_user_by_username("nonexistent") == nil
    end

    test "get_user_by_email/1 returns user with matching email" do
      user = user_fixture()
      assert Accounts.get_user_by_email(user.email) == user
    end

    test "get_user_by_email/1 returns nil for non-existent email" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end

    test "register_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.register_user(@valid_attrs)
      assert user.username == @valid_attrs.username
      assert user.email == @valid_attrs.email
      assert is_binary(user.password_hash)
    end

    test "register_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(@invalid_attrs)
    end

    test "register_user/1 with short password returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(@short_password_attrs)
    end

    test "register_user/1 with invalid email returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(@invalid_email_attrs)
    end

    test "register_user/1 enforces unique usernames" do
      assert {:ok, %User{}} = Accounts.register_user(@valid_attrs)
      assert {:error, changeset} = Accounts.register_user(@valid_attrs)
      assert %{username: ["has already been taken"]} = errors_on(changeset)
    end

    test "register_user/1 enforces unique emails" do
      assert {:ok, %User{}} = Accounts.register_user(@valid_attrs)

      similar_attrs = %{
        username: "different",
        email: @valid_attrs.email,
        password: "password123456"
      }

      assert {:error, changeset} = Accounts.register_user(similar_attrs)
      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, @update_attrs)
      assert updated_user.username == @update_attrs.username
      assert updated_user.email == @update_attrs.email
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "update_user_password/3 with valid data updates the password" do
      user = user_fixture()

      assert {:ok, updated_user} =
               Accounts.update_user_password(user, @valid_attrs.password, %{
                 password: "new_password123"
               })

      assert Accounts.valid_password?(updated_user, "new_password123")
      refute Accounts.valid_password?(updated_user, @valid_attrs.password)
    end

    test "update_user_password/3 with invalid current password returns error" do
      user = user_fixture()

      assert {:error, :invalid_current_password} =
               Accounts.update_user_password(user, "wrong_password", %{
                 password: "new_password123"
               })

      assert Accounts.valid_password?(Accounts.get_user!(user.id), @valid_attrs.password)
    end

    test "update_user_password/3 with invalid new password returns error changeset" do
      user = user_fixture()

      assert {:error, changeset} =
               Accounts.update_user_password(user, @valid_attrs.password, %{password: "short"})

      assert %{password: ["should be at least 8 character(s)"]} = errors_on(changeset)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
      assert Accounts.get_user(user.id) == nil
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "change_user_registration/1 returns a user registration changeset" do
      assert %Ecto.Changeset{} = Accounts.change_user_registration(%User{})
    end
  end

  describe "authentication" do
    setup do
      user_attrs = %{
        username: "authuser",
        email: "auth@example.com",
        password: "password123456"
      }

      {:ok, user} = Accounts.register_user(user_attrs)
      %{user: user, password: user_attrs.password}
    end

    test "authenticate_by_username_and_password/2 with valid credentials", %{
      user: user,
      password: password
    } do
      assert {:ok, authenticated_user} =
               Accounts.authenticate_by_username_and_password(user.username, password)

      assert authenticated_user.id == user.id
    end

    test "authenticate_by_username_and_password/2 with invalid password", %{user: user} do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_username_and_password(user.username, "wrong_password")
    end

    test "authenticate_by_username_and_password/2 with non-existent username" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_username_and_password("nonexistent", "any_password")
    end

    test "authenticate_by_email_and_password/2 with valid credentials", %{
      user: user,
      password: password
    } do
      assert {:ok, authenticated_user} =
               Accounts.authenticate_by_email_and_password(user.email, password)

      assert authenticated_user.id == user.id
    end

    test "authenticate_by_email_and_password/2 with invalid password", %{user: user} do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_email_and_password(user.email, "wrong_password")
    end

    test "authenticate_by_email_and_password/2 with non-existent email" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_email_and_password(
                 "nonexistent@example.com",
                 "any_password"
               )
    end

    test "valid_password?/2 returns true for valid password", %{user: user, password: password} do
      assert Accounts.valid_password?(user, password)
    end

    test "valid_password?/2 returns false for invalid password", %{user: user} do
      refute Accounts.valid_password?(user, "wrong_password")
    end
  end

  describe "session tokens" do
    setup do
      user_attrs = %{
        username: "tokenuser",
        email: "token@example.com",
        password: "password123456"
      }

      {:ok, user} = Accounts.register_user(user_attrs)
      %{user: user}
    end

    test "generate_user_session_token/1 returns a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert is_binary(token)
    end

    test "verify_user_session_token/1 returns user data for valid token", %{user: user} do
      token = Accounts.generate_user_session_token(user)

      assert {:ok, %{"user_id" => user_id, "username" => username}} =
               Accounts.verify_user_session_token(token)

      assert user_id == user.id
      assert username == user.username
    end

    test "verify_user_session_token/1 returns error for invalid token" do
      assert {:error, :invalid} = Accounts.verify_user_session_token("invalid_token")
    end

    test "verify_user_session_token/1 returns error for expired token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert {:error, :expired} = Accounts.verify_user_session_token(token, 0)
    end

    test "get_user_by_session_token/1 returns user for valid token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert retrieved_user = Accounts.get_user_by_session_token(token)
      assert retrieved_user.id == user.id
    end

    test "get_user_by_session_token/1 returns nil for invalid token" do
      assert Accounts.get_user_by_session_token("invalid_token") == nil
    end

    test "delete_session_token/1 returns :ok" do
      assert :ok = Accounts.delete_session_token("any_token")
    end
  end
end
