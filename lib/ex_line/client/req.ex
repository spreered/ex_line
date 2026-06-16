defmodule ExLine.Client.Req do
  @moduledoc """
  Default `ExLine.Client.Adapter` implementation backed by [Req](https://hex.pm/packages/req).
  """

  @behaviour ExLine.Client.Adapter

  alias ExLine.Error

  @impl true
  def request(%{method: method, url: url, headers: headers, body: body, query: query}) do
    opts =
      [method: method, url: url, headers: headers, params: query]
      |> maybe_put_json(body)

    case Req.request(opts) do
      {:ok, %Req.Response{status: status, body: rbody, headers: rheaders}} ->
        {:ok, %{status: status, body: rbody, headers: rheaders}}

      {:error, reason} ->
        {:error, Error.network(reason)}
    end
  end

  defp maybe_put_json(opts, nil), do: opts
  defp maybe_put_json(opts, body), do: Keyword.put(opts, :json, body)
end
