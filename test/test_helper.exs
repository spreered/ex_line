# External tests (hit the real LINE API) are excluded by default; run them with
# `mix test --include external` and credentials supplied via the environment.
ExUnit.start(exclude: [:external])

# Mock adapter for asserting outbound requests without touching the network.
Mox.defmock(ExLine.AdapterMock, for: ExLine.Client.Adapter)
