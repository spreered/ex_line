defmodule ExLine.M4ApiTest do
  use ExUnit.Case, async: true

  import Mox
  import ExLine.Conformance

  alias ExLine.Api.{AccountLink, Coupon, Insight, Membership, Messaging}
  alias ExLine.Client

  setup :verify_on_exit!

  defp client, do: Client.new(access_token: "tok", adapter: ExLine.AdapterMock)
  @api "https://api.line.me"

  defp expect_get(url, response \\ %{}) do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == :get
      assert req.url == url
      {:ok, %{status: 200, body: response}}
    end)
  end

  describe "AccountLink" do
    test "issue_link_token/2 POSTs the user link-token path" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "#{@api}/v2/bot/user/U1/linkToken"
        {:ok, %{status: 200, body: %{"linkToken" => "lt"}}}
      end)

      assert {:ok, %{"linkToken" => "lt"}} = AccountLink.issue_link_token(client(), "U1")
    end
  end

  describe "Membership" do
    test "list/1, subscription/2, joined_users/3 hit the right paths" do
      expect_get("#{@api}/v2/bot/membership/list", %{"memberships" => []})
      assert {:ok, _} = Membership.list(client())

      expect_get("#{@api}/v2/bot/membership/subscription/U1")
      assert {:ok, _} = Membership.subscription(client(), "U1")

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/membership/42/users/ids"
        assert {:start, "tok2"} in req.query
        assert {:limit, 100} in req.query
        {:ok, %{status: 200, body: %{"memberUserIds" => []}}}
      end)

      assert {:ok, _} = Membership.joined_users(client(), 42, start: "tok2", limit: 100)
    end
  end

  describe "Insight" do
    test "aggregation unit usage/names" do
      expect_get("#{@api}/v2/bot/message/aggregation/info", %{"numOfCustomAggregationUnits" => 3})

      assert {:ok, %{"numOfCustomAggregationUnits" => 3}} =
               Insight.aggregation_unit_usage(client())

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/message/aggregation/list"
        assert {:limit, 50} in req.query
        {:ok, %{status: 200, body: %{"customAggregationUnits" => []}}}
      end)

      assert {:ok, _} = Insight.aggregation_unit_names(client(), limit: 50)
    end
  end

  describe "Messaging.sent_count/3 :pnp" do
    test "hits the delivery/pnp path with the date" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/message/delivery/pnp"
        assert {:date, "20260101"} in req.query
        {:ok, %{status: 200, body: %{"status" => "ready", "success" => 5}}}
      end)

      assert {:ok, %{"success" => 5}} = Messaging.sent_count(client(), :pnp, "20260101")
    end
  end

  describe "Coupon" do
    test "create/2 POSTs the coupon body" do
      coupon = %{title: "t", visibility: "PUBLIC"}

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "#{@api}/v2/bot/coupon"
        assert req.body == coupon
        {:ok, %{status: 200, body: %{"couponId" => "c1"}}}
      end)

      assert {:ok, %{"couponId" => "c1"}} = Coupon.create(client(), coupon)
    end

    test "list/2 passes status/start/limit as query" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :get
        assert req.url == "#{@api}/v2/bot/coupon"
        assert {:status, ["RUNNING"]} in req.query
        assert {:limit, 10} in req.query
        {:ok, %{status: 200, body: %{"items" => []}}}
      end)

      assert {:ok, _} = Coupon.list(client(), status: ["RUNNING"], limit: 10)
    end

    test "get/2 and close/2 hit per-coupon paths" do
      expect_get("#{@api}/v2/bot/coupon/c1")
      assert {:ok, _} = Coupon.get(client(), "c1")

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :put
        assert req.url == "#{@api}/v2/bot/coupon/c1/close"
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = Coupon.close(client(), "c1")
    end
  end

  describe "conformance" do
    @describetag :conformance

    test "coupon create body → CouponCreateRequest" do
      body = %{
        title: "10% off",
        visibility: "PUBLIC",
        timezone: "ASIA_TAIPEI",
        startTimestamp: 1_700_000_000_000,
        endTimestamp: 1_800_000_000_000,
        maxUseCountPerTicket: 1,
        acquisitionCondition: %{type: "normal"},
        reward: %{type: "discount"}
      }

      assert_conforms(body, "CouponCreateRequest")
    end
  end
end
