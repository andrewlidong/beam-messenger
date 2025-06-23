defmodule Messenger.Accounts.Avatar do
  @moduledoc """
  Provides avatar generation and URL helper functions.
  
  This module handles both uploaded avatars and default avatars (Gravatar or initials).
  It prioritizes uploaded avatars when available and falls back to defaults otherwise.
  """

  @doc """
  Returns the appropriate avatar URL for a user.
  
  Prioritizes:
  1. User's uploaded avatar if available
  2. Gravatar if user has an email
  3. Initials-based placeholder avatar as last resort
  
  ## Examples
  
      iex> get_avatar_url(%User{avatar: "/uploads/avatar.jpg"})
      "/uploads/avatar.jpg"
      
      iex> get_avatar_url(%User{email: "user@example.com"})
      "https://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?s=200&d=mp"
      
      iex> get_avatar_url(%User{username: "John Doe"})
      "https://ui-avatars.com/api/?name=JD&background=random&color=fff"
  """
  def get_avatar_url(user) do
    cond do
      # Case 1: User has uploaded an avatar
      user.avatar && String.trim(user.avatar) != "" ->
        user.avatar
        
      # Case 2: User has an email, use Gravatar
      user.email && String.trim(user.email) != "" ->
        gravatar_url(user.email)
        
      # Case 3: Fall back to initials-based avatar
      true ->
        initials_avatar_url(user.username)
    end
  end

  @doc """
  Generates a Gravatar URL for the given email.
  
  ## Options
  
  * `:size` - Size in pixels (default: 200)
  * `:default` - Default image style if no Gravatar exists (default: "mp" for mystery person)
  * `:rating` - Content rating filter (default: "g" for general audiences)
  
  ## Examples
  
      iex> gravatar_url("user@example.com")
      "https://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?s=200&d=mp"
      
      iex> gravatar_url("user@example.com", size: 100, default: "identicon")
      "https://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?s=100&d=identicon"
  """
  def gravatar_url(email, opts \\ []) do
    size = Keyword.get(opts, :size, 200)
    default = Keyword.get(opts, :default, "mp")
    rating = Keyword.get(opts, :rating, "g")
    
    email
    |> String.trim()
    |> String.downcase()
    |> md5_hash()
    |> build_gravatar_url(size, default, rating)
  end
  
  @doc """
  Generates an avatar URL based on user initials.
  
  Uses the ui-avatars.com service to generate a placeholder avatar
  with the user's initials on a colored background.
  
  ## Options
  
  * `:size` - Size in pixels (default: 200)
  * `:background` - Background color (default: "random")
  * `:color` - Text color (default: "fff" for white)
  
  ## Examples
  
      iex> initials_avatar_url("John Doe")
      "https://ui-avatars.com/api/?name=JD&background=random&color=fff"
      
      iex> initials_avatar_url("John Doe", size: 100, background: "0088cc")
      "https://ui-avatars.com/api/?name=JD&size=100&background=0088cc&color=fff"
  """
  def initials_avatar_url(username, opts \\ []) do
    size = Keyword.get(opts, :size, 200)
    background = Keyword.get(opts, :background, "random")
    color = Keyword.get(opts, :color, "fff")
    
    initials = extract_initials(username)
    
    query = URI.encode_query(%{
      "name" => initials,
      "size" => to_string(size),
      "background" => background,
      "color" => color
    })
    
    "https://ui-avatars.com/api/?#{query}"
  end
  
  @doc """
  Extracts initials from a username or full name.
  
  Takes the first letter of each word, up to 2 letters.
  
  ## Examples
  
      iex> extract_initials("John Doe")
      "JD"
      
      iex> extract_initials("jane")
      "J"
      
      iex> extract_initials("John Paul George Ringo")
      "JP"
  """
  def extract_initials(nil), do: "??"
  def extract_initials(username) do
    username
    |> String.split(" ", trim: true)
    |> Enum.map(fn name -> String.first(name) end)
    |> Enum.filter(& &1)
    |> Enum.take(2)
    |> Enum.join()
    |> String.upcase()
  end
  
  @doc """
  Generates a random hex color code.
  
  ## Examples
  
      iex> random_color()
      "3f8a12" # (random hex color)
  """
  def random_color do
    :rand.seed(:exsplus, {System.os_time(), System.unique_integer([:positive]), :erlang.phash2(self())})
    
    Integer.to_string(:rand.uniform(16777215), 16)
    |> String.pad_leading(6, "0")
  end
  
  # Private helper functions
  
  defp md5_hash(str) do
    :crypto.hash(:md5, str) 
    |> Base.encode16(case: :lower)
  end
  
  defp build_gravatar_url(hash, size, default, rating) do
    query = URI.encode_query(%{
      "s" => to_string(size),
      "d" => default,
      "r" => rating
    })
    
    "https://www.gravatar.com/avatar/#{hash}?#{query}"
  end
end
