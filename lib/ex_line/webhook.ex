defmodule ExLine.Webhook do
  @moduledoc """
  Parse incoming LINE webhook payloads into event structs.

  `parse/1` is **total — it never raises**. This is required for forward
  compatibility: LINE adds new event/message types, enum values, and fields without
  notice, and the server must keep working
  ([dev guidelines](https://developers.line.biz/en/docs/messaging-api/development-guidelines/)).
  Accordingly:

    * an unrecognized event/message `type` degrades to `ExLine.Webhook.Event.Unknown` /
      `ExLine.Webhook.Message.Unknown` (mirroring the official SDKs),
    * unknown fields are ignored (the original payload is kept in each struct's `raw`),
    * a single malformed event degrades to `Event.Unknown` rather than failing the batch.

  Verify the signature first with `ExLine.Webhook.Signature` / `ExLine.Webhook.Plug`.

  ## Example

      body |> Jason.decode!() |> ExLine.Webhook.parse() |> Enum.each(&MyRouter.call/1)

  Ref: https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects
  """

  alias ExLine.Webhook.{Event, Message, Source}

  @type event ::
          Event.Message.t()
          | Event.Postback.t()
          | Event.Follow.t()
          | Event.Unfollow.t()
          | Event.Join.t()
          | Event.Leave.t()
          | Event.MemberJoined.t()
          | Event.MemberLeft.t()
          | Event.Unsend.t()
          | Event.VideoPlayComplete.t()
          | Event.Beacon.t()
          | Event.AccountLink.t()
          | Event.Membership.t()
          | Event.Activated.t()
          | Event.Deactivated.t()
          | Event.BotSuspended.t()
          | Event.BotResumed.t()
          | Event.Module.t()
          | Event.PnpDeliveryCompletion.t()
          | Event.Unknown.t()

  @doc """
  Parses a decoded webhook request (`%{"events" => [...]}`) or a list of raw events
  into a list of event structs.
  """
  @spec parse(map() | [map()]) :: [event()]
  def parse(%{"events" => events}) when is_list(events), do: Enum.map(events, &parse_event/1)
  def parse(events) when is_list(events), do: Enum.map(events, &parse_event/1)
  def parse(_), do: []

  @doc """
  Parses a single raw event map into an event struct. Never raises — anything it
  can't model becomes an `Event.Unknown`.
  """
  @spec parse_event(map()) :: event()
  def parse_event(raw) when is_map(raw) do
    do_parse_event(raw)
  rescue
    _ -> %Event.Unknown{type: Map.get(raw, "type"), raw: raw}
  end

  def parse_event(raw), do: %Event.Unknown{type: nil, raw: raw}

  defp do_parse_event(%{"type" => "message"} = raw) do
    struct(Event.Message, [
      {:reply_token, raw["replyToken"]},
      {:message, Message.parse(raw["message"])} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "postback"} = raw) do
    struct(Event.Postback, [
      {:reply_token, raw["replyToken"]},
      {:postback, postback(raw["postback"])} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "follow"} = raw) do
    struct(Event.Follow, [
      {:reply_token, raw["replyToken"]},
      {:follow, raw["follow"]} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "unfollow"} = raw), do: struct(Event.Unfollow, common(raw))

  defp do_parse_event(%{"type" => "join"} = raw) do
    struct(Event.Join, [{:reply_token, raw["replyToken"]} | common(raw)])
  end

  defp do_parse_event(%{"type" => "leave"} = raw), do: struct(Event.Leave, common(raw))

  defp do_parse_event(%{"type" => "memberJoined"} = raw) do
    struct(Event.MemberJoined, [
      {:reply_token, raw["replyToken"]},
      {:joined, members(raw["joined"])} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "memberLeft"} = raw) do
    struct(Event.MemberLeft, [{:left, members(raw["left"])} | common(raw)])
  end

  defp do_parse_event(%{"type" => "unsend"} = raw) do
    struct(Event.Unsend, [{:unsend, raw["unsend"]} | common(raw)])
  end

  defp do_parse_event(%{"type" => "videoPlayComplete"} = raw) do
    struct(Event.VideoPlayComplete, [
      {:reply_token, raw["replyToken"]},
      {:video_play_complete, raw["videoPlayComplete"]} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "beacon"} = raw) do
    struct(Event.Beacon, [
      {:reply_token, raw["replyToken"]},
      {:beacon, raw["beacon"]} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "accountLink"} = raw) do
    struct(Event.AccountLink, [
      {:reply_token, raw["replyToken"]},
      {:link, raw["link"]} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "membership"} = raw) do
    struct(Event.Membership, [
      {:reply_token, raw["replyToken"]},
      {:membership, raw["membership"]} | common(raw)
    ])
  end

  defp do_parse_event(%{"type" => "activated"} = raw) do
    struct(Event.Activated, [{:chat_control, raw["chatControl"]} | common(raw)])
  end

  defp do_parse_event(%{"type" => "deactivated"} = raw),
    do: struct(Event.Deactivated, common(raw))

  defp do_parse_event(%{"type" => "botSuspended"} = raw),
    do: struct(Event.BotSuspended, common(raw))

  defp do_parse_event(%{"type" => "botResumed"} = raw),
    do: struct(Event.BotResumed, common(raw))

  defp do_parse_event(%{"type" => "module"} = raw) do
    struct(Event.Module, [{:module, raw["module"]} | common(raw)])
  end

  defp do_parse_event(%{"type" => "delivery"} = raw) do
    struct(Event.PnpDeliveryCompletion, [{:delivery, raw["delivery"]} | common(raw)])
  end

  defp do_parse_event(%{"type" => type} = raw),
    do: struct(Event.Unknown, [{:type, type} | common(raw)])

  defp do_parse_event(raw), do: %Event.Unknown{type: nil, raw: raw}

  # Common envelope shared by every event. `type` is included so concrete structs
  # carry it too.
  defp common(raw) do
    [
      type: raw["type"],
      mode: raw["mode"],
      timestamp: raw["timestamp"],
      source: Source.parse(raw["source"]),
      webhook_event_id: raw["webhookEventId"],
      delivery_context: raw["deliveryContext"],
      raw: raw
    ]
  end

  defp postback(%{"data" => data} = pb), do: %{data: data, params: pb["params"]}
  defp postback(pb), do: pb

  defp members(%{"members" => members}) when is_list(members) do
    %{members: Enum.map(members, &Source.parse/1)}
  end

  defp members(other), do: other
end
