defmodule ExLine.Client do
  @moduledoc """
  Holds the Messaging API credentials and HTTP configuration as a plain value.

  A client is **constructed and passed per call** — the SDK never owns a global
  registry, so multi-channel / multi-tenant apps simply build the right client
  for each request:

      client = ExLine.Client.new(access_token: provider.message_channel_access_token)
      ExLine.Api.Messaging.push(client, user_id, message)

  For the single-channel case, `from_env/1` reads a default from application config.

  Note: the webhook channel **secret** is intentionally *not* held here — it
  belongs to a different trust boundary and is passed directly to
  `ExLine.Webhook.Signature.valid?/3`.
  """

  alias ExLine.Error

  @enforce_keys [:access_token]
  defstruct access_token: nil,
            channel_id: nil,
            adapter: ExLine.Client.Req,
            base_url: "https://api.line.me",
            data_url: "https://api-data.line.me",
            retry: []

  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          channel_id: String.t() | nil,
          adapter: module(),
          base_url: String.t(),
          data_url: String.t(),
          retry: keyword()
        }

  @doc """
  Builds a client from a keyword list or map.

      iex> client = ExLine.Client.new(access_token: "tok")
      iex> client.access_token
      "tok"
      iex> client.base_url
      "https://api.line.me"
  """
  @spec new(keyword() | map()) :: t()
  def new(opts), do: struct!(__MODULE__, opts)

  @doc """
  Builds a client from application config (single-channel convenience).

      config :ex_line, access_token: "...", channel_id: "..."
  """
  @spec from_env(atom()) :: t()
  def from_env(app \\ :ex_line) do
    new(
      access_token: Application.fetch_env!(app, :access_token),
      channel_id: Application.get_env(app, :channel_id)
    )
  end

  @doc """
  Builds a **transport-only** client with no access token.

  The channel-access-token endpoints (`ExLine.Api.ChannelAccessToken`) authenticate
  with the channel id/secret or a signed JWT assertion — not a Bearer token — so
  they need the adapter/host configuration but not an `access_token`. Use this to
  obtain a token before you can build a normal client:

      iex> client = ExLine.Client.transport()
      iex> client.access_token
      nil
      iex> client.base_url
      "https://api.line.me"
  """
  @spec transport(keyword() | map()) :: t()
  def transport(opts \\ []) do
    struct!(__MODULE__, Enum.into(opts, %{access_token: nil}))
  end

  @doc """
  Performs a request against the LINE API.

  Options:

    * `:method` — HTTP method (default `:get`)
    * `:path` — request path appended to the host (required)
    * `:body` — request body, JSON-encoded by the adapter
    * `:raw_body` — request body sent as-is (e.g. image bytes); requires `:content_type`
    * `:content_type` — content type for a `:raw_body` upload
    * `:form` — request body sent as `application/x-www-form-urlencoded` (used by the
      OAuth/token endpoints)
    * `:query` — query params (keyword)
    * `:host` — `:api` (default, `base_url`) or `:data` (`data_url`, for content)
    * `:retry_key` — sets the `X-Line-Retry-Key` header for idempotent retries

  Returns the raw `{:ok, response}` / `{:error, ExLine.Error.t()}` from the
  adapter; use `decode/1` (or an endpoint-specific handler) to map it to a result.
  """
  @spec request(t(), keyword()) :: {:ok, ExLine.Client.Adapter.response()} | {:error, Error.t()}
  def request(%__MODULE__{} = client, opts) do
    host = if opts[:host] == :data, do: client.data_url, else: client.base_url
    path = Keyword.fetch!(opts, :path)

    req = %{
      method: Keyword.get(opts, :method, :get),
      url: host <> path,
      headers: headers(client, opts),
      body: Keyword.get(opts, :body),
      raw_body: Keyword.get(opts, :raw_body),
      form: Keyword.get(opts, :form),
      query: Keyword.get(opts, :query, [])
    }

    case client.adapter.request(req) do
      {:ok, response} -> {:ok, response}
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, Error.network(reason)}
    end
  end

  @doc """
  Default response handling: 2xx → `{:ok, body}`, otherwise a classified `ExLine.Error`.
  """
  @spec decode({:ok, ExLine.Client.Adapter.response()} | {:error, Error.t()}) ::
          {:ok, term()} | {:error, Error.t()}
  def decode({:ok, %{status: status, body: body}}) when status in 200..299, do: {:ok, body}
  def decode({:ok, %{status: status, body: body}}), do: {:error, Error.from_status(status, body)}
  def decode({:error, %Error{}} = error), do: error

  defp headers(client, opts) do
    base = auth_header(client)
    base = content_type_header(base, opts)

    case opts[:retry_key] do
      nil -> base
      key -> [{"x-line-retry-key", key} | base]
    end
  end

  # Token endpoints use a transport-only client (no access_token) — they
  # authenticate via the request body, so no Authorization header is sent.
  defp auth_header(%{access_token: nil}), do: []
  defp auth_header(%{access_token: token}), do: [{"authorization", "Bearer " <> token}]

  defp content_type_header(base, opts) do
    cond do
      opts[:raw_body] -> [{"content-type", Keyword.fetch!(opts, :content_type)} | base]
      opts[:form] -> [{"content-type", "application/x-www-form-urlencoded"} | base]
      opts[:body] -> [{"content-type", "application/json"} | base]
      true -> base
    end
  end
end
