defmodule Messenger.Conversations.ConversationParticipantTest do
  use Messenger.DataCase

  alias Messenger.Conversations.ConversationParticipant

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{
        conversation_id: 1,
        user_id: 1,
        role: "member",
        joined_at: DateTime.utc_now(),
        is_active: true
      })

      assert changeset.valid?
      assert get_field(changeset, :conversation_id) == 1
      assert get_field(changeset, :user_id) == 1
      assert get_field(changeset, :role) == "member"
    end

    test "defaults role to member" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{
        conversation_id: 1,
        user_id: 1
      })

      assert changeset.valid?
      assert get_field(changeset, :role) == "member"
    end

    test "validates role inclusion" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{
        conversation_id: 1,
        user_id: 1,
        role: "invalid_role"
      })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).role
    end

    test "accepts admin role" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{
        conversation_id: 1,
        user_id: 1,
        role: "admin"
      })

      assert changeset.valid?
      assert get_field(changeset, :role) == "admin"
    end

    test "requires conversation_id and user_id" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).conversation_id
      assert "can't be blank" in errors_on(changeset).user_id
    end
  end
end