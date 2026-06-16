defmodule ExLine.Webhook.SignatureTest do
  use ExUnit.Case, async: true

  doctest ExLine.Webhook.Signature

  alias ExLine.Webhook.Signature

  @secret "channel-secret"
  @body ~s({"destination":"U","events":[]})

  test "accepts a valid signature" do
    sig = Signature.sign(@body, @secret)
    assert Signature.valid?(@body, sig, @secret)
  end

  test "rejects a tampered body" do
    sig = Signature.sign(@body, @secret)
    refute Signature.valid?(@body <> " ", sig, @secret)
  end

  test "rejects a wrong secret" do
    sig = Signature.sign(@body, @secret)
    refute Signature.valid?(@body, sig, "other-secret")
  end

  test "rejects non-binary inputs" do
    refute Signature.valid?(nil, "sig", @secret)
    refute Signature.valid?(@body, nil, @secret)
    refute Signature.valid?(@body, "sig", nil)
  end

  test "rejects a signature of different length without raising" do
    refute Signature.valid?(@body, "short", @secret)
  end
end
