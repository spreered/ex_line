defmodule ExLine.Api.ChannelAccessToken do
  @moduledoc """
  Issue, verify, and revoke **channel access tokens** for the Messaging API.

  A channel access token is the Bearer credential every Messaging API call needs
  (`ExLine.Client.new(access_token: ...)`). You can either paste a long-lived token
  from the LINE Developers Console and skip this module entirely, or issue tokens
  programmatically here. There are three families:

    * **Long-lived (v1)** — `issue/3` / `verify/2` / `revoke/2`. Authenticated with
      the channel id + secret; one token at a time, ~30-day fixed lifetime.
    * **Stateless** — `issue_stateless/3` (channel secret) or
      `issue_stateless_with_jwt/2` (JWT assertion). Short-lived (~15 min), not
      counted/stored — issue one per burst of calls; no verify/revoke needed.
    * **JWT with custom expiry (v2.1)** — `issue_jwt/2` / `verify_jwt/2` /
      `revoke_jwt/4` / `key_ids/2`. Authenticated with a JWT assertion signed by a
      private key whose public key is registered in the Console; up to 30 active
      tokens, expiry up to 30 days.

  Every function takes a **transport-only** client (`ExLine.Client.transport/0`) —
  these endpoints authenticate via the request body, not a Bearer header, so an
  `access_token` is neither required nor sent.

  Build the JWT assertion with `ExLine.ChannelAccessToken.Assertion.sign/1`, and see
  the [Channel access token guide](channel_access_token.md) for key generation,
  Console registration, and caching with `ExLine.ChannelAccessToken.Cache`.

  Ref: https://developers.line.biz/en/docs/messaging-api/channel-access-tokens/
  """

  alias ExLine.{Client, Error}

  @grant_type "client_credentials"
  @assertion_type "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

  @typedoc "Decoded token response. `key_id` is present only for v2.1 tokens."
  @type token :: %{optional(String.t()) => term()}

  # ── Long-lived (v1) ───────────────────────────────────────────────────────

  @doc """
  Issues a long-lived channel access token (v1) from the channel id and secret.

  Returns `{:ok, %{"access_token" => token, "expires_in" => seconds, "token_type"
  => "Bearer"}}` or `{:error, ExLine.Error.t()}`. Issuing again invalidates the
  previous v1 token.

      iex> client = ExLine.Client.transport(adapter: MyAdapter)
      iex> ExLine.Api.ChannelAccessToken.issue(client, "1656...", "secret")
      {:ok, %{"access_token" => "...", "expires_in" => 2592000, "token_type" => "Bearer"}}

  Ref: https://developers.line.biz/en/reference/messaging-api/#issue-channel-access-token
  """
  @spec issue(Client.t(), String.t(), String.t()) :: {:ok, token()} | {:error, Error.t()}
  def issue(client, channel_id, channel_secret) do
    post_form(client, "/v2/oauth/accessToken",
      grant_type: @grant_type,
      client_id: channel_id,
      client_secret: channel_secret
    )
  end

  @doc """
  Verifies a long-lived (v1) channel access token.

  Returns `{:ok, %{"client_id" => ..., "expires_in" => seconds, "scope" => ...}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#verify-channel-access-token
  """
  @spec verify(Client.t(), String.t()) :: {:ok, token()} | {:error, Error.t()}
  def verify(client, access_token) do
    post_form(client, "/v2/oauth/verify", access_token: access_token)
  end

  @doc """
  Revokes a long-lived (v1) channel access token.

  Ref: https://developers.line.biz/en/reference/messaging-api/#revoke-channel-access-token
  """
  @spec revoke(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def revoke(client, access_token) do
    post_form(client, "/v2/oauth/revoke", access_token: access_token)
  end

  # ── Stateless ─────────────────────────────────────────────────────────────

  @doc """
  Issues a stateless channel access token using the channel id and secret.

  Stateless tokens are short-lived (~15 min) and are not stored or counted, so
  there is no verify/revoke — just issue one when you need it.

  Ref: https://developers.line.biz/en/reference/messaging-api/#issue-stateless-channel-access-token
  """
  @spec issue_stateless(Client.t(), String.t(), String.t()) ::
          {:ok, token()} | {:error, Error.t()}
  def issue_stateless(client, channel_id, channel_secret) do
    post_form(client, "/oauth2/v3/token",
      grant_type: @grant_type,
      client_id: channel_id,
      client_secret: channel_secret
    )
  end

  @doc """
  Issues a stateless channel access token using a signed JWT `assertion`.

  Build `assertion` with `ExLine.ChannelAccessToken.Assertion.sign/1`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#issue-stateless-channel-access-token
  """
  @spec issue_stateless_with_jwt(Client.t(), String.t()) :: {:ok, token()} | {:error, Error.t()}
  def issue_stateless_with_jwt(client, assertion) do
    post_form(client, "/oauth2/v3/token",
      grant_type: @grant_type,
      client_assertion_type: @assertion_type,
      client_assertion: assertion
    )
  end

  # ── JWT with custom expiry (v2.1) ─────────────────────────────────────────

  @doc """
  Issues a channel access token with a user-specified expiry (v2.1) from a signed
  JWT `assertion`.

  Returns `{:ok, %{"access_token" => ..., "expires_in" => ..., "token_type" =>
  "Bearer", "key_id" => ...}}`. Keep `key_id` to look the token up via `key_ids/2`.
  Build `assertion` with `ExLine.ChannelAccessToken.Assertion.sign/1` (include
  `:token_exp` for the desired lifetime).

  Ref: https://developers.line.biz/en/reference/messaging-api/#issue-channel-access-token-v2-1
  """
  @spec issue_jwt(Client.t(), String.t()) :: {:ok, token()} | {:error, Error.t()}
  def issue_jwt(client, assertion) do
    post_form(client, "/oauth2/v2.1/token",
      grant_type: @grant_type,
      client_assertion_type: @assertion_type,
      client_assertion: assertion
    )
  end

  @doc """
  Verifies a v2.1 channel access token.

  Ref: https://developers.line.biz/en/reference/messaging-api/#verify-channel-access-token-v2-1
  """
  @spec verify_jwt(Client.t(), String.t()) :: {:ok, token()} | {:error, Error.t()}
  def verify_jwt(client, access_token) do
    client
    |> Client.request(
      method: :get,
      path: "/oauth2/v2.1/verify",
      query: [access_token: access_token]
    )
    |> Client.decode()
  end

  @doc """
  Revokes a v2.1 channel access token (requires the channel id and secret).

  Ref: https://developers.line.biz/en/reference/messaging-api/#revoke-channel-access-token-v2-1
  """
  @spec revoke_jwt(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, term()} | {:error, Error.t()}
  def revoke_jwt(client, channel_id, channel_secret, access_token) do
    post_form(client, "/oauth2/v2.1/revoke",
      client_id: channel_id,
      client_secret: channel_secret,
      access_token: access_token
    )
  end

  @doc """
  Gets all valid v2.1 token key ids for the channel, authenticated with a signed
  JWT `assertion`.

  Returns `{:ok, %{"kids" => [...]}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-all-valid-channel-access-token-key-ids-v2-1
  """
  @spec key_ids(Client.t(), String.t()) :: {:ok, token()} | {:error, Error.t()}
  def key_ids(client, assertion) do
    client
    |> Client.request(
      method: :get,
      path: "/oauth2/v2.1/tokens/kid",
      query: [client_assertion_type: @assertion_type, client_assertion: assertion]
    )
    |> Client.decode()
  end

  defp post_form(client, path, form) do
    client
    |> Client.request(method: :post, path: path, form: form)
    |> Client.decode()
  end
end
