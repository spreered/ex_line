defmodule ExLine.Message do
  @moduledoc """
  Builders for LINE message objects.

  Functions return plain maps conforming to the LINE Messaging API message object
  spec, ready to pass to `ExLine.Messaging.reply/4` / `push/4`. Template, action,
  flex and imagemap sub-objects live in `ExLine.Message.Template`,
  `ExLine.Message.Action`, `ExLine.Message.Flex` and `ExLine.Message.Imagemap`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#message-objects
  """

  @doc """
  Text message.

  Options: `:emojis` (list of LINE emoji objects), `:quote_token` (quote a message).

  Ref: https://developers.line.biz/en/reference/messaging-api/#text-message

      iex> ExLine.Message.text("hello")
      %{type: "text", text: "hello"}

      iex> ExLine.Message.text("hi", quote_token: "qt")
      %{type: "text", text: "hi", quoteToken: "qt"}
  """
  @spec text(String.t(), keyword()) :: map()
  def text(text, opts \\ []) do
    %{type: "text", text: text}
    |> maybe_put(:emojis, opts[:emojis])
    |> maybe_put(:quoteToken, opts[:quote_token])
  end

  @doc """
  Text message v2 — supports mentions/emoji via `{placeholder}` substitutions.

  Options: `:substitution` (map of placeholder => substitution object),
  `:quote_token`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#text-message-v2

      iex> ExLine.Message.text_v2("hello {user}")
      %{type: "textV2", text: "hello {user}"}
  """
  @spec text_v2(String.t(), keyword()) :: map()
  def text_v2(text, opts \\ []) do
    %{type: "textV2", text: text}
    |> maybe_put(:substitution, opts[:substitution])
    |> maybe_put(:quoteToken, opts[:quote_token])
  end

  @doc """
  Sticker message.

  Ref: https://developers.line.biz/en/reference/messaging-api/#sticker-message

      iex> ExLine.Message.sticker("446", "1988")
      %{type: "sticker", packageId: "446", stickerId: "1988"}
  """
  @spec sticker(String.t(), String.t()) :: map()
  def sticker(package_id, sticker_id),
    do: %{type: "sticker", packageId: package_id, stickerId: sticker_id}

  @doc """
  Image message.

  Ref: https://developers.line.biz/en/reference/messaging-api/#image-message

      iex> ExLine.Message.image("https://x/o.jpg", "https://x/p.jpg")
      %{type: "image", originalContentUrl: "https://x/o.jpg", previewImageUrl: "https://x/p.jpg"}
  """
  @spec image(String.t(), String.t()) :: map()
  def image(original_content_url, preview_image_url) do
    %{
      type: "image",
      originalContentUrl: original_content_url,
      previewImageUrl: preview_image_url
    }
  end

  @doc """
  Video message. Option `:tracking_id` correlates with the video viewing complete event.

  Ref: https://developers.line.biz/en/reference/messaging-api/#video-message

      iex> ExLine.Message.video("https://x/o.mp4", "https://x/p.jpg")
      %{type: "video", originalContentUrl: "https://x/o.mp4", previewImageUrl: "https://x/p.jpg"}
  """
  @spec video(String.t(), String.t(), keyword()) :: map()
  def video(original_content_url, preview_image_url, opts \\ []) do
    %{
      type: "video",
      originalContentUrl: original_content_url,
      previewImageUrl: preview_image_url
    }
    |> maybe_put(:trackingId, opts[:tracking_id])
  end

  @doc """
  Audio message. `duration` is in milliseconds.

  Ref: https://developers.line.biz/en/reference/messaging-api/#audio-message

      iex> ExLine.Message.audio("https://x/a.m4a", 60000)
      %{type: "audio", originalContentUrl: "https://x/a.m4a", duration: 60000}
  """
  @spec audio(String.t(), integer()) :: map()
  def audio(original_content_url, duration) do
    %{type: "audio", originalContentUrl: original_content_url, duration: duration}
  end

  @doc """
  Location message.

  Ref: https://developers.line.biz/en/reference/messaging-api/#location-message

      iex> ExLine.Message.location("Office", "Taipei", 25.0, 121.5)
      %{type: "location", title: "Office", address: "Taipei", latitude: 25.0, longitude: 121.5}
  """
  @spec location(String.t(), String.t(), number(), number()) :: map()
  def location(title, address, latitude, longitude) do
    %{type: "location", title: title, address: address, latitude: latitude, longitude: longitude}
  end

  @doc """
  Imagemap message — a tappable image divided into action areas.

  `base_size` is `%{width: w, height: h}`; `actions` are built with
  `ExLine.Message.Imagemap`. Option `:video`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#imagemap-message
  """
  @spec imagemap(String.t(), String.t(), map(), [map()], keyword()) :: map()
  def imagemap(base_url, alt_text, base_size, actions, opts \\ []) do
    %{
      type: "imagemap",
      baseUrl: base_url,
      altText: alt_text,
      baseSize: base_size,
      actions: actions
    }
    |> maybe_put(:video, opts[:video])
  end

  @doc """
  Coupon message. Option `:delivery_tag` (route tag for LINE OA Manager analysis).

  Ref: https://developers.line.biz/en/reference/messaging-api/#coupon-message

      iex> ExLine.Message.coupon("cpn-1")
      %{type: "coupon", couponId: "cpn-1"}
  """
  @spec coupon(String.t(), keyword()) :: map()
  def coupon(coupon_id, opts \\ []) do
    %{type: "coupon", couponId: coupon_id}
    |> maybe_put(:deliveryTag, opts[:delivery_tag])
  end

  @doc """
  Attaches quick reply actions to a message object.

  Ref: https://developers.line.biz/en/docs/messaging-api/using-quick-reply/

      iex> "hi" |> ExLine.Message.text() |> ExLine.Message.with_quick_reply([ExLine.Message.Action.message("Yes", "yes")])
      %{
        type: "text",
        text: "hi",
        quickReply: %{items: [%{type: "action", action: %{type: "message", label: "Yes", text: "yes"}}]}
      }
  """
  @spec with_quick_reply(map(), [map()]) :: map()
  def with_quick_reply(message, actions \\ []) do
    items =
      actions
      |> List.wrap()
      |> Enum.map(&%{type: "action", action: &1})

    Map.put(message, :quickReply, %{items: items})
  end

  @doc """
  Overrides the display name and icon of a single message (the "sender" / icon switch).

  Ref: https://developers.line.biz/en/reference/messaging-api/#icon-nickname-switch

      iex> "hi" |> ExLine.Message.text() |> ExLine.Message.with_sender("Bot", "https://example.com/i.png")
      %{type: "text", text: "hi", sender: %{name: "Bot", iconUrl: "https://example.com/i.png"}}
  """
  @spec with_sender(map(), String.t(), String.t()) :: map()
  def with_sender(message, name, icon_url),
    do: Map.put(message, :sender, %{name: name, iconUrl: icon_url})

  @doc false
  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)
end
