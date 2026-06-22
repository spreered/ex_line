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
    webhook: "webhook.yml",
    channel_access_token: "channel-access-token.yml"
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

  # ── Field-completeness check (incoming, factory-based) ─────────────────────
  #
  # Whereas assert_conforms/2 checks "our output matches the spec", this checks
  # "we extract every field the spec defines": generate a maximal instance from
  # the schema (every property populated), parse it, and assert each spec property
  # lands in a non-nil struct field. A missing field = we must model it.
  #
  # Principle: model whatever the spec defines. (An allowlist of intentional
  # omissions is a possible future extension — not implemented; see M1.6.)

  @doc """
  Asserts that parsing a maximal instance of `schema_name` (built by `factory/1`,
  with its discriminator `type` set) populates a non-nil struct field for every spec
  property. The discriminator `"type"` itself is represented by the struct's identity
  and is excluded from the field check.
  """
  def assert_fields_covered(schema_name, type, parse_fun) do
    parsed =
      schema_name
      |> factory()
      |> Map.put("type", type)
      |> parse_fun.()

    missing =
      schema_name
      |> spec_property_names()
      |> Enum.reject(&(&1 == "type"))
      |> Enum.reject(&(Map.get(parsed, underscore_atom(&1)) != nil))

    assert missing == [],
           """
           #{schema_name} → #{inspect(parsed.__struct__)}: spec fields not captured by the parser:
             #{Enum.join(missing, ", ")}
           Model each (struct field + parse clause). parsed:
           #{inspect(parsed, pretty: true)}
           """
  end

  @doc """
  Builds a maximal JSON instance (camelCase keys, every property populated) for the
  named schema, resolving `$ref`/`allOf` and recursing into nested objects/arrays.
  """
  def factory(schema_name) do
    {schema, spec} = schema_and_spec(schema_name)
    factory_value(schema, spec.components.schemas, MapSet.new())
  end

  defp schema_and_spec(schema_name) do
    {spec, schema} = find_schema(schema_name)
    {schema, spec}
  end

  defp spec_property_names(schema_name) do
    {schema, spec} = schema_and_spec(schema_name)
    schema |> collect_props(spec.components.schemas) |> Enum.uniq()
  end

  defp collect_props(%OpenApiSpex.Schema{allOf: members}, schemas) when is_list(members),
    do: Enum.flat_map(members, &collect_props(&1, schemas))

  defp collect_props(%OpenApiSpex.Schema{properties: props}, _schemas) when is_map(props),
    do: Enum.map(Map.keys(props), &to_string/1)

  defp collect_props(%OpenApiSpex.Reference{"$ref": ref}, schemas),
    do: collect_props(schemas[ref_name(ref)], schemas)

  defp collect_props(_schema, _schemas), do: []

  defp factory_value(%OpenApiSpex.Reference{"$ref": ref}, schemas, seen) do
    name = ref_name(ref)

    if MapSet.member?(seen, name),
      do: %{},
      else: factory_value(schemas[name], schemas, MapSet.put(seen, name))
  end

  defp factory_value(%OpenApiSpex.Schema{allOf: members}, schemas, seen) when is_list(members) do
    Enum.reduce(members, %{}, &Map.merge(&2, factory_value(&1, schemas, seen)))
  end

  defp factory_value(%OpenApiSpex.Schema{enum: [first | _]}, _schemas, _seen), do: first

  defp factory_value(%OpenApiSpex.Schema{properties: props}, schemas, seen) when is_map(props) do
    Map.new(props, fn {k, v} -> {to_string(k), factory_value(v, schemas, seen)} end)
  end

  defp factory_value(%OpenApiSpex.Schema{type: :array, items: items}, schemas, seen),
    do: [factory_value(items, schemas, seen)]

  defp factory_value(%OpenApiSpex.Schema{type: :integer}, _schemas, _seen), do: 1
  defp factory_value(%OpenApiSpex.Schema{type: :number}, _schemas, _seen), do: 1.0
  defp factory_value(%OpenApiSpex.Schema{type: :boolean}, _schemas, _seen), do: true
  defp factory_value(_schema, _schemas, _seen), do: "x"

  defp ref_name(ref), do: ref |> String.split("/") |> List.last()
  defp underscore_atom(prop), do: prop |> Macro.underscore() |> String.to_atom()
end
