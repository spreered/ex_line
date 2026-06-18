defmodule ExLine.EventRouterTest do
  use ExUnit.Case, async: true

  alias ExLine.Webhook
  alias ExLine.Webhook.Event

  # Handlers record the dispatch into the test process for assertion.
  defmodule EchoHandler do
    use ExLine.EventHandler

    @impl true
    def handle_event(action, event, assigns) do
      send(self(), {:handled, action, event, assigns})
      :ok
    end
  end

  defmodule Router do
    use ExLine.EventRouter

    text("hello", %{role: :admin}, EchoHandler, :admin_hello)
    text("hello", EchoHandler, :hello)
    message(:image, EchoHandler, :on_image)
    postback("buy", EchoHandler, :buy)
    follow(EchoHandler, :welcome)
    member_joined(EchoHandler, :greet)
    unsend(EchoHandler, :unsent)
    beacon(EchoHandler, :on_beacon)
    default(EchoHandler, :fallback)

    @impl true
    def before_action(event, assigns), do: {event, Map.put(assigns, :seen, true)}
  end

  defp route(raw, assigns \\ %{}), do: raw |> Webhook.parse_event() |> Router.call(assigns)

  defp text_event(text),
    do: %{"type" => "message", "message" => %{"type" => "text", "text" => text}}

  test "routes a text message to its handler/action" do
    route(text_event("hello"))
    assert_received {:handled, :hello, %Event.Message{}, %{seen: true}}
  end

  test "assigns pattern selects a more specific route" do
    route(text_event("hello"), %{role: :admin})
    assert_received {:handled, :admin_hello, _event, _assigns}
  end

  test "routes any image message by content kind" do
    route(%{"type" => "message", "message" => %{"type" => "image", "id" => "1"}})

    assert_received {:handled, :on_image, %Event.Message{message: %Webhook.Message.Image{}}, _}
  end

  test "routes postback by data" do
    route(%{"type" => "postback", "postback" => %{"data" => "buy"}})
    assert_received {:handled, :buy, %Event.Postback{}, _assigns}
  end

  test "routes follow events" do
    route(%{"type" => "follow"})
    assert_received {:handled, :welcome, %Event.Follow{}, _assigns}
  end

  test "routes member-joined events" do
    route(%{"type" => "memberJoined", "joined" => %{"members" => []}})
    assert_received {:handled, :greet, %Event.MemberJoined{}, _assigns}
  end

  test "routes additional event types by name (unsend, beacon)" do
    route(%{"type" => "unsend", "unsend" => %{"messageId" => "m"}})
    assert_received {:handled, :unsent, %Event.Unsend{}, _}

    route(%{"type" => "beacon", "beacon" => %{"hwid" => "x"}})
    assert_received {:handled, :on_beacon, %Event.Beacon{}, _}
  end

  test "a still-unmodelled event type falls through to default as UnknownEvent" do
    route(%{"type" => "things", "things" => %{}})
    assert_received {:handled, :fallback, %Event.Unknown{type: "things"}, _assigns}
  end

  test "a text other than the matched literal falls through to default" do
    route(text_event("nope"))
    assert_received {:handled, :fallback, _event, _assigns}
  end
end
