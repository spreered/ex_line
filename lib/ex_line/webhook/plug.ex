if Code.ensure_loaded?(Plug) do
  defmodule ExLine.Webhook.Plug do
    @moduledoc """
    Plug that verifies the LINE webhook signature and halts with `401` on failure.

    ## The `:secret` option

    This is your **Messaging API channel secret** — the value LINE uses to sign the
    `x-line-signature` header. Find it in the LINE Developers Console under your
    *Messaging API channel → Basic settings → Channel secret*. It is a different
    credential from the channel *access token* used to send messages, and is
    intentionally not part of `ExLine.Client` — it belongs to a separate trust
    boundary, so it is passed straight to this plug.

    Pass it one of two ways:

      * **A static binary** — the simplest case:

            plug ExLine.Webhook.Plug, secret: "your-channel-secret"

      * **A 1-arity function** `(conn -> secret)`, resolved at **request time**.
        Use this for either of:

          * **Lazy / dynamic loading.** Read the secret from runtime config or the
            environment when the request arrives instead of baking it in. This
            matters in a Phoenix router, where `plug` options are evaluated at
            **compile time** — a static `System.fetch_env!(...)` would be read while
            compiling, not at boot, so wrap it in a function:

                plug ExLine.Webhook.Plug,
                  secret: fn _conn -> Application.fetch_env!(:my_app, :line_channel_secret) end

          * **Multi-channel.** Pick the right secret per request, e.g. from a path
            param — the SDK never holds a channel registry:

                plug ExLine.Webhook.Plug,
                  secret: fn conn -> MyApp.Channels.secret!(conn.path_params["channel_id"]) end

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
