defmodule MessengerWeb.RegistrationController do
  use MessengerWeb, :controller

  alias Messenger.Accounts
  alias Messenger.Accounts.User
  alias MessengerWeb.UserAuth

  @doc """
  Renders the registration form.
  """
  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  @doc """
  Handles user registration form submission.
  
  Creates a new user account if the provided information is valid.
  Automatically logs the user in after successful registration.
  """
  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account created successfully!")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  @doc """
  Renders the account confirmation page after registration.
  
  This is useful if you want to add email verification later.
  """
  def confirmation(conn, _params) do
    conn
    |> put_layout(html: {MessengerWeb.Layouts, :minimal})
    |> render(:confirmation)
  end

  @doc """
  Renders the account settings page where users can update their profile.
  
  Requires authentication.
  """
  def edit(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  @doc """
  Updates user account settings.
  """
  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user(user, user_params) do
      {:ok, updated_user} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: ~p"/profile")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  @doc """
  Renders the password change form.
  """
  def edit_password(conn, _params) do
    changeset = Accounts.change_user(conn.assigns.current_user)
    render(conn, :edit_password, changeset: changeset)
  end

  @doc """
  Updates the user's password.
  """
  def update_password(conn, %{"current_password" => current_password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, current_password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: ~p"/profile")

      {:error, :invalid_current_password} ->
        changeset = Accounts.change_user(user)

        conn
        |> put_flash(:error, "Current password is incorrect.")
        |> render(:edit_password, changeset: changeset)

      {:error, changeset} ->
        render(conn, :edit_password, changeset: changeset)
    end
  end

  @doc """
  Deletes a user account.
  
  This is a destructive action and should be confirmed.
  """
  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    # Only allow users to delete their own account
    if user.id == conn.assigns.current_user.id do
      {:ok, _user} = Accounts.delete_user(user)

      conn
      |> put_flash(:info, "Account deleted successfully.")
      |> UserAuth.log_out_user()
    else
      conn
      |> put_flash(:error, "You can only delete your own account.")
      |> redirect(to: ~p"/profile")
    end
  end
end
