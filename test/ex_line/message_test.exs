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

  # Optional fields map snake_case opts to the correct camelCase wire key, and are
  # omitted when not given. Conformance can't guard these (a mis-named optional key
  # is silently accepted as an extra property and the real field just goes missing).
  describe "optional field mappings" do
    test "Message.text emojis" do
      emojis = [%{index: 0, productId: "p", emojiId: "e"}]
      assert Message.text("hi", emojis: emojis).emojis == emojis
      refute Map.has_key?(Message.text("hi"), :emojis)
    end

    test "Message.video trackingId" do
      assert Message.video("o", "p", tracking_id: "t").trackingId == "t"
      refute Map.has_key?(Message.video("o", "p"), :trackingId)
    end

    test "Message.text_v2 quoteToken / substitution" do
      msg = Message.text_v2("hi", quote_token: "q", substitution: %{"k" => %{}})
      assert msg.quoteToken == "q"
      assert msg.substitution == %{"k" => %{}}

      plain = Message.text_v2("hi")
      refute Map.has_key?(plain, :quoteToken)
      refute Map.has_key?(plain, :substitution)
    end

    test "Template.carousel_column camelCase keys" do
      default_action = Action.uri("Open", "https://x")

      col =
        Template.carousel_column("t", [],
          title: "T",
          thumbnail_image_url: "u",
          image_background_color: "#fff",
          default_action: default_action
        )

      assert col.title == "T"
      assert col.thumbnailImageUrl == "u"
      assert col.imageBackgroundColor == "#fff"
      assert col.defaultAction == default_action

      plain = Template.carousel_column("t", [])
      refute Map.has_key?(plain, :thumbnailImageUrl)
      refute Map.has_key?(plain, :defaultAction)
    end

    test "Template.carousel imageAspectRatio / imageSize" do
      template =
        Template.carousel([], image_aspect_ratio: "rectangle", image_size: "cover").template

      assert template.imageAspectRatio == "rectangle"
      assert template.imageSize == "cover"
      refute Map.has_key?(Template.carousel([]).template, :imageAspectRatio)
    end

    test "Flex.image aspectRatio / aspectMode" do
      img = Flex.image("u", aspect_ratio: "20:13", aspect_mode: "cover")
      assert img.aspectRatio == "20:13"
      assert img.aspectMode == "cover"
      refute Map.has_key?(Flex.image("u"), :aspectRatio)
    end

    test "Flex.box paddingAll / backgroundColor" do
      box = Flex.box(:vertical, [], padding_all: "10px", background_color: "#000")
      assert box.paddingAll == "10px"
      assert box.backgroundColor == "#000"
      refute Map.has_key?(Flex.box(:vertical, []), :paddingAll)
    end

    test "Action.datetimepicker initial/max/min and mode atom → string" do
      action =
        Action.datetimepicker("L", "d", :date,
          initial: "2026-01-01",
          max: "2026-12-31",
          min: "2026-01-01"
        )

      assert action.mode == "date"
      assert action.initial == "2026-01-01"
      assert action.max == "2026-12-31"
      assert action.min == "2026-01-01"

      refute Map.has_key?(Action.datetimepicker("L", "d", :time), :initial)
    end
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
