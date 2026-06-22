defmodule ExLine.Api.Coupon do
  @moduledoc """
  Coupon management API (create / list / detail / close).

  This is the management API for coupon *campaigns* — distinct from the coupon
  **message** type (`ExLine.Message.coupon/2`), which sends an already-created
  coupon to a user.

  The coupon object passed to `create/2` is a map matching LINE's
  `CouponCreateRequest`; build it per the reference (required: `title`,
  `visibility`, `timezone`, `startTimestamp`, `endTimestamp`,
  `maxUseCountPerTicket`, `acquisitionCondition`, `reward`):

      %{
        title: "10% off",
        visibility: "PUBLIC",
        timezone: "ASIA_TAIPEI",
        startTimestamp: 1_700_000_000_000,
        endTimestamp: 1_800_000_000_000,
        maxUseCountPerTicket: 1,
        acquisitionCondition: %{type: "normal"},
        reward: %{type: "discount", priceInfo: %{discountType: "percent", percentage: 10}}
      }

  Ref: https://developers.line.biz/en/docs/messaging-api/create-coupons/
  """

  alias ExLine.{Client, Error}

  @path "/v2/bot/coupon"

  @doc """
  Creates a coupon. `coupon` is a map matching `CouponCreateRequest` (see the
  module doc). Returns `{:ok, %{"couponId" => ...}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#create-coupon
  """
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, coupon) do
    client
    |> Client.request(method: :post, path: @path, body: coupon)
    |> Client.decode()
  end

  @doc """
  Gets a paginated list of coupons.

  `opts[:status]` filters by status (a list, e.g. `["RUNNING", "CLOSED"]`);
  `opts[:start]` is the continuation token; `opts[:limit]` caps the page size.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-coupon-list
  """
  @spec list(Client.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def list(client, opts \\ []) do
    query =
      []
      |> maybe(:status, opts[:status])
      |> maybe(:start, opts[:start])
      |> maybe(:limit, opts[:limit])

    client
    |> Client.request(method: :get, path: @path, query: query)
    |> Client.decode()
  end

  @doc """
  Gets the detail of a single coupon.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-coupon-detail
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, coupon_id) do
    client
    |> Client.request(method: :get, path: "#{@path}/#{coupon_id}")
    |> Client.decode()
  end

  @doc """
  Closes a coupon (stops it being acquired). Returns `{:ok, _}` on success.

  Ref: https://developers.line.biz/en/reference/messaging-api/#close-coupon
  """
  @spec close(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def close(client, coupon_id) do
    client
    |> Client.request(method: :put, path: "#{@path}/#{coupon_id}/close")
    |> Client.decode()
  end

  defp maybe(query, _key, nil), do: query
  defp maybe(query, key, value), do: [{key, value} | query]
end
