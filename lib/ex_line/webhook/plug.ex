if Code.ensure_loaded?(Plug) do
  defmodule ExLine.Webhook.Plug do
    @moduledoc """
    Plug that verifies the LINE webhook signature and halts with `401` on failure.

    The channel secret is supplied via the `:secret` option, which is the key to
    multi-channel support: pass either a static binary, or a 1-arity function that
    resolves the secret from the `conn` at request time (e.g. by the product in the
    path). The SDK never holds a channel registry.

        # static secret
        plug ExLine.Webhook.Plug, secret: System.fetch_env!("LINE_CHANNEL_SECRET")

        # resolver — pick the secret per request
        plug ExLine.Webhook.Plug, secret: &MyApp.line_secret/1

    Requires the raw body to be cached by `ExLine.Webhook.BodyReader`.

    Ref: https://developers.line.biz/en/docs/messaging-api/receiving-messages/#verifying-signatures
    """

    import Plug.Conn

    @behaviour Plug

    @impl true
    def init(opts), do: opts

    @impl true
    def call(conn, opts) do
      signature = conn |> get_req_header("x-line-signature") |> List.first()
      raw_body = raw_body(conn)
      secret = resolve_secret(opts[:secret], conn)

      if is_binary(secret) and is_binary(signature) and is_binary(raw_body) and
           ExLine.Webhook.Signature.valid?(raw_body, signature, secret) do
        conn
      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"invalid signature"}))
        |> halt()
      end
    end

    defp resolve_secret(fun, conn) when is_function(fun, 1), do: fun.(conn)
    defp resolve_secret(secret, _conn) when is_binary(secret), do: secret
    defp resolve_secret(_secret, _conn), do: nil

    # BodyReader prepends each chunk, so the cached value is a list of binaries.
    defp raw_body(%{assigns: %{raw_body: [_ | _] = chunks}}), do: IO.iodata_to_binary(chunks)
    defp raw_body(%{assigns: %{raw_body: body}}) when is_binary(body), do: body
    defp raw_body(_conn), do: nil
  end
end
