defmodule ExLine.Message.Template do
  @moduledoc """
  Builders for LINE template messages.

  Ref: https://developers.line.biz/en/reference/messaging-api/#template-messages
  """

  @doc """
  Buttons template.

  Options: `:alt_text` (defaults to `text`), `:thumbnail_image_url`,
  `:image_aspect_ratio`, `:image_size`, `:image_background_color`, `:title`,
  `:default_action`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#buttons

      iex> ExLine.Message.Template.buttons("Pick one", [ExLine.Message.Action.message("A", "a")])
      %{
        type: "template",
        altText: "Pick one",
        template: %{type: "buttons", text: "Pick one", actions: [%{type: "message", label: "A", text: "a"}]}
      }
  """
  @spec buttons(String.t(), [map()], keyword()) :: map()
  def buttons(text, actions, opts \\ []) do
    template =
      %{type: "buttons", text: text}
      |> maybe_put(:thumbnailImageUrl, opts[:thumbnail_image_url])
      |> maybe_put(:imageAspectRatio, opts[:image_aspect_ratio])
      |> maybe_put(:imageSize, opts[:image_size])
      |> maybe_put(:imageBackgroundColor, opts[:image_background_color])
      |> maybe_put(:title, opts[:title])
      |> maybe_put(:defaultAction, opts[:default_action])
      |> Map.put(:actions, actions)

    %{type: "template", altText: opts[:alt_text] || text, template: template}
  end

  @doc """
  Confirm template — two actions (yes/no).

  Ref: https://developers.line.biz/en/reference/messaging-api/#confirm

      iex> ExLine.Message.Template.confirm("OK?", [ExLine.Message.Action.message("Yes", "y"), ExLine.Message.Action.message("No", "n")])
      %{
        type: "template",
        altText: "OK?",
        template: %{type: "confirm", text: "OK?", actions: [
          %{type: "message", label: "Yes", text: "y"},
          %{type: "message", label: "No", text: "n"}
        ]}
      }
  """
  @spec confirm(String.t(), [map()], keyword()) :: map()
  def confirm(text, actions, opts \\ []) do
    %{
      type: "template",
      altText: opts[:alt_text] || text,
      template: %{type: "confirm", text: text, actions: actions}
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
