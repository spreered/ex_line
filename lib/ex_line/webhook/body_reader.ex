if Code.ensure_loaded?(Plug) do
  defmodule ExLine.Webhook.BodyReader do
    @moduledoc """
    A custom `Plug.Parsers` body reader that caches the raw request body in
    `conn.assigns[:raw_body]`, so `ExLine.Webhook.Plug` can verify the LINE
    signature after the JSON parser has consumed the stream.

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
