defmodule ExLine.Api.Messaging do
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
  @broadcast_path "/v2/bot/message/broadcast"
  @narrowcast_path "/v2/bot/message/narrowcast"
  @narrowcast_progress_path "/v2/bot/message/progress/narrowcast"

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
  Sends messages to **all** friends of the official account.

  Like `push/4`, `opts[:retry_key]` enables idempotent retries and
  `opts[:notification_disabled]` suppresses the push notification.

  Ref: https://developers.line.biz/en/reference/messaging-api/#send-broadcast-message
  """
  @spec broadcast(Client.t(), messages(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def broadcast(client, messages, opts \\ []) do
    body =
      %{messages: List.wrap(messages)}
      |> maybe_disable_notification(opts)

    client
    |> Client.request(
      method: :post,
      path: @broadcast_path,
      body: body,
      retry_key: opts[:retry_key]
    )
    |> handle_send()
  end

  @doc """
  Sends messages to a filtered segment of friends (by audience/demographic).

  Targeting is passed via `opts`: `:recipient` (audience/operator object), `:filter`
  (demographic object), `:limit` (`%{max: n}`). Also `:retry_key`,
  `:notification_disabled`.

  Narrowcast is asynchronous: on success this returns `{:ok, request_id}` (from the
  `X-Line-Request-Id` header); poll `narrowcast_progress/2` with it.

  Ref: https://developers.line.biz/en/reference/messaging-api/#send-narrowcast-message
  """
  @spec narrowcast(Client.t(), messages(), keyword()) ::
          {:ok, String.t() | nil} | {:error, Error.t()}
  def narrowcast(client, messages, opts \\ []) do
    body =
      %{messages: List.wrap(messages)}
      |> maybe_put(:recipient, opts[:recipient])
      |> maybe_put(:filter, opts[:filter])
      |> maybe_put(:limit, opts[:limit])
      |> maybe_disable_notification(opts)

    client
    |> Client.request(
      method: :post,
      path: @narrowcast_path,
      body: body,
      retry_key: opts[:retry_key]
    )
    |> handle_narrowcast()
  end

  @doc """
  Gets the delivery status of a narrowcast request (`phase`: `waiting` / `sending` /
  `succeeded` / `failed`, plus counts).

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-narrowcast-progress-status
  """
  @spec narrowcast_progress(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def narrowcast_progress(client, request_id) do
    client
    |> Client.request(
      method: :get,
      path: @narrowcast_progress_path,
      query: [requestId: request_id]
    )
    |> Client.decode()
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

  defp maybe_put(body, _key, nil), do: body
  defp maybe_put(body, key, value), do: Map.put(body, key, value)

  # 200 = sent, 409 = deduplicated retry (X-Line-Retry-Key) — both are success.
  defp handle_send({:ok, %{status: status, body: body}}) when status in [200, 409],
    do: {:ok, body}

  defp handle_send({:ok, %{status: status, body: body}}),
    do: {:error, Error.from_status(status, body)}

  defp handle_send({:error, %Error{}} = error), do: error

  # Narrowcast succeeds with 202 (or 409 for a deduplicated retry); the request id
  # for progress polling comes back in the X-Line-Request-Id response header.
  defp handle_narrowcast({:ok, %{status: status, headers: headers}}) when status in [202, 409],
    do: {:ok, request_id(headers)}

  defp handle_narrowcast({:ok, %{status: status, body: body}}),
    do: {:error, Error.from_status(status, body)}

  defp handle_narrowcast({:error, %Error{}} = error), do: error

  defp request_id(headers) when is_map(headers) do
    case headers["x-line-request-id"] do
      [value | _] -> value
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  defp request_id(headers) when is_list(headers) do
    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(to_string(k)) == "x-line-request-id", do: v
    end)
  end

  defp request_id(_headers), do: nil
end
