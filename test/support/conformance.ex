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

  # Pinned line-openapi commit: 779d8ca9e632 (2026-04-13). Re-vendor to update.
  # Both specs are self-contained, so we keep them separate and pick by schema name
  # (messaging-api = outgoing builders/requests; webhook = incoming events).
  @spec_files %{
    messaging: "messaging-api.yml",
    webhook: "webhook.yml"
  }

  @doc """
  Asserts that `value` (a builder output, request body, or webhook payload; atom- or
  string-keyed) conforms to the named schema in the vendored specs.

  The value is round-tripped through JSON first, which also verifies it is
  JSON-serializable the way it travels on the wire.
  """
  def assert_conforms(value, schema_name) do
    {spec, schema} = find_schema(schema_name)
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

  defp find_schema(schema_name) do
    Enum.find_value(Map.keys(@spec_files), fn key ->
      spec = spec(key)

      case spec.components.schemas[schema_name] do
        nil -> nil
        schema -> {spec, schema}
      end
    end) ||
      raise ArgumentError, "unknown schema #{inspect(schema_name)} in vendored specs"
  end

  @doc "Decoded OpenApi spec struct for `which` (`:messaging` | `:webhook`), cached."
  def spec(which \\ :messaging) do
    key = {__MODULE__, which}

    case :persistent_term.get(key, nil) do
      nil ->
        spec =
          [__DIR__, "line_openapi", Map.fetch!(@spec_files, which)]
          |> Path.join()
          |> YamlElixir.read_from_file!()
          |> OpenApiSpex.OpenApi.Decode.decode()
          |> strip_discriminators()

        :persistent_term.put(key, spec)
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
