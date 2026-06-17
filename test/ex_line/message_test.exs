defmodule ExLine.MessageTest do
  use ExUnit.Case, async: true

  import ExLine.Conformance

  doctest ExLine.Message
  doctest ExLine.Message.Action
  doctest ExLine.Message.Template
  doctest ExLine.Message.Imagemap
  doctest ExLine.Message.Flex

  alias ExLine.Message
  alias ExLine.Message.{Action, Flex, Imagemap, Template}

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

    test "text_v2 → TextMessageV2" do
      assert_conforms(Message.text_v2("hi {u}"), "TextMessageV2")
    end

    test "image → ImageMessage" do
      assert_conforms(Message.image("https://x/o.jpg", "https://x/p.jpg"), "ImageMessage")
    end

    test "video → VideoMessage" do
      msg = Message.video("https://x/o.mp4", "https://x/p.jpg", tracking_id: "t1")
      assert_conforms(msg, "VideoMessage")
    end

    test "audio → AudioMessage" do
      assert_conforms(Message.audio("https://x/a.m4a", 60_000), "AudioMessage")
    end

    test "location → LocationMessage" do
      assert_conforms(Message.location("Office", "Taipei", 25.0, 121.5), "LocationMessage")
    end

    test "imagemap → ImagemapMessage" do
      area = Imagemap.area(0, 0, 520, 1040)

      msg =
        Message.imagemap(
          "https://x/base",
          "alt",
          Imagemap.base_size(1040, 1040),
          [Imagemap.message_action("hi", area), Imagemap.uri_action("https://x", area)]
        )

      assert_conforms(msg, "ImagemapMessage")
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

    test "carousel template → TemplateMessage" do
      col =
        Template.carousel_column("desc", [Action.message("A", "a")],
          title: "Title",
          thumbnail_image_url: "https://x/i.jpg"
        )

      assert_conforms(Template.carousel([col, col]), "TemplateMessage")
    end

    test "image carousel template → TemplateMessage" do
      col = Template.image_carousel_column("https://x/i.jpg", Action.uri("Open", "https://x"))
      assert_conforms(Template.image_carousel([col, col]), "TemplateMessage")
    end

    test "flex bubble → FlexMessage" do
      bubble =
        Flex.bubble(
          header: Flex.box(:vertical, [Flex.text("Title", weight: "bold")]),
          hero: Flex.image("https://x/h.jpg", size: "full"),
          body:
            Flex.box(:vertical, [
              Flex.text("Body", wrap: true),
              Flex.separator(margin: "md")
            ]),
          footer:
            Flex.box(:vertical, [Flex.button(Action.uri("Open", "https://x"), style: "primary")])
        )

      assert_conforms(Flex.flex("alt", bubble), "FlexMessage")
    end

    test "flex carousel → FlexMessage" do
      bubble = Flex.bubble(body: Flex.box(:vertical, [Flex.text("Hi")]))
      assert_conforms(Flex.flex("alt", Flex.carousel([bubble, bubble])), "FlexMessage")
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

    test "datetimepicker action → DatetimePickerAction" do
      assert_conforms(
        Action.datetimepicker("Pick", "d", :datetime, initial: "2026-01-01t00:00"),
        "DatetimePickerAction"
      )
    end

    test "camera action → CameraAction" do
      assert_conforms(Action.camera("Camera"), "CameraAction")
    end

    test "camera_roll action → CameraRollAction" do
      assert_conforms(Action.camera_roll("Album"), "CameraRollAction")
    end

    test "location action → LocationAction" do
      assert_conforms(Action.location("Location"), "LocationAction")
    end

    test "clipboard action → ClipboardAction" do
      assert_conforms(Action.clipboard("Copy", "copied"), "ClipboardAction")
    end

    test "richmenu_switch action → RichMenuSwitchAction" do
      assert_conforms(Action.richmenu_switch("Next", "menu-b", "d"), "RichMenuSwitchAction")
    end
  end
end
