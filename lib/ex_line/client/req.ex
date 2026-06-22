defmodule ExLine.Client.Req do
  @moduledoc """
  Default `ExLine.Client.Adapter` implementation backed by [Req](https://hex.pm/packages/req).
  """

  @behaviour ExLine.Client.Adapter

  alias ExLine.Error

  @impl true
  def request(%{method: method, url: url, headers: headers, query: query} = req) do
    opts =
      [method: method, url: url, headers: headers, params: query]
      |> put_body(req)

    case Req.request(opts) do
      {:ok, %Req.Response{status: status, body: rbody, headers: rheaders}} ->
        {:ok, %{status: status, body: rbody, headers: rheaders}}

      {:error, reason} ->
        {:error, Error.network(reason)}
    end
  end

  # raw_body (e.g. image bytes) is sent as-is; form is URL-encoded
  # (application/x-www-form-urlencoded); otherwise body is JSON-encoded.
  defp put_body(opts, %{raw_body: raw}) when not is_nil(raw), do: Keyword.put(opts, :body, raw)
  defp put_body(opts, %{form: form}) when not is_nil(form), do: Keyword.put(opts, :form, form)
  defp put_body(opts, %{body: body}) when not is_nil(body), do: Keyword.put(opts, :json, body)
  defp put_body(opts, _req), do: opts
end
