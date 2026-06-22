defmodule ExLine.ChannelAccessToken.Cache do
  @moduledoc """
  A GenServer that caches a channel access token and refreshes it before it expires.

  ExLine is a library and owns no processes — **you** add this to your application's
  supervision tree, one child per channel you want to keep a warm token for:

      children = [
        {ExLine.ChannelAccessToken.Cache,
         name: :my_channel,
         issue: fn ->
           ExLine.Api.ChannelAccessToken.issue_stateless(
             ExLine.Client.transport(),
             System.fetch_env!("LINE_CHANNEL_ID"),
             System.fetch_env!("LINE_CHANNEL_SECRET")
           )
         end}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)

  Then build clients from the cached token wherever you send messages:

      {:ok, token} = ExLine.ChannelAccessToken.Cache.token(:my_channel)
      client = ExLine.Client.new(access_token: token)
      ExLine.Api.Messaging.push(client, user_id, ExLine.Message.text("hi"))

  The `:issue` function is any zero-arity function returning the same shape as the
  `ExLine.Api.ChannelAccessToken` issue functions
  (`{:ok, %{"access_token" => ..., "expires_in" => ...}}` | `{:error, _}`); for
  v2.1 tokens, have it sign an assertion with
  `ExLine.ChannelAccessToken.Assertion.sign/1` and call `issue_jwt/2`.

  ## Options

    * `:issue` (required) — zero-arity issue function (see above).
    * `:name` — process name to register under (e.g. an atom or `{:via, ...}` tuple).
    * `:refresh_before` — refresh this many seconds before `expires_in` (default 600).
    * `:retry_after` — seconds to wait before retrying a failed issue (default 30).
  """

  use GenServer

  require Logger

  @type t :: GenServer.server()

  @doc "Starts the cache. See the module doc for options."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc """
  Returns the currently cached token, or `{:error, :unavailable}` if the first issue
  has not yet succeeded.
  """
  @spec token(t()) :: {:ok, String.t()} | {:error, :unavailable}
  def token(server), do: GenServer.call(server, :token)

  @impl true
  def init(opts) do
    state = %{
      issue: Keyword.fetch!(opts, :issue),
      refresh_before: Keyword.get(opts, :refresh_before, 600),
      retry_after: Keyword.get(opts, :retry_after, 30),
      token: nil
    }

    {:ok, state, {:continue, :refresh}}
  end

  @impl true
  def handle_continue(:refresh, state), do: {:noreply, refresh(state)}

  @impl true
  def handle_call(:token, _from, %{token: nil} = state),
    do: {:reply, {:error, :unavailable}, state}

  def handle_call(:token, _from, %{token: token} = state),
    do: {:reply, {:ok, token}, state}

  @impl true
  def handle_info(:refresh, state), do: {:noreply, refresh(state)}

  # Issues a fresh token and schedules the next refresh. On failure the previous
  # token (if any) is kept and a shorter retry is scheduled.
  defp refresh(state) do
    case state.issue.() do
      {:ok, %{"access_token" => token, "expires_in" => expires_in}} ->
        schedule(max(expires_in - state.refresh_before, 1))
        %{state | token: token}

      other ->
        Logger.warning("[ExLine] channel access token refresh failed: #{inspect(other)}")
        schedule(state.retry_after)
        state
    end
  end

  defp schedule(seconds), do: Process.send_after(self(), :refresh, seconds * 1000)
end
