defmodule ExLine.Message.Flex do
  @moduledoc """
  Builders for Flex Message containers and components.

  Compose a Flex message bottom-up: build components (`text/2`, `image/2`,
  `button/2`, `separator/1`) into `box/3`es, boxes into a `bubble/1`
  (header/hero/body/footer), bubbles optionally into a `carousel/1`, then wrap with
  `flex/2`.

      alias ExLine.Message.Flex
      Flex.flex("alt", Flex.bubble(body: Flex.box(:vertical, [Flex.text("Hello")])))

  Ref: https://developers.line.biz/en/reference/messaging-api/#flex-message
  """

  @doc """
  Flex message wrapping a `contents` container (a `bubble/1` or `carousel/1`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#flex-message
  """
  @spec flex(String.t(), map()) :: map()
  def flex(alt_text, contents), do: %{type: "flex", altText: alt_text, contents: contents}

  @doc """
  Bubble container. Options: `:size`, `:direction`, `:header`, `:hero`, `:body`,
  `:footer`, `:action` (each block is a `box/3`, except `:hero`/`:action`).
  """
  @spec bubble(keyword()) :: map()
  def bubble(opts \\ []) do
    %{type: "bubble"}
    |> put(:size, opts[:size])
    |> put(:direction, opts[:direction])
    |> put(:header, opts[:header])
    |> put(:hero, opts[:hero])
    |> put(:body, opts[:body])
    |> put(:footer, opts[:footer])
    |> put(:action, opts[:action])
  end

  @doc "Carousel of bubbles."
  @spec carousel([map()]) :: map()
  def carousel(bubbles), do: %{type: "carousel", contents: bubbles}

  @doc """
  Box component. `layout` is `:horizontal` | `:vertical` | `:baseline`.

  Options: `:flex`, `:spacing`, `:margin`, `:padding_all`, `:background_color`.

      iex> ExLine.Message.Flex.box(:vertical, [])
      %{type: "box", layout: "vertical", contents: []}
  """
  @spec box(atom() | String.t(), [map()], keyword()) :: map()
  def box(layout, contents, opts \\ []) do
    %{type: "box", layout: to_string(layout), contents: contents}
    |> put(:flex, opts[:flex])
    |> put(:spacing, opts[:spacing])
    |> put(:margin, opts[:margin])
    |> put(:paddingAll, opts[:padding_all])
    |> put(:backgroundColor, opts[:background_color])
  end

  @doc """
  Text component. Options: `:size`, `:weight`, `:color`, `:align`, `:wrap`, `:flex`.

      iex> ExLine.Message.Flex.text("Hello", weight: "bold")
      %{type: "text", text: "Hello", weight: "bold"}
  """
  @spec text(String.t(), keyword()) :: map()
  def text(text, opts \\ []) do
    %{type: "text", text: text}
    |> put(:size, opts[:size])
    |> put(:weight, opts[:weight])
    |> put(:color, opts[:color])
    |> put(:align, opts[:align])
    |> put(:wrap, opts[:wrap])
    |> put(:flex, opts[:flex])
  end

  @doc """
  Image component. Options: `:size`, `:aspect_ratio`, `:aspect_mode`, `:flex`.

      iex> ExLine.Message.Flex.image("https://x/i.jpg")
      %{type: "image", url: "https://x/i.jpg"}
  """
  @spec image(String.t(), keyword()) :: map()
  def image(url, opts \\ []) do
    %{type: "image", url: url}
    |> put(:size, opts[:size])
    |> put(:aspectRatio, opts[:aspect_ratio])
    |> put(:aspectMode, opts[:aspect_mode])
    |> put(:flex, opts[:flex])
  end

  @doc """
  Button component wrapping an action (from `ExLine.Message.Action`).

  Options: `:style` (`"primary"`/`"secondary"`/`"link"`), `:color`, `:flex`.
  """
  @spec button(map(), keyword()) :: map()
  def button(action, opts \\ []) do
    %{type: "button", action: action}
    |> put(:style, opts[:style])
    |> put(:color, opts[:color])
    |> put(:flex, opts[:flex])
  end

  @doc """
  Separator component. Options: `:margin`, `:color`.

      iex> ExLine.Message.Flex.separator()
      %{type: "separator"}
  """
  @spec separator(keyword()) :: map()
  def separator(opts \\ []) do
    %{type: "separator"}
    |> put(:margin, opts[:margin])
    |> put(:color, opts[:color])
  end

  defp put(map, _key, nil), do: map
  defp put(map, key, value), do: Map.put(map, key, value)
end
