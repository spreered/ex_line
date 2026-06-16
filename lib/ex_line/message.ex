defmodule ExLine.Message do
  @moduledoc """
  Builders for LINE message objects.

  Functions return plain maps conforming to the LINE Messaging API message object
  spec, ready to pass to `ExLine.Messaging.reply/4` / `push/4`. Template and action
  objects live in `ExLine.Message.Template` and `ExLine.Message.Action`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#message-objects
  """

  @doc """
  Text message.

  Ref: https://developers.line.biz/en/reference/messaging-api/#text-message

      iex> ExLine.Message.text("hello")
      %{type: "text", text: "hello"}
  """
  @spec text(String.t()) :: map()
  def text(text), do: %{type: "text", text: text}

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
end
