defmodule ExLine.ChannelAccessTokenTest do
  use ExUnit.Case, async: true

  import Mox
  import ExLine.Conformance

  alias ExLine.Api.ChannelAccessToken
  alias ExLine.Client

  setup :verify_on_exit!

  defp client, do: Client.transport(adapter: ExLine.AdapterMock)
  @api "https://api.line.me"
  @assertion_type "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

  describe "long-lived (v1)" do
    test "issue/3 posts client credentials as a form to /v2/oauth/accessToken" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "#{@api}/v2/oauth/accessToken"

        assert req.form == [
                 grant_type: "client_credentials",
                 client_id: "cid",
                 client_secret: "sec"
               ]

        assert {"content-type", "application/x-www-form-urlencoded"} in req.headers
        refute Enum.any?(req.headers, fn {k, _} -> k == "authorization" end)
        {:ok, %{status: 200, body: %{"access_token" => "tok", "expires_in" => 2_592_000}}}
      end)

      assert {:ok, %{"access_token" => "tok"}} = ChannelAccessToken.issue(client(), "cid", "sec")
    end

    test "verify/2 posts the token to /v2/oauth/verify" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/oauth/verify"
        assert req.form == [access_token: "tok"]
        {:ok, %{status: 200, body: %{"client_id" => "cid", "expires_in" => 100}}}
      end)

      assert {:ok, %{"client_id" => "cid"}} = ChannelAccessToken.verify(client(), "tok")
    end

    test "revoke/2 posts the token to /v2/oauth/revoke" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/oauth/revoke"
        assert req.form == [access_token: "tok"]
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = ChannelAccessToken.revoke(client(), "tok")
    end
  end

  describe "stateless" do
    test "issue_stateless/3 posts client credentials to /oauth2/v3/token" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/oauth2/v3/token"

        assert req.form == [
                 grant_type: "client_credentials",
                 client_id: "cid",
                 client_secret: "sec"
               ]

        {:ok, %{status: 200, body: %{"access_token" => "s-tok", "expires_in" => 900}}}
      end)

      assert {:ok, %{"access_token" => "s-tok"}} =
               ChannelAccessToken.issue_stateless(client(), "cid", "sec")
    end

    test "issue_stateless_with_jwt/2 posts the assertion to /oauth2/v3/token" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/oauth2/v3/token"

        assert req.form == [
                 grant_type: "client_credentials",
                 client_assertion_type: @assertion_type,
                 client_assertion: "JWT"
               ]

        {:ok, %{status: 200, body: %{"access_token" => "s-tok", "expires_in" => 900}}}
      end)

      assert {:ok, _} = ChannelAccessToken.issue_stateless_with_jwt(client(), "JWT")
    end
  end

  describe "v2.1 (JWT)" do
    test "issue_jwt/2 posts the assertion to /oauth2/v2.1/token" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "#{@api}/oauth2/v2.1/token"

        assert req.form == [
                 grant_type: "client_credentials",
                 client_assertion_type: @assertion_type,
                 client_assertion: "JWT"
               ]

        {:ok, %{status: 200, body: %{"access_token" => "v-tok", "key_id" => "kid1"}}}
      end)

      assert {:ok, %{"key_id" => "kid1"}} = ChannelAccessToken.issue_jwt(client(), "JWT")
    end

    test "verify_jwt/2 GETs /oauth2/v2.1/verify with the token in the query" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :get
        assert req.url == "#{@api}/oauth2/v2.1/verify"
        assert {:access_token, "v-tok"} in req.query
        {:ok, %{status: 200, body: %{"client_id" => "cid"}}}
      end)

      assert {:ok, %{"client_id" => "cid"}} = ChannelAccessToken.verify_jwt(client(), "v-tok")
    end

    test "revoke_jwt/4 posts id/secret/token to /oauth2/v2.1/revoke" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/oauth2/v2.1/revoke"
        assert req.form == [client_id: "cid", client_secret: "sec", access_token: "v-tok"]
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = ChannelAccessToken.revoke_jwt(client(), "cid", "sec", "v-tok")
    end

    test "key_ids/2 GETs /oauth2/v2.1/tokens/kid with the assertion" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :get
        assert req.url == "#{@api}/oauth2/v2.1/tokens/kid"
        assert {:client_assertion_type, @assertion_type} in req.query
        assert {:client_assertion, "JWT"} in req.query
        {:ok, %{status: 200, body: %{"kids" => ["kid1", "kid2"]}}}
      end)

      assert {:ok, %{"kids" => ["kid1", "kid2"]}} = ChannelAccessToken.key_ids(client(), "JWT")
    end
  end

  test "a non-2xx token response is classified as an error" do
    expect(ExLine.AdapterMock, :request, fn _req ->
      {:ok, %{status: 400, body: %{"error" => "invalid_request"}}}
    end)

    assert {:error, %ExLine.Error{status: 400}} =
             ChannelAccessToken.issue_stateless(client(), "cid", "bad")
  end

  # The form bodies we send must match LINE's official request schemas.
  describe "conformance" do
    @describetag :conformance

    test "client-secret stateless request → IssueStatelessChannelTokenByClientSecretRequest" do
      body = %{grant_type: "client_credentials", client_id: "cid", client_secret: "sec"}
      assert_conforms(body, "IssueStatelessChannelTokenByClientSecretRequest")
    end

    test "JWT-assertion stateless request → IssueStatelessChannelTokenByJWTAssertionRequest" do
      body = %{
        grant_type: "client_credentials",
        client_assertion_type: @assertion_type,
        client_assertion: "JWT"
      }

      assert_conforms(body, "IssueStatelessChannelTokenByJWTAssertionRequest")
    end
  end
end
