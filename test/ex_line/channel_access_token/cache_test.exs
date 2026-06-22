defmodule ExLine.ChannelAccessToken.CacheTest do
  use ExUnit.Case, async: true

  alias ExLine.ChannelAccessToken.Cache

  test "serves the issued token after the eager first fetch" do
    issue = fn -> {:ok, %{"access_token" => "tok-1", "expires_in" => 3600}} end
    pid = start_supervised!({Cache, issue: issue})

    assert {:ok, "tok-1"} = Cache.token(pid)
  end

  test "registers under :name" do
    issue = fn -> {:ok, %{"access_token" => "tok-named", "expires_in" => 3600}} end
    start_supervised!({Cache, name: :cache_test_named, issue: issue})

    assert {:ok, "tok-named"} = Cache.token(:cache_test_named)
  end

  test "reports :unavailable and keeps running when the first issue fails" do
    issue = fn -> {:error, :boom} end
    pid = start_supervised!({Cache, issue: issue, retry_after: 60})

    assert {:error, :unavailable} = Cache.token(pid)
    assert Process.alive?(pid)
  end

  test "refreshes when the schedule fires" do
    test_pid = self()

    issue = fn ->
      send(test_pid, :issued)
      {:ok, %{"access_token" => "tok", "expires_in" => 1, "refresh_before" => 0}}
    end

    # refresh_before > expires_in clamps the next refresh to 1s.
    pid = start_supervised!({Cache, issue: issue, refresh_before: 600})

    assert_receive :issued
    # the scheduled refresh fires again ~1s later
    assert_receive :issued, 1500
    assert {:ok, "tok"} = Cache.token(pid)
  end
end
