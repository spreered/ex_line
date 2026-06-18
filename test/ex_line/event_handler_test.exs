defmodule ExLine.EventHandlerTest do
  use ExUnit.Case, async: true

  defmodule Handler do
    use ExLine.EventHandler

    @impl true
    # Uses text/1 directly — compiles only because `use` auto-imports ExLine.Message.
    def handle_event(:echo, event, assigns), do: {:ok, text("hi"), event, assigns}
  end

  test "call/3 delegates to handle_event/3" do
    assert Handler.call(:echo, %{"id" => 1}, %{a: 1}) ==
             {:ok, %{type: "text", text: "hi"}, %{"id" => 1}, %{a: 1}}
  end

  test "use ExLine.EventHandler auto-imports ExLine.Message builders" do
    # If the import didn't happen, the handler above (text/1) would not compile.
    assert {:ok, %{type: "text", text: "hi"}, _event, _assigns} =
             Handler.call(:echo, %{}, %{})
  end
end
