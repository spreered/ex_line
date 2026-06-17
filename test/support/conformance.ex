defmodule ExLine.Conformance do
  @moduledoc """
  Test helper that validates builder/request output against LINE's official
  OpenAPI spec (vendored under `test/support/line_openapi/`).

  This is the "our format == LINE's expected format" gate. The spec is the source
  of truth: when LINE updates it, re-vendor the YAML and these assertions
  automatically validate against the new schema — no regeneration needed.

  Validation uses `open_api_spex`, which understands OpenAPI 3.0 natively
  (`$ref` / `allOf` / `discriminator` / `nullable`), so no JSON-Schema
  preprocessing is required.

      assert_conforms(ExLine.Message.text("hi"), "TextMessage")
  """

  import ExUnit.Assertions

  @spec_path Path.join([__DIR__, "line_openapi", "messaging-api.yml"])
  # Pinned line-openapi commit: 779d8ca9e632 (2026-04-13). Re-vendor to update.
  @pt_key {__MODULE__, :spec}

  @doc """
  Asserts that `value` (a builder output or request body, atom- or string-keyed)
  conforms to the named schema in the vendored Messaging API spec.

  The value is round-tripped through JSON first, which also verifies it is
  JSON-serializable the way it will be sent on the wire.
  """
  def assert_conforms(value, schema_name) do
    spec = spec()

    schema =
      spec.components.schemas[schema_name] ||
        raise ArgumentError,
              "unknown schema #{inspect(schema_name)} in vendored messaging-api.yml"

    json = value |> Jason.encode!() |> Jason.decode!()

    case OpenApiSpex.cast_value(json, schema, spec) do
      {:ok, _cast} ->
        :ok

      {:error, errors} ->
        flunk("""
        #{schema_name} conformance failed:
        #{format_errors(errors)}
        value sent: #{inspect(json, pretty: true)}
        """)
    end
  end

  @doc "Decoded OpenApi spec struct (parsed once, cached across tests)."
  def spec do
    case :persistent_term.get(@pt_key, nil) do
      nil ->
        spec =
          @spec_path
          |> YamlElixir.read_from_file!()
          |> OpenApiSpex.OpenApi.Decode.decode()
          |> strip_discriminators()

        :persistent_term.put(@pt_key, spec)
        spec

      spec ->
        spec
    end
  end

  # LINE's polymorphism uses "parent schema with `discriminator` + children via
  # `allOf: [$ref parent, {...}]`", whereas open_api_spex's discriminator cast
  # expects the `oneOf`+discriminator pattern and crashes on LINE's shape. We
  # always validate against a *concrete* schema name (TextMessage, etc.), so
  # discriminator dispatch is unnecessary — strip it. Concrete-type tests keep
  # full strictness; request bodies that reference the abstract parent then
  # validate against its base properties (per-type strictness comes from the
  # dedicated message-object tests).
  defp strip_discriminators(%OpenApiSpex.OpenApi{components: components} = spec) do
    schemas =
      Map.new(components.schemas, fn {name, schema} ->
        {name, %{schema | discriminator: nil}}
      end)

    %{spec | components: %{components | schemas: schemas}}
  end

  defp format_errors(errors) do
    Enum.map_join(errors, "\n", fn error ->
      "  - " <>
        OpenApiSpex.error_message(error) <> " (at " <> OpenApiSpex.path_to_string(error) <> ")"
    end)
  end
end
