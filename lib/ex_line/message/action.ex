defmodule ExLine.Message.Action do
  @moduledoc """
  Builders for LINE action objects (used in templates, quick replies, imagemaps).

  Ref: https://developers.line.biz/en/reference/messaging-api/#action-objects
  """

  @doc """
  Message action — sends `text` as the user when tapped.

  Ref: https://developers.line.biz/en/reference/messaging-api/#message-action

      iex> ExLine.Message.Action.message("Label", "sent text")
      %{type: "message", label: "Label", text: "sent text"}
  """
  @spec message(String.t(), String.t()) :: map()
  def message(label, text), do: %{type: "message", label: label, text: text}

  @doc """
  Postback action — delivers `data` to your webhook as a postback event.

  Options: `:display_text`, `:input_option`, `:fill_in_text`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#postback-action

      iex> ExLine.Message.Action.postback("Buy", "action=buy&id=1")
      %{type: "postback", label: "Buy", data: "action=buy&id=1"}

      iex> ExLine.Message.Action.postback("Buy", "action=buy", display_text: "Buying")
      %{type: "postback", label: "Buy", data: "action=buy", displayText: "Buying"}
  """
  @spec postback(String.t(), String.t(), keyword()) :: map()
  def postback(label, data, opts \\ []) do
    %{type: "postback", label: label, data: data}
    |> maybe_put(:displayText, opts[:display_text])
    |> maybe_put(:inputOption, opts[:input_option])
    |> maybe_put(:fillInText, opts[:fill_in_text])
  end

  @doc """
  URI action — opens `uri` when tapped.

  Ref: https://developers.line.biz/en/reference/messaging-api/#uri-action

      iex> ExLine.Message.Action.uri("Open", "https://example.com")
      %{type: "uri", label: "Open", uri: "https://example.com"}
  """
  @spec uri(String.t(), String.t()) :: map()
  def uri(label, uri), do: %{type: "uri", label: label, uri: uri}

  @doc """
  Datetime picker action. `mode` is `:date` | `:time` | `:datetime`.

  Options: `:initial`, `:max`, `:min`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#datetime-picker-action

      iex> ExLine.Message.Action.datetimepicker("Pick", "d", :datetime)
      %{type: "datetimepicker", label: "Pick", data: "d", mode: "datetime"}
  """
  @spec datetimepicker(String.t(), String.t(), :date | :time | :datetime, keyword()) :: map()
  def datetimepicker(label, data, mode, opts \\ []) when mode in [:date, :time, :datetime] do
    %{type: "datetimepicker", label: label, data: data, mode: Atom.to_string(mode)}
    |> maybe_put(:initial, opts[:initial])
    |> maybe_put(:max, opts[:max])
    |> maybe_put(:min, opts[:min])
  end

  @doc """
  Camera action — opens the camera screen.

  Ref: https://developers.line.biz/en/reference/messaging-api/#camera-action

      iex> ExLine.Message.Action.camera("Camera")
      %{type: "camera", label: "Camera"}
  """
  @spec camera(String.t()) :: map()
  def camera(label), do: %{type: "camera", label: label}

  @doc """
  Camera roll action — opens the photo library.

  Ref: https://developers.line.biz/en/reference/messaging-api/#camera-roll-action

      iex> ExLine.Message.Action.camera_roll("Album")
      %{type: "cameraRoll", label: "Album"}
  """
  @spec camera_roll(String.t()) :: map()
  def camera_roll(label), do: %{type: "cameraRoll", label: label}

  @doc """
  Location action — opens the location screen.

  Ref: https://developers.line.biz/en/reference/messaging-api/#location-action

      iex> ExLine.Message.Action.location("Location")
      %{type: "location", label: "Location"}
  """
  @spec location(String.t()) :: map()
  def location(label), do: %{type: "location", label: label}

  @doc """
  Clipboard action — copies `clipboard_text` (max 1000 chars) when tapped.

  Ref: https://developers.line.biz/en/reference/messaging-api/#clipboard-action

      iex> ExLine.Message.Action.clipboard("Copy", "copied")
      %{type: "clipboard", label: "Copy", clipboardText: "copied"}
  """
  @spec clipboard(String.t(), String.t()) :: map()
  def clipboard(label, clipboard_text),
    do: %{type: "clipboard", label: label, clipboardText: clipboard_text}

  @doc """
  Rich menu switch action — switches to the rich menu with `rich_menu_alias_id`.

  Ref: https://developers.line.biz/en/reference/messaging-api/#richmenu-switch-action

      iex> ExLine.Message.Action.richmenu_switch("Next", "menu-b", "switched")
      %{type: "richmenuswitch", label: "Next", richMenuAliasId: "menu-b", data: "switched"}
  """
  @spec richmenu_switch(String.t(), String.t(), String.t()) :: map()
  def richmenu_switch(label, rich_menu_alias_id, data),
    do: %{type: "richmenuswitch", label: label, richMenuAliasId: rich_menu_alias_id, data: data}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
