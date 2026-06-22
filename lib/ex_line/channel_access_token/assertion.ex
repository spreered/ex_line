defmodule ExLine.ChannelAccessToken.Assertion do
  @moduledoc """
  Builds and signs the JWT assertion used by the JWT-based channel-access-token
  endpoints (`ExLine.Api.ChannelAccessToken.issue_jwt/2`,
  `issue_stateless_with_jwt/2`, `key_ids/2`).

  You register the **public** key in the LINE Developers Console (channel's
  *Basic settings → Assertion Signing Key → Register a public key*), which returns
  a `kid`. You keep the matching **private** key and use it here to sign assertions.
  See the [Channel access token guide](channel_access_token.md) for key generation.

  The assertion is an `RS256` JWT with this shape:

      header  = %{"alg" => "RS256", "typ" => "JWT", "kid" => kid}
      payload = %{
        "iss" => channel_id,
        "sub" => channel_id,
        "aud" => "https://api.line.me/",
        "exp" => <now + assertion_ttl>,      # assertion's own short expiry
        "token_exp" => <desired token lifetime in seconds>  # v2.1 only
      }

  Ref: https://developers.line.biz/en/docs/messaging-api/generate-json-web-token/
  """

  @aud "https://api.line.me/"

  @doc """
  Signs a JWT assertion and returns the compact (`header.payload.signature`) string.

  Options:

    * `:channel_id` (required) — the Messaging API channel id; used as `iss` and `sub`.
    * `:kid` (required) — the key id returned by the Console when you registered the
      public key.
    * `:private_key` (required) — the signing key as a PEM string, a JWK map, or a
      `JOSE.JWK` struct.
    * `:token_exp` (optional) — desired lifetime of the **issued token** in seconds
      (v2.1 only; max 30 days = 2_592_000). Omit for the stateless endpoint.
    * `:assertion_ttl` (optional) — lifetime of the **assertion itself** in seconds
      (default 30, max 30 min).
    * `:now` (optional) — base Unix time in seconds (defaults to the current time);
      mainly for testing.

  Network-free, but not a doctest because the output depends on the current time
  and a private key.

      iex> pem = File.read!("priv/keys/line_assertion.pem")
      iex> assertion =
      ...>   ExLine.ChannelAccessToken.Assertion.sign(
      ...>     channel_id: "1656...",
      ...>     kid: "sDTOzw5w...",
      ...>     private_key: pem,
      ...>     token_exp: 2_592_000
      ...>   )
      iex> ExLine.Api.ChannelAccessToken.issue_jwt(ExLine.Client.transport(), assertion)
  """
  @spec sign(keyword()) :: String.t()
  def sign(opts) do
    channel_id = Keyword.fetch!(opts, :channel_id)
    kid = Keyword.fetch!(opts, :kid)
    jwk = to_jwk(Keyword.fetch!(opts, :private_key))
    now = Keyword.get_lazy(opts, :now, fn -> System.system_time(:second) end)
    assertion_ttl = Keyword.get(opts, :assertion_ttl, 30)

    claims =
      %{
        "iss" => channel_id,
        "sub" => channel_id,
        "aud" => @aud,
        "exp" => now + assertion_ttl
      }
      |> maybe_put_token_exp(opts[:token_exp])

    header = %{"alg" => "RS256", "typ" => "JWT", "kid" => kid}

    {_meta, token} = JOSE.JWS.compact(JOSE.JWT.sign(jwk, header, claims))
    IO.iodata_to_binary(token)
  end

  defp maybe_put_token_exp(claims, nil), do: claims
  defp maybe_put_token_exp(claims, token_exp), do: Map.put(claims, "token_exp", token_exp)

  defp to_jwk(%JOSE.JWK{} = jwk), do: jwk
  defp to_jwk(pem) when is_binary(pem), do: JOSE.JWK.from_pem(pem)
  defp to_jwk(map) when is_map(map), do: JOSE.JWK.from_map(map)
end
