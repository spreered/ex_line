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
    body = %{to: to, messages: List.wrap(messages)}

    client
    |> Client.request(method: :post, path: @push_path, body: body, retry_key: opts[:retry_key])
    |> handle_push()
  end

  # 200 = sent, 409 = deduplicated retry (X-Line-Retry-Key) — both are success.
  defp handle_push({:ok, %{status: status, body: body}}) when status in [200, 409],
    do: {:ok, body}

  defp handle_push({:ok, %{status: status, body: body}}),
    do: {:error, Error.from_status(status, body)}

  defp handle_push({:error, %Error{}} = error), do: error
end
