defmodule ExLine.Webhook.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias ExLine.Webhook.Signature

  @secret "channel-secret"
  @body ~s({"events":[]})

  defp conn_with(body, signature, raw_body) do
    :post
    |> conn("/webhook", body)
    |> put_req_header("x-line-signature", signature)
    |> then(fn conn ->
      if raw_body, do: assign(conn, :raw_body, [raw_body]), else: conn
    end)
  end

  test "passes a request with a valid signature (static secret)" do
    sig = Signature.sign(@body, @secret)
    conn = conn_with(@body, sig, @body)

    result = ExLine.Webhook.Plug.call(conn, ExLine.Webhook.Plug.init(secret: @secret))

    refute result.halted
  end

  test "halts with 401 on an invalid signature" do
    conn = conn_with(@body, "bad-signature", @body)

    result = ExLine.Webhook.Plug.call(conn, ExLine.Webhook.Plug.init(secret: @secret))

    assert result.halted
    assert result.status == 401
  end

  test "resolves the secret via a function of conn" do
    sig = Signature.sign(@body, @secret)
    conn = conn_with(@body, sig, @body)

    result =
      ExLine.Webhook.Plug.call(conn, ExLine.Webhook.Plug.init(secret: fn _conn -> @secret end))

    refute result.halted
  end

  test "halts when the raw body was not cached" do
    sig = Signature.sign(@body, @secret)
    conn = conn_with(@body, sig, nil)

    result = ExLine.Webhook.Plug.call(conn, ExLine.Webhook.Plug.init(secret: @secret))

    assert result.halted
    assert result.status == 401
  end
end
