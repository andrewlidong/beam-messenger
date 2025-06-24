defmodule Messenger.Conversations.ConversationTest do
  use Messenger.DataCase

  alias Messenger.Conversations.Conversation

  describe "changeset/2" do
    test "valid changeset for private conversation" do
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "private",
        created_by_id: 1,
        is_active: true
      })

      assert changeset.valid?
      assert get_field(changeset, :type) == "private"
      assert get_field(changeset, :created_by_id) == 1
    end

    test "valid changeset for group conversation" do
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "group",
        name: "Test Group",
        description: "A test group",
        created_by_id: 1,
        is_active: true
      })

      assert changeset.valid?
      assert get_field(changeset, :type) == "group"
      assert get_field(changeset, :name) == "Test Group"
    end

    test "requires name for group conversations" do
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "group",
        created_by_id: 1
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "does not require name for private conversations" do
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "private",
        created_by_id: 1
      })

      assert changeset.valid?
    end

    test "validates type inclusion" do
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "invalid_type",
        created_by_id: 1
      })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).type
    end

    test "requires type and created_by_id" do
      changeset = Conversation.changeset(%Conversation{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).type
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "validates name length for group conversations" do
      # Name too long
      long_name = String.duplicate("a", 101)
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "group",
        name: long_name,
        created_by_id: 1
      })

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).name

      # Empty name
      changeset = Conversation.changeset(%Conversation{}, %{
        type: "group",
        name: "",
        created_by_id: 1
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end