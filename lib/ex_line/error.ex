defmodule ExLine.Error do
  @moduledoc """
  Normalized error returned by `ExLine` API calls.

  `kind` classifies the failure so callers can decide whether to retry:

    * `:transient` — server-side or timeout statuses (408/500/502/503/504); safe to retry.
    * `:quota_exceeded` — HTTP 429, the monthly push quota / rate limit was hit.
    * `:permanent` — any other non-2xx status (4xx); retrying will not help.
    * `:network` — the request never got a response (connection error, timeout at the
      transport layer); safe to retry.

  Ref: https://developers.line.biz/en/reference/messaging-api/#error-responses
  """

  defexception [:kind, :status, :reason, :body]

  @type kind :: :transient | :quota_exceeded | :permanent | :network

  @type t :: %__MODULE__{
          kind: kind(),
          status: pos_integer() | nil,
          reason: term(),
          body: term()
        }

  @transient_statuses [408, 500, 502, 503, 504]

  @impl true
  def message(%__MODULE__{kind: kind, status: nil, reason: reason}),
    do: "LINE API error (#{kind}): #{inspect(reason)}"

  def message(%__MODULE__{kind: kind, status: status}),
    do: "LINE API error (#{kind}), HTTP status #{status}"

  @doc """
  Builds an error for a transport-level failure (no HTTP response received).
  """
  @spec network(term()) :: t()
  def network(reason), do: %__MODULE__{kind: :network, reason: reason}

  @doc """
  Classifies a non-2xx HTTP status into an `ExLine.Error`.

      iex> ExLine.Error.from_status(429, %{}).kind
      :quota_exceeded

      iex> ExLine.Error.from_status(503, %{}).kind
      :transient

      iex> ExLine.Error.from_status(400, %{}).kind
      :permanent
  """
  @spec from_status(pos_integer(), term()) :: t()
  def from_status(429, body), do: %__MODULE__{kind: :quota_exceeded, status: 429, body: body}

  def from_status(status, body) when status in @transient_statuses,
    do: %__MODULE__{kind: :transient, status: status, body: body}

  def from_status(status, body), do: %__MODULE__{kind: :permanent, status: status, body: body}

  @doc """
  Whether the error is worth retrying (`:transient` or `:network`).

      iex> ExLine.Error.retryable?(%ExLine.Error{kind: :transient})
      true

      iex> ExLine.Error.retryable?(%ExLine.Error{kind: :permanent})
      false
  """
  @spec retryable?(t()) :: boolean()
  def retryable?(%__MODULE__{kind: kind}), do: kind in [:transient, :network]
end
