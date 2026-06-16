defmodule ExLine.Webhook.Signature do
  @moduledoc """
  Verifies the `x-line-signature` header on incoming webhook requests.

  LINE signs the **raw request body** with HMAC-SHA256 using the channel secret,
  Base64-encodes it, and sends it in the `x-line-signature` header. The comparison
  is constant-time.

  Make sure the raw body is preserved before your JSON parser consumes it (see
  `ExLine.Webhook.BodyReader`).

  Ref: https://developers.line.biz/en/docs/messaging-api/receiving-messages/#verifying-signatures
  """

  import Bitwise

  @doc """
  Returns `true` iff `signature` is a valid LINE signature for `body` under `secret`.

      iex> secret = "secret"
      iex> body = ~s({"events":[]})
      iex> sig = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode64()
      iex> ExLine.Webhook.Signature.valid?(body, sig, secret)
      true

      iex> ExLine.Webhook.Signature.valid?(~s({"events":[]}), "wrong", "secret")
      false
  """
  @spec valid?(binary(), binary(), binary()) :: boolean()
  def valid?(body, signature, secret)
      when is_binary(body) and is_binary(signature) and is_binary(secret) do
    expected = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode64()
    secure_compare(expected, signature)
  end

  def valid?(_body, _signature, _secret), do: false

  @doc """
  Computes the Base64-encoded HMAC-SHA256 signature for `body` under `secret`.
  """
  @spec sign(binary(), binary()) :: binary()
  def sign(body, secret), do: :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode64()

  # Constant-time comparison so we don't leak timing information about the secret.
  defp secure_compare(left, right) when byte_size(left) == byte_size(right) do
    secure_compare(left, right, 0) == 0
  end

  defp secure_compare(_left, _right), do: false

  defp secure_compare(<<x, left::binary>>, <<y, right::binary>>, acc),
    do: secure_compare(left, right, bor(acc, bxor(x, y)))

  defp secure_compare(<<>>, <<>>, acc), do: acc
end
