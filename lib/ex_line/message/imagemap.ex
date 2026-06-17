defmodule ExLine.Message.Imagemap do
  @moduledoc """
  Builders for imagemap sub-objects: tappable areas and their actions, plus the
  base size, used by `ExLine.Message.imagemap/5`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#imagemap-message
  """

  @doc """
  Base size of the imagemap image.

      iex> ExLine.Message.Imagemap.base_size(1040, 1040)
      %{width: 1040, height: 1040}
  """
  @spec base_size(integer(), integer()) :: map()
  def base_size(width, height), do: %{width: width, height: height}

  @doc """
  A tappable area (pixels relative to `baseUrl` at `baseSize`).

      iex> ExLine.Message.Imagemap.area(0, 0, 520, 1040)
      %{x: 0, y: 0, width: 520, height: 1040}
  """
  @spec area(integer(), integer(), integer(), integer()) :: map()
  def area(x, y, width, height), do: %{x: x, y: y, width: width, height: height}

  @doc """
  Message imagemap action — sends `text` as the user when the `area` is tapped.

      iex> ExLine.Message.Imagemap.message_action("hello", ExLine.Message.Imagemap.area(0, 0, 1, 1))
      %{type: "message", text: "hello", area: %{x: 0, y: 0, width: 1, height: 1}}
  """
  @spec message_action(String.t(), map(), keyword()) :: map()
  def message_action(text, area, opts \\ []) do
    %{type: "message", text: text, area: area}
    |> ExLine.Message.maybe_put(:label, opts[:label])
  end

  @doc """
  URI imagemap action — opens `link_uri` when the `area` is tapped.

      iex> ExLine.Message.Imagemap.uri_action("https://x", ExLine.Message.Imagemap.area(0, 0, 1, 1))
      %{type: "uri", linkUri: "https://x", area: %{x: 0, y: 0, width: 1, height: 1}}
  """
  @spec uri_action(String.t(), map(), keyword()) :: map()
  def uri_action(link_uri, area, opts \\ []) do
    %{type: "uri", linkUri: link_uri, area: area}
    |> ExLine.Message.maybe_put(:label, opts[:label])
  end
end
