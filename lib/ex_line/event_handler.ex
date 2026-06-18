defmodule ExLine.EventHandler do
  @moduledoc """
  Behaviour + convenience macro for implementing LINE event handlers dispatched by
  `ExLine.EventRouter`.

  `use ExLine.EventHandler` imports `ExLine.Message` (so builders like `text/1` are
  available), enforces the `handle_event/3` callback, and defines the `call/3`
  wrapper the router calls.

  Message sending takes a client, so call `ExLine.Api.Messaging` explicitly with the
  client you placed in `event_assigns`:

      defmodule MyApp.HelpHandler do
        use ExLine.EventHandler

        @impl true
        def handle_event(:show_help, %{"replyToken" => token}, %{client: client}) do
          ExLine.Api.Messaging.reply(client, token, text("Need help?"))
          :ok
        end
      end
  """

  @callback handle_event(action :: atom(), event :: map(), event_assigns :: map()) ::
              :ok | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      import ExLine.Message
      @behaviour ExLine.EventHandler

      def call(action, event, event_assigns) do
        handle_event(action, event, event_assigns)
      end
    end
  end
end
