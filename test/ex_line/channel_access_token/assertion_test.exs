defmodule ExLine.ChannelAccessToken.AssertionTest do
  use ExUnit.Case, async: true

  alias ExLine.ChannelAccessToken.Assertion

  # One RSA key pair for the whole module (generation is the slow part).
  setup_all do
    private = JOSE.JWK.generate_key({:rsa, 2048})
    public = JOSE.JWK.to_public(private)
    {_, pem} = JOSE.JWK.to_pem(private)
    %{private: private, public: public, pem: pem}
  end

  defp claims(public, token) do
    {true, %JOSE.JWT{fields: fields}, _jws} = JOSE.JWT.verify(public, token)
    fields
  end

  test "signs a verifiable RS256 JWT with the expected header and claims", %{
    private: private,
    public: public
  } do
    token =
      Assertion.sign(
        channel_id: "1656",
        kid: "kid-1",
        private_key: private,
        now: 1_000_000
      )

    # header
    %{"alg" => alg, "typ" => typ, "kid" => kid} =
      token |> JOSE.JWS.peek_protected() |> Jason.decode!()

    assert alg == "RS256"
    assert typ == "JWT"
    assert kid == "kid-1"

    # claims
    fields = claims(public, token)
    assert fields["iss"] == "1656"
    assert fields["sub"] == "1656"
    assert fields["aud"] == "https://api.line.me/"
    assert fields["exp"] == 1_000_030
    refute Map.has_key?(fields, "token_exp")
  end

  test "includes token_exp when given (v2.1)", %{private: private, public: public} do
    token =
      Assertion.sign(
        channel_id: "1656",
        kid: "kid-1",
        private_key: private,
        token_exp: 2_592_000
      )

    assert claims(public, token)["token_exp"] == 2_592_000
  end

  test "accepts a PEM private key", %{pem: pem, public: public} do
    token = Assertion.sign(channel_id: "1656", kid: "kid-1", private_key: pem)
    assert claims(public, token)["iss"] == "1656"
  end

  test "honours :assertion_ttl", %{private: private, public: public} do
    token =
      Assertion.sign(
        channel_id: "1656",
        kid: "kid-1",
        private_key: private,
        now: 0,
        assertion_ttl: 120
      )

    assert claims(public, token)["exp"] == 120
  end
end
