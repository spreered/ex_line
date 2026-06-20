defmodule ExLine.Client.Adapter do
  @moduledoc """
  Behaviour for the HTTP transport used by `ExLine.Client`.

  The default implementation is `ExLine.Client.Req`. Swapping the adapter is the
  supported way to mock LINE API calls in tests — assert on the `request/1`
  argument instead of hitting the network.

  ## Example (Mox)

      Mox.defmock(MyApp.LineAdapterMock, for: ExLine.Client.Adapter)
      client = ExLine.Client.new(access_token: "tok", adapter: MyApp.LineAdapterMock)
  """

  @typedoc "Normalized request handed to the adapter."
  @type request :: %{
          method: atom(),
          url: String.t(),
          headers: [{String.t(), String.t()}],
          body: term() | nil,
          raw_body: binary() | nil,
          query: keyword()
        }

  @typedoc "Normalized response the adapter must return on a completed HTTP round-trip."
  @type response :: %{status: pos_integer(), body: term(), headers: term()}

  @doc """
  Performs the HTTP request.

  Returns `{:ok, response}` whenever an HTTP response was received (any status),
  or `{:error, ExLine.Error.t()}` for transport-level failures.
  """
  @callback request(request()) :: {:ok, response()} | {:error, ExLine.Error.t()}
end
