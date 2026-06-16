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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
