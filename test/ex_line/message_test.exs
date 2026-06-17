defmodule ExLine.MessageTest do
  use ExUnit.Case, async: true

  import ExLine.Conformance

  doctest ExLine.Message
  doctest ExLine.Message.Action
  doctest ExLine.Message.Template

  alias ExLine.Message
  alias ExLine.Message.{Action, Template}

  test "text/1 builds a text message" do
    assert Message.text("hi") == %{type: "text", text: "hi"}
  end

  test "with_quick_reply wraps actions as quick reply items" do
    msg = Message.text("hi") |> Message.with_quick_reply([Action.message("Yes", "y")])

    assert msg.quickReply == %{
             items: [%{type: "action", action: %{type: "message", label: "Yes", text: "y"}}]
           }
  end

  test "with_sender overrides name and icon" do
    msg = Message.text("hi") |> Message.with_sender("Bot", "https://x/i.png")
    assert msg.sender == %{name: "Bot", iconUrl: "https://x/i.png"}
  end

  test "buttons template includes optional fields only when provided" do
    plain = Template.buttons("t", [Action.message("A", "a")])
    refute Map.has_key?(plain.template, :title)

    titled = Template.buttons("t", [Action.message("A", "a")], title: "Title", alt_text: "alt")
    assert titled.altText == "alt"
    assert titled.template.title == "Title"
  end

  test "postback action includes display_text when given" do
    assert Action.postback("L", "d", display_text: "shown") == %{
             type: "postback",
             label: "L",
             data: "d",
             displayText: "shown"
           }
  end

  # Conformance against LINE's official OpenAPI spec (see ExLine.Conformance).
  # Run all conformance checks with `mix test --only conformance`.
  describe "conformance" do
    @describetag :conformance

    test "text → TextMessage" do
      assert_conforms(Message.text("hello"), "TextMessage")
    end

    test "sticker → StickerMessage" do
      assert_conforms(Message.sticker("446", "1988"), "StickerMessage")
    end

    test "text with quick reply → TextMessage" do
      msg = Message.text("hi") |> Message.with_quick_reply([Action.message("Yes", "y")])
      assert_conforms(msg, "TextMessage")
    end

    test "buttons template → TemplateMessage" do
      msg = Template.buttons("Pick one", [Action.message("A", "a"), Action.postback("B", "b")])
      assert_conforms(msg, "TemplateMessage")
    end

    test "confirm template → TemplateMessage" do
      msg = Template.confirm("OK?", [Action.message("Yes", "y"), Action.message("No", "n")])
      assert_conforms(msg, "TemplateMessage")
    end

    test "message action → MessageAction" do
      assert_conforms(Action.message("Label", "text"), "MessageAction")
    end

    test "postback action → PostbackAction" do
      assert_conforms(
        Action.postback("Buy", "action=buy", display_text: "Buying"),
        "PostbackAction"
      )
    end

    test "uri action → URIAction" do
      assert_conforms(Action.uri("Open", "https://example.com"), "URIAction")
    end
  end
end
