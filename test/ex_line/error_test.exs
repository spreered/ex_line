defmodule ExLine.ErrorTest do
  use ExUnit.Case, async: true

  doctest ExLine.Error

  alias ExLine.Error

  test "from_status classifies statuses" do
    assert Error.from_status(429, %{}).kind == :quota_exceeded
    assert Error.from_status(500, %{}).kind == :transient
    assert Error.from_status(503, %{}).kind == :transient
    assert Error.from_status(401, %{}).kind == :permanent
    assert Error.from_status(404, %{}).kind == :permanent
  end

  test "network/1 builds a network error" do
    err = Error.network(:timeout)
    assert err.kind == :network
    assert err.reason == :timeout
  end

  test "retryable? is true only for transient and network" do
    assert Error.retryable?(%Error{kind: :transient})
    assert Error.retryable?(%Error{kind: :network})
    refute Error.retryable?(%Error{kind: :permanent})
    refute Error.retryable?(%Error{kind: :quota_exceeded})
  end

  test "is an exception with a message" do
    assert Exception.message(%Error{kind: :permanent, status: 400}) =~ "400"
  end
end
