defmodule ExLine.EventRouter do
  @moduledoc """
  A DSL for routing LINE Messaging API webhook events to handlers.

  Routes are declared with macros and matched against the raw event map plus an
  `event_assigns` map you control (e.g. for the resolved channel/user). An optional
  `before_action/2` callback preprocesses each event before matching.

  ## Example

      defmodule MyApp.LineRouter do
        use ExLine.EventRouter

        # match text with an assigns pattern
        text "hello", %{current_user: %{role: "admin"}}, MyApp.AdminHandler, :hello
        # match text with default assigns
        text "help", MyApp.HelpHandler, :show_help
        # postback
        postback "buy", MyApp.ShopHandler, :buy
        # follow event
        follow MyApp.OnboardHandler, :welcome
        # catch-all
        default MyApp.FallbackHandler, :unknown

        @impl true
        def before_action(event, assigns) do
          {event, Map.put(assigns, :current_user, fetch_user(event))}
        end
      end

      MyApp.LineRouter.call(event, %{client: client})

  Ref: https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects
  """

  @doc "Invoked before an event is matched; preprocess the event and assigns here."
  @callback before_action(event :: map(), event_assigns :: map()) ::
              {event :: map(), event_assigns :: map()}

  @doc "Invoked just before the handler is called; lets you tweak the dispatch."
  @callback before_handler_call(
              handler :: atom(),
              action :: atom(),
              event :: map(),
              event_assigns :: map()
            ) :: {atom(), atom(), map(), map()}

  @optional_callbacks [before_action: 2]

  defmacro __using__(_opts) do
    quote do
      import ExLine.EventRouter
      @behaviour ExLine.EventRouter

      def call(event, event_assigns \\ %{}) do
        {event, event_assigns} = before_action(event, event_assigns)

        case match_event(event, event_assigns) do
          {handler, action} ->
            {handler, action, event, event_assigns} =
              before_handler_call(handler, action, event, event_assigns)

            apply(handler, :call, [action, event, event_assigns])
        end
      end

      def before_action(event, event_assigns), do: {event, event_assigns}

      def before_handler_call(handler, action, event, event_assigns),
        do: {handler, action, event, event_assigns}

      defoverridable before_action: 2
      defoverridable before_handler_call: 4
    end
  end

  defp generate_match_event(pattern, assign_match, handler, action) do
    quote location: :keep, generated: true do
      def match_event(unquote(pattern) = event, unquote(assign_match) = event_assigns) do
        {unquote(handler), unquote(action)}
      end
    end
  end

  @doc "Routes a text message event whose text equals `text`."
  defmacro text(text, assign_match \\ quote(do: %{}), handler, action) do
    pattern = quote do: %{"message" => %{"type" => "text", "text" => unquote(text)}}
    generate_match_event(pattern, assign_match, handler, action)
  end

  @doc "Routes a postback event whose `data` equals `data`."
  defmacro postback(data, assign_match \\ quote(do: %{}), handler, action) do
    pattern = quote do: %{"type" => "postback", "postback" => %{"data" => unquote(data)}}
    generate_match_event(pattern, assign_match, handler, action)
  end

  @doc "Routes a follow event."
  defmacro follow(assign_match \\ quote(do: %{}), handler, action) do
    pattern = quote do: %{"type" => "follow"}
    generate_match_event(pattern, assign_match, handler, action)
  end

  @doc "Catch-all route for any unmatched event."
  defmacro default(handler, action) do
    generate_match_event(quote(do: _), quote(do: _), handler, action)
  end
end
