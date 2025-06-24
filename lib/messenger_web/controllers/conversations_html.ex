defmodule MessengerWeb.ConversationsHTML do
  use MessengerWeb, :html

  embed_templates "conversations_html/*"

  def format_timestamp(timestamp) when is_struct(timestamp, DateTime) do
    timestamp
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 5)
  end

  def format_timestamp(_), do: ""

  def conversation_title(conversation, current_user) do
    case conversation.type do
      "group" ->
        conversation.name || "Group Chat"
      "private" ->
        # Find the other participant
        other_participant = 
          Enum.find(conversation.participants, fn p -> 
            p.user_id != current_user.id 
          end)
        
        if other_participant && other_participant.user do
          other_participant.user.username
        else
          "Private Chat"
        end
    end
  end

  def truncate_message(text, length \\ 50) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end
end