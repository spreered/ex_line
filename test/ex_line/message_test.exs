defmodule ExLine.MessageTest do
  use ExUnit.Case, async: true

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
end
