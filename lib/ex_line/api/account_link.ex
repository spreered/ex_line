defmodule ExLine.Api.AccountLink do
  @moduledoc """
  Links a LINE user to an account in your own service (account linking).

  Ref: https://developers.line.biz/en/docs/messaging-api/linking-accounts/
  """

  alias ExLine.{Client, Error}

  @doc """
  Issues a one-time link token for `user_id`, used to start the account-linking flow.

  Returns `{:ok, %{"linkToken" => token}}` or `{:error, ExLine.Error.t()}`. The token
  is valid for ~10 minutes and one-time use.

      iex> client = ExLine.Client.new(access_token: "tok", adapter: MyAdapter)
      iex> ExLine.Api.AccountLink.issue_link_token(client, "U123")
      {:ok, %{"linkToken" => "..."}}

  Ref: https://developers.line.biz/en/reference/messaging-api/#issue-link-token
  """
  @spec issue_link_token(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def issue_link_token(client, user_id) do
    client
    |> Client.request(method: :post, path: "/v2/bot/user/#{user_id}/linkToken")
    |> Client.decode()
  end
end
