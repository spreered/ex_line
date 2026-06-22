defmodule ExLine.Api.Webhook do
  @moduledoc """
  Manage the channel's webhook endpoint setting (get / set / test).

  This is the **settings API** — distinct from `ExLine.Webhook`, which parses incoming
  webhook events.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-webhook-endpoint-information
  """

  alias ExLine.{Client, Error}

  @path "/v2/bot/channel/webhook/endpoint"

  @doc "Gets the webhook endpoint info (`%{\"endpoint\" => url, \"active\" => bool}`)."
  @spec get_endpoint(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_endpoint(client) do
    client |> Client.request(method: :get, path: @path) |> Client.decode()
  end

  @doc "Sets the webhook endpoint URL."
  @spec set_endpoint(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def set_endpoint(client, url) do
    client |> Client.request(method: :put, path: @path, body: %{endpoint: url}) |> Client.decode()
  end

  @doc """
  Tests the webhook endpoint (the configured one, or `opts[:endpoint]` if given).

  Ref: https://developers.line.biz/en/reference/messaging-api/#test-webhook-endpoint
  """
  @spec test_endpoint(Client.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def test_endpoint(client, opts \\ []) do
    body = if opts[:endpoint], do: %{endpoint: opts[:endpoint]}, else: %{}

    client
    |> Client.request(method: :post, path: "/v2/bot/channel/webhook/test", body: body)
    |> Client.decode()
  end
end
