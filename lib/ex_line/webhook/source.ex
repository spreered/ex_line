defmodule ExLine.Webhook.Source do
  @moduledoc """
  The origin of a webhook event: a user, group, or room.

  `type` is `"user"` | `"group"` | `"room"`; the matching id field is populated
  (`user_id` is also present for group/room events when available). `raw` keeps the
  original map.

  Ref: https://developers.line.biz/en/reference/messaging-api/#source-user
  """

  defstruct [:type, :user_id, :group_id, :room_id, :raw]

  @type t :: %__MODULE__{
          type: String.t() | nil,
          user_id: String.t() | nil,
          group_id: String.t() | nil,
          room_id: String.t() | nil,
          raw: map() | nil
        }

  @doc false
  def parse(%{"type" => type} = source) do
    %__MODULE__{
      type: type,
      user_id: source["userId"],
      group_id: source["groupId"],
      room_id: source["roomId"],
      raw: source
    }
  end

  def parse(_), do: nil
end
