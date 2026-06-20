defmodule ExLine.Api.RichMenu do
  @moduledoc """
  Rich menu API: create/manage rich menus, upload their images, set the default,
  link per-user, manage aliases, and run bulk (batch) operations.

  Image up/download go through the `api-data.line.me` host. Build a rich menu object
  with `rich_menu/3` (+ `size/1,2`, `area/2`, `bounds/4`; actions come from
  `ExLine.Message.Action`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#rich-menu
  """

  alias ExLine.{Client, Error}

  @base "/v2/bot/richmenu"

  # ── Builders ───────────────────────────────────────────────────────────────

  @doc """
  Rich menu object. `size` is `%{width:, height:}` (see `size/1,2`), `areas` is a
  list from `area/2`. Options: `:name`, `:chat_bar_text`, `:selected`.
  """
  @spec rich_menu(map(), [map()], keyword()) :: map()
  def rich_menu(size, areas, opts \\ []) do
    %{size: size, areas: areas}
    |> maybe_put(:name, opts[:name])
    |> maybe_put(:chatBarText, opts[:chat_bar_text])
    |> maybe_put(:selected, opts[:selected])
  end

  @doc """
  Rich menu size. `:full` → 2500×1686, `:compact` → 2500×843.

      iex> ExLine.Api.RichMenu.size(:full)
      %{width: 2500, height: 1686}
  """
  @spec size(:full | :compact) :: map()
  def size(:full), do: size(2500, 1686)
  def size(:compact), do: size(2500, 843)

  @doc "Custom rich menu size."
  @spec size(integer(), integer()) :: map()
  def size(width, height), do: %{width: width, height: height}

  @doc "A tappable area: `bounds` from `bounds/4`, `action` from `ExLine.Message.Action`."
  @spec area(map(), map()) :: map()
  def area(bounds, action), do: %{bounds: bounds, action: action}

  @doc "Pixel bounds of an area."
  @spec bounds(integer(), integer(), integer(), integer()) :: map()
  def bounds(x, y, width, height), do: %{x: x, y: y, width: width, height: height}

  # ── CRUD ───────────────────────────────────────────────────────────────────

  @doc "Creates a rich menu; returns `{:ok, %{\"richMenuId\" => id}}`. Ref: #create-rich-menu"
  @spec create(Client.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, rich_menu) do
    client |> Client.request(method: :post, path: @base, body: rich_menu) |> Client.decode()
  end

  @doc "Validates a rich menu object without creating it. Ref: #validate-rich-menu-object"
  @spec validate(Client.t(), map()) :: {:ok, term()} | {:error, Error.t()}
  def validate(client, rich_menu) do
    client
    |> Client.request(method: :post, path: "#{@base}/validate", body: rich_menu)
    |> Client.decode()
  end

  @doc "Gets a rich menu. Ref: #get-rich-menu"
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, rich_menu_id) do
    client |> Client.request(method: :get, path: "#{@base}/#{rich_menu_id}") |> Client.decode()
  end

  @doc "Lists rich menus. Ref: #get-rich-menu-list"
  @spec list(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def list(client) do
    client |> Client.request(method: :get, path: "#{@base}/list") |> Client.decode()
  end

  @doc "Deletes a rich menu. Ref: #delete-rich-menu"
  @spec delete(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def delete(client, rich_menu_id) do
    client |> Client.request(method: :delete, path: "#{@base}/#{rich_menu_id}") |> Client.decode()
  end

  # ── Image (api-data host) ────────────────────────────────────────────────────

  @doc """
  Uploads the rich menu image (`content_type` `"image/jpeg"` or `"image/png"`).

  Ref: https://developers.line.biz/en/reference/messaging-api/#upload-rich-menu-image
  """
  @spec set_image(Client.t(), String.t(), binary(), String.t()) ::
          {:ok, term()} | {:error, Error.t()}
  def set_image(client, rich_menu_id, image, content_type) do
    client
    |> Client.request(
      method: :post,
      host: :data,
      path: "#{@base}/#{rich_menu_id}/content",
      raw_body: image,
      content_type: content_type
    )
    |> Client.decode()
  end

  @doc "Downloads the rich menu image (raw bytes). Ref: #download-rich-menu-image"
  @spec get_image(Client.t(), String.t()) :: {:ok, binary()} | {:error, Error.t()}
  def get_image(client, rich_menu_id) do
    client
    |> Client.request(method: :get, host: :data, path: "#{@base}/#{rich_menu_id}/content")
    |> Client.decode()
  end

  # ── Default rich menu ────────────────────────────────────────────────────────

  @doc "Sets the default rich menu for all users. Ref: #set-default-rich-menu"
  @spec set_default(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def set_default(client, rich_menu_id) do
    client
    |> Client.request(method: :post, path: "/v2/bot/user/all/richmenu/#{rich_menu_id}")
    |> Client.decode()
  end

  @doc "Gets the default rich menu id. Ref: #get-default-rich-menu-id"
  @spec get_default(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_default(client) do
    client |> Client.request(method: :get, path: "/v2/bot/user/all/richmenu") |> Client.decode()
  end

  @doc "Clears the default rich menu. Ref: #cancel-default-rich-menu"
  @spec cancel_default(Client.t()) :: {:ok, term()} | {:error, Error.t()}
  def cancel_default(client) do
    client
    |> Client.request(method: :delete, path: "/v2/bot/user/all/richmenu")
    |> Client.decode()
  end

  # ── Per-user linking ─────────────────────────────────────────────────────────

  @doc "Links a rich menu to a user. Ref: #link-rich-menu-to-user"
  @spec link(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def link(client, user_id, rich_menu_id) do
    client
    |> Client.request(method: :post, path: "/v2/bot/user/#{user_id}/richmenu/#{rich_menu_id}")
    |> Client.decode()
  end

  @doc "Links a rich menu to multiple users. Ref: #link-rich-menu-to-users"
  @spec link_bulk(Client.t(), [String.t()], String.t()) :: {:ok, term()} | {:error, Error.t()}
  def link_bulk(client, user_ids, rich_menu_id) do
    body = %{richMenuId: rich_menu_id, userIds: user_ids}

    client
    |> Client.request(method: :post, path: "#{@base}/bulk/link", body: body)
    |> Client.decode()
  end

  @doc "Unlinks a user's rich menu. Ref: #unlink-rich-menu-from-user"
  @spec unlink(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def unlink(client, user_id) do
    client
    |> Client.request(method: :delete, path: "/v2/bot/user/#{user_id}/richmenu")
    |> Client.decode()
  end

  @doc "Unlinks the rich menu from multiple users. Ref: #unlink-rich-menus-from-users"
  @spec unlink_bulk(Client.t(), [String.t()]) :: {:ok, term()} | {:error, Error.t()}
  def unlink_bulk(client, user_ids) do
    client
    |> Client.request(method: :post, path: "#{@base}/bulk/unlink", body: %{userIds: user_ids})
    |> Client.decode()
  end

  @doc "Gets the rich menu id linked to a user. Ref: #get-rich-menu-id-of-user"
  @spec get_for_user(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_for_user(client, user_id) do
    client
    |> Client.request(method: :get, path: "/v2/bot/user/#{user_id}/richmenu")
    |> Client.decode()
  end

  # ── Aliases ──────────────────────────────────────────────────────────────────

  @doc "Creates a rich menu alias. Ref: #create-rich-menu-alias"
  @spec create_alias(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def create_alias(client, alias_id, rich_menu_id) do
    body = %{richMenuAliasId: alias_id, richMenuId: rich_menu_id}

    client
    |> Client.request(method: :post, path: "#{@base}/alias", body: body)
    |> Client.decode()
  end

  @doc "Updates a rich menu alias to point at `rich_menu_id`. Ref: #update-rich-menu-alias"
  @spec update_alias(Client.t(), String.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def update_alias(client, alias_id, rich_menu_id) do
    client
    |> Client.request(
      method: :post,
      path: "#{@base}/alias/#{alias_id}",
      body: %{richMenuId: rich_menu_id}
    )
    |> Client.decode()
  end

  @doc "Deletes a rich menu alias. Ref: #delete-rich-menu-alias"
  @spec delete_alias(Client.t(), String.t()) :: {:ok, term()} | {:error, Error.t()}
  def delete_alias(client, alias_id) do
    client
    |> Client.request(method: :delete, path: "#{@base}/alias/#{alias_id}")
    |> Client.decode()
  end

  @doc "Gets a rich menu alias. Ref: #get-rich-menu-alias-by-id"
  @spec get_alias(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get_alias(client, alias_id) do
    client |> Client.request(method: :get, path: "#{@base}/alias/#{alias_id}") |> Client.decode()
  end

  @doc "Lists rich menu aliases. Ref: #get-rich-menu-alias-list"
  @spec list_aliases(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def list_aliases(client) do
    client |> Client.request(method: :get, path: "#{@base}/alias/list") |> Client.decode()
  end

  # ── Batch (bulk control) ──────────────────────────────────────────────────────

  @doc """
  Runs a batch of rich menu operations (link/unlink/setDefault…). Option
  `:resume_request_key` to resume a previous request. Ref: #batch-control-rich-menus-of-users
  """
  @spec batch(Client.t(), [map()], keyword()) :: {:ok, term()} | {:error, Error.t()}
  def batch(client, operations, opts \\ []) do
    body = %{operations: operations} |> maybe_put(:resumeRequestKey, opts[:resume_request_key])

    client |> Client.request(method: :post, path: "#{@base}/batch", body: body) |> Client.decode()
  end

  @doc "Validates a batch request without running it. Ref: #validate-batch-control-rich-menus-of-users"
  @spec validate_batch(Client.t(), [map()]) :: {:ok, term()} | {:error, Error.t()}
  def validate_batch(client, operations) do
    client
    |> Client.request(
      method: :post,
      path: "#{@base}/validate/batch",
      body: %{operations: operations}
    )
    |> Client.decode()
  end

  @doc "Gets the progress of a batch request. Ref: #get-batch-control-rich-menus-progress-status"
  @spec batch_progress(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def batch_progress(client, request_id) do
    client
    |> Client.request(
      method: :get,
      path: "#{@base}/progress/batch",
      query: [requestId: request_id]
    )
    |> Client.decode()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
