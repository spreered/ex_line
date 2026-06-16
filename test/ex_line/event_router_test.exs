defmodule ExLine.EventRouterTest do
  use ExUnit.Case, async: true

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
    postback("buy", EchoHandler, :buy)
    follow(EchoHandler, :welcome)
    default(EchoHandler, :fallback)

    @impl true
    def before_action(event, assigns) do
      {event, Map.put(assigns, :seen, true)}
    end
  end

  defp text_event(text), do: %{"message" => %{"type" => "text", "text" => text}}

  test "routes a text message to its handler/action" do
    Router.call(text_event("hello"))
    assert_received {:handled, :hello, _event, %{seen: true}}
  end

  test "assigns pattern selects a more specific route" do
    Router.call(text_event("hello"), %{role: :admin})
    assert_received {:handled, :admin_hello, _event, _assigns}
  end

  test "routes postback by data" do
    Router.call(%{"type" => "postback", "postback" => %{"data" => "buy"}})
    assert_received {:handled, :buy, _event, _assigns}
  end

  test "routes follow events" do
    Router.call(%{"type" => "follow"})
    assert_received {:handled, :welcome, _event, _assigns}
  end

  test "falls back for unmatched events" do
    Router.call(%{"type" => "unsend"})
    assert_received {:handled, :fallback, _event, _assigns}
  end

  test "before_action preprocesses assigns" do
    Router.call(text_event("hello"), %{})
    assert_received {:handled, :hello, _event, %{seen: true}}
  end
end
