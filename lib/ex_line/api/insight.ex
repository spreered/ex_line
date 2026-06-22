defmodule ExLine.Api.Insight do
  @moduledoc """
  Aggregation-unit usage for the Messaging API.

  Aggregation units group messages (via a `customAggregationUnits` name on a
  send request) so their delivery can be counted separately. The broader
  statistics API (message events, demographics, followers) lives in LINE's
  separate `insight.yml` spec and is not modelled here yet.

  Ref: https://developers.line.biz/en/docs/messaging-api/unit-based-statistics-aggregation/
  """

  alias ExLine.{Client, Error}

  @doc """
  Gets the number of aggregation units used this month.

  Returns `{:ok, %{"numOfCustomAggregationUnits" => n}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-the-number-of-unit-name-types-assigned-during-this-month
  """
  @spec aggregation_unit_usage(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def aggregation_unit_usage(client) do
    client
    |> Client.request(method: :get, path: "/v2/bot/message/aggregation/info")
    |> Client.decode()
  end

  @doc """
  Gets the names of the aggregation units used this month.

  `opts[:limit]` caps the page size; `opts[:start]` is the continuation token from a
  previous page. Returns `{:ok, %{"customAggregationUnits" => [...], "next" => ...}}`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#get-the-unit-names-assigned-during-this-month
  """
  @spec aggregation_unit_names(Client.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def aggregation_unit_names(client, opts \\ []) do
    query =
      []
      |> maybe(:limit, opts[:limit])
      |> maybe(:start, opts[:start])

    client
    |> Client.request(method: :get, path: "/v2/bot/message/aggregation/list", query: query)
    |> Client.decode()
  end

  defp maybe(query, _key, nil), do: query
  defp maybe(query, key, value), do: [{key, value} | query]
end
