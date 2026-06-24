if Code.ensure_loaded?(Plug) do
  defmodule ExLine.Webhook.BodyReader do
    @moduledoc """
    A custom `Plug.Parsers` body reader that caches the raw request body in
    `conn.assigns[:raw_body]`, so `ExLine.Webhook.Plug` can verify the LINE
    signature after the JSON parser has consumed the stream.

    ## Why you need this

    LINE signs the **exact bytes** of the request body, and verifying the signature
    means re-hashing those same bytes. You cannot use the parsed payload instead,
    because JSON parsing is a one-way door: once `Plug.Parsers` turns the body into a
    map, encoding that map back to JSON can reorder keys and change whitespace, so it
    is no longer byte-for-byte identical to what LINE sent — and the signature won't
    match.

    On top of that, `Plug.Parsers` *consumes* the body stream as it parses, so by the
    time your controller runs the original bytes are gone. This reader sits inside the
    parser: it reads the body, stashes an untouched copy in `conn.assigns[:raw_body]`,
    and hands the same bytes on to the parser. JSON parsing still works as usual, and
    the original bytes survive for signature verification.

    Wire it into your endpoint's `Plug.Parsers`:

        plug Plug.Parsers,
          parsers: [:json],
          body_reader: {ExLine.Webhook.BodyReader, :read_body, []},
          json_decoder: Jason

    Ref: https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader
    """

    @spec read_body(Plug.Conn.t(), keyword()) :: {:ok, binary(), Plug.Conn.t()}
    def read_body(conn, opts) do
      {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
      conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
      {:ok, body, conn}
    end
  end
end
