defmodule ExLine.Messaging do
  @moduledoc """
  LINE Messaging API send endpoints.

  Every function takes an `ExLine.Client` as its first argument. Messages may be a
  single message map or a list (max 5 per request).

  Ref: https://developers.line.biz/en/reference/messaging-api/#messages
  """

  alias ExLine.{Client, Error}

  @reply_path "/v2/bot/message/reply"
  @push_path "/v2/bot/message/push"
  @multicast_path "/v2/bot/message/multicast"

  @type messages :: map() | [map()]

  @doc """
  Sends reply messages using the `replyToken` from a webhook event.

  Returns `{:ok, body}` on success, or `{:error, ExLine.Error.t()}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#send-reply-message
  """
  @spec reply(Client.t(), String.t(), messages(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def reply(client, reply_token, messages, _opts \\ []) do
    body = %{replyToken: reply_token, messages: List.wrap(messages)}

    client
    |> Client.request(method: :post, path: @reply_path, body: body)
    |> Client.decode()
  end

  @doc """
  Sends push messages to a user, group, or room.

  `opts[:retry_key]` (a UUID) is sent as the `X-Line-Retry-Key` header so LINE
  deduplicates retried requests; a deduplicated retry returns HTTP 409, which is
  treated here as success (`{:ok, body}`). HTTP 429 maps to a
  `%ExLine.Error{kind: :quota_exceeded}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#send-push-message
  """
  @spec push(Client.t(), String.t(), messages(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def push(client, to, messages, opts \\ []) do
    body =
      %{to: to, messages: List.wrap(messages)}
      |> maybe_disable_notification(opts)

    client
    |> Client.request(method: :post, path: @push_path, body: body, retry_key: opts[:retry_key])
    |> handle_send()
  end

  @doc """
  Sends the same messages to multiple users at once (max 500 user IDs).

  `to` is a list of user IDs; group/room IDs are not allowed. Like `push/4`,
  `opts[:retry_key]` enables idempotent retries (409 is treated as success) and
  HTTP 429 maps to `%ExLine.Error{kind: :quota_exceeded}`. `opts[:notification_disabled]`
  suppresses the push notification.

  Ref: https://developers.line.biz/en/reference/messaging-api/#send-multicast-message
  """
  @spec multicast(Client.t(), [String.t()], messages(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def multicast(client, to, messages, opts \\ []) when is_list(to) do
    body =
      %{to: to, messages: List.wrap(messages)}
      |> maybe_disable_notification(opts)

    client
    |> Client.request(
      method: :post,
      path: @multicast_path,
      body: body,
      retry_key: opts[:retry_key]
    )
    |> handle_send()
  end

  @doc """
  Displays a loading animation in a one-on-one chat for up to `seconds` (5–60, in
  multiples of 5).

  Ref: https://developers.line.biz/en/reference/messaging-api/#display-a-loading-indicator
  """
  @spec display_loading_animation(Client.t(), String.t(), pos_integer()) ::
          {:ok, map()} | {:error, Error.t()}
  def display_loading_animation(client, chat_id, seconds \\ 20) do
    body = %{chatId: chat_id, loadingSeconds: seconds}

    client
    |> Client.request(method: :post, path: "/v2/bot/chat/loading/start", body: body)
    |> Client.decode()
  end

  @doc """
  Gets this month's message-sending quota (`%{"type" => "limited"|"none", "value" => n}`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-quota
  """
  @spec quota(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def quota(client) do
    client
    |> Client.request(method: :get, path: "/v2/bot/message/quota")
    |> Client.decode()
  end

  @doc """
  Gets this month's number of sent messages counted toward the quota.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-consumption
  """
  @spec quota_consumption(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def quota_consumption(client) do
    client
    |> Client.request(method: :get, path: "/v2/bot/message/quota/consumption")
    |> Client.decode()
  end

  @doc """
  Gets the number of messages sent on `date` (`"yyyyMMdd"`) for the given `kind`
  (`:reply` | `:push` | `:multicast` | `:broadcast`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-number-of-reply-messages
  """
  @spec sent_count(Client.t(), :reply | :push | :multicast | :broadcast, String.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def sent_count(client, kind, date) when kind in [:reply, :push, :multicast, :broadcast] do
    client
    |> Client.request(
      method: :get,
      path: "/v2/bot/message/delivery/#{kind}",
      query: [date: date]
    )
    |> Client.decode()
  end

  defp maybe_disable_notification(body, opts) do
    case Keyword.get(opts, :notification_disabled) do
      nil -> body
      value -> Map.put(body, :notificationDisabled, value)
    end
  end

  # 200 = sent, 409 = deduplicated retry (X-Line-Retry-Key) — both are success.
  defp handle_send({:ok, %{status: status, body: body}}) when status in [200, 409],
    do: {:ok, body}

  defp handle_send({:ok, %{status: status, body: body}}),
    do: {:error, Error.from_status(status, body)}

  defp handle_send({:error, %Error{}} = error), do: error
end
