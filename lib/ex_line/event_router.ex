defmodule ExLine.EventRouter do
  @moduledoc """
  A DSL for routing **parsed** LINE webhook events (`ExLine.Webhook` structs) to
  handlers.

  Routes are declared with macros and matched against the event struct plus an
  `event_assigns` map you control. Parse the raw payload with `ExLine.Webhook.parse/1`
  first, then route each event.

  ## Example

      defmodule MyApp.LineRouter do
        use ExLine.EventRouter

        text "hello", MyApp.HelpHandler, :hello         # text equal to "hello"
        message :image, MyApp.MediaHandler, :on_image   # any image message
        postback "buy", MyApp.ShopHandler, :buy
        follow MyApp.OnboardHandler, :welcome
        unfollow MyApp.OnboardHandler, :goodbye
        default MyApp.FallbackHandler, :unknown         # REQUIRED: also catches UnknownEvent

        @impl true
        def before_action(event, assigns), do: {event, Map.put(assigns, :client, MyApp.client())}
      end

      event |> ExLine.Webhook.parse() ... # or parse the whole body
      MyApp.LineRouter.call(parsed_event, %{})

  Because LINE adds event types without notice (and unknown types become
  `ExLine.Webhook.UnknownEvent`), always declare a `default/2` route so unmatched
  events never raise.

  Ref: https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects
  """

  @message_modules %{
    text: ExLine.Webhook.Message.Text,
    image: ExLine.Webhook.Message.Image,
    video: ExLine.Webhook.Message.Video,
    audio: ExLine.Webhook.Message.Audio,
    file: ExLine.Webhook.Message.File,
    location: ExLine.Webhook.Message.Location,
    sticker: ExLine.Webhook.Message.Sticker
  }

  @doc "Invoked before an event is matched; preprocess the event and assigns here."
  @callback before_action(event :: struct(), event_assigns :: map()) ::
              {event :: struct(), event_assigns :: map()}

  @doc "Invoked just before the handler is called; lets you tweak the dispatch."
  @callback before_handler_call(
              handler :: atom(),
              action :: atom(),
              event :: struct(),
              event_assigns :: map()
            ) :: {atom(), atom(), struct(), map()}

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
    pattern =
      quote do
        %ExLine.Webhook.MessageEvent{message: %ExLine.Webhook.Message.Text{text: unquote(text)}}
      end

    generate_match_event(pattern, assign_match, handler, action)
  end

  @doc """
  Routes any message event of the given content `kind`
  (`:text` | `:image` | `:video` | `:audio` | `:file` | `:location` | `:sticker`).
  """
  defmacro message(kind, assign_match \\ quote(do: %{}), handler, action) do
    module = Map.fetch!(@message_modules, kind)
    pattern = quote do: %ExLine.Webhook.MessageEvent{message: %unquote(module){}}
    generate_match_event(pattern, assign_match, handler, action)
  end

  @doc "Routes a postback event whose `data` equals `data`."
  defmacro postback(data, assign_match \\ quote(do: %{}), handler, action) do
    pattern = quote do: %ExLine.Webhook.PostbackEvent{postback: %{data: unquote(data)}}
    generate_match_event(pattern, assign_match, handler, action)
  end

  @doc "Routes a follow event."
  defmacro follow(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(quote(do: %ExLine.Webhook.FollowEvent{}), assign_match, handler, action)
  end

  @doc "Routes an unfollow event."
  defmacro unfollow(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.UnfollowEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a join event."
  defmacro join(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(quote(do: %ExLine.Webhook.JoinEvent{}), assign_match, handler, action)
  end

  @doc "Routes a leave event."
  defmacro leave(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(quote(do: %ExLine.Webhook.LeaveEvent{}), assign_match, handler, action)
  end

  @doc "Routes a member-joined event."
  defmacro member_joined(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.MemberJoinedEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a member-left event."
  defmacro member_left(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.MemberLeftEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes an unsend event."
  defmacro unsend(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(quote(do: %ExLine.Webhook.UnsendEvent{}), assign_match, handler, action)
  end

  @doc "Routes a video-play-complete event."
  defmacro video_play_complete(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.VideoPlayCompleteEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a beacon event."
  defmacro beacon(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(quote(do: %ExLine.Webhook.BeaconEvent{}), assign_match, handler, action)
  end

  @doc "Routes an account-link event."
  defmacro account_link(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.AccountLinkEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a membership event."
  defmacro membership(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.MembershipEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a module-channel activated event."
  defmacro activated(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.ActivatedEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a module-channel deactivated event."
  defmacro deactivated(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.DeactivatedEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a bot-suspended event."
  defmacro bot_suspended(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.BotSuspendedEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a bot-resumed event."
  defmacro bot_resumed(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.BotResumedEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Routes a module-channel event."
  defmacro module(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(quote(do: %ExLine.Webhook.ModuleEvent{}), assign_match, handler, action)
  end

  @doc "Routes a PNP (LINE notification message) delivery-completion event."
  defmacro pnp_delivery_completion(assign_match \\ quote(do: %{}), handler, action) do
    generate_match_event(
      quote(do: %ExLine.Webhook.PnpDeliveryCompletionEvent{}),
      assign_match,
      handler,
      action
    )
  end

  @doc "Catch-all route for any unmatched event (also catches `UnknownEvent`)."
  defmacro default(handler, action) do
    generate_match_event(quote(do: _), quote(do: _), handler, action)
  end
end
