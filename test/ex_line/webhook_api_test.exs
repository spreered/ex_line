defmodule ExLine.WebhookApiTest do
  use ExUnit.Case, async: true

  import Mox

  alias ExLine.Api.Webhook
  alias ExLine.Client

  setup :verify_on_exit!

  defp client, do: Client.new(access_token: "tok", adapter: ExLine.AdapterMock)
  @api "https://api.line.me"

  test "get_endpoint" do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == :get
      assert req.url == "#{@api}/v2/bot/channel/webhook/endpoint"
      {:ok, %{status: 200, body: %{"endpoint" => "https://x", "active" => true}}}
    end)

    assert {:ok, %{"active" => true}} = Webhook.get_endpoint(client())
  end

  test "set_endpoint PUTs the url" do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == :put
      assert req.url == "#{@api}/v2/bot/channel/webhook/endpoint"
      assert req.body == %{endpoint: "https://x/webhook"}
      {:ok, %{status: 200, body: ""}}
    end)

    assert {:ok, _} = Webhook.set_endpoint(client(), "https://x/webhook")
  end

  test "test_endpoint posts to the test path" do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == :post
      assert req.url == "#{@api}/v2/bot/channel/webhook/test"
      assert req.body == %{endpoint: "https://x/webhook"}
      {:ok, %{status: 200, body: %{"success" => true}}}
    end)

    assert {:ok, %{"success" => true}} =
             Webhook.test_endpoint(client(), endpoint: "https://x/webhook")
  end
end
