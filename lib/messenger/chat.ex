defmodule Messenger.Chat do
  @moduledoc """
  The Chat context.
  
  This module provides functions for managing chat messages in the application.
  It handles all database operations related to messages including creating,
  reading, updating, and deleting messages.
  """

  import Ecto.Query, warn: false
  alias Messenger.Repo
  alias Messenger.Chat.Message

  @doc """
  Returns the list of messages for a specific room.

  ## Examples

      iex> list_messages("room-123")
      [%Message{}, ...]

  """
  def list_messages(room_id) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: m.timestamp)
    |> Repo.all()
  end

  @doc """
  Returns the list of recent messages for a specific room with pagination.

  ## Examples

      iex> list_recent_messages("room-123", 20)
      [%Message{}, ...]

  """
  def list_recent_messages(room_id, limit \\ 50) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], desc: m.timestamp)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Gets a single message.
  
  Returns `nil` if the Message does not exist.

  ## Examples

      iex> get_message(123)
      %Message{}

      iex> get_message(456)
      nil

  """
  def get_message(id), do: Repo.get(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @doc """
  Gets messages by a specific user.

  ## Examples

      iex> get_messages_by_user("user-123")
      [%Message{}, ...]

  """
  def get_messages_by_user(user_id) do
    Message
    |> where([m], m.user_id == ^user_id)
    |> order_by([m], desc: m.timestamp)
    |> Repo.all()
  end

  @doc """
  Searches for messages containing specific text.

  ## Examples

      iex> search_messages("hello", "room-123")
      [%Message{}, ...]

  """
  def search_messages(query_text, room_id \\ nil) do
    base_query = from m in Message, 
                 where: ilike(m.text, ^"%#{query_text}%")
    
    query = if room_id do
      from m in base_query, where: m.room_id == ^room_id
    else
      base_query
    end
    
    query
    |> order_by([m], desc: m.timestamp)
    |> Repo.all()
  end

  @doc """
  Gets message count for a room.

  ## Examples

      iex> count_messages("room-123")
      42

  """
  def count_messages(room_id) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> select([m], count(m.id))
    |> Repo.one()
  end
end
