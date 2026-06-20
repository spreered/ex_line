defmodule ExLine.RichMenuTest do
  use ExUnit.Case, async: true

  import Mox
  import ExLine.Conformance

  alias ExLine.Api.RichMenu
  alias ExLine.Client
  alias ExLine.Message.Action

  doctest ExLine.Api.RichMenu

  setup :verify_on_exit!

  defp client, do: Client.new(access_token: "tok", adapter: ExLine.AdapterMock)
  @api "https://api.line.me"
  @data "https://api-data.line.me"

  # Asserts the adapter is called with method+url, returns a canned 200 body.
  defp expect_request(method, url, body \\ %{}) do
    expect(ExLine.AdapterMock, :request, fn req ->
      assert req.method == method
      assert req.url == url
      {:ok, %{status: 200, body: body}}
    end)
  end

  defp menu do
    RichMenu.rich_menu(
      RichMenu.size(:full),
      [RichMenu.area(RichMenu.bounds(0, 0, 1250, 1686), Action.message("L", "left"))],
      name: "menu",
      chat_bar_text: "tap",
      selected: false
    )
  end

  describe "conformance" do
    @describetag :conformance

    test "rich_menu builder → RichMenuRequest" do
      assert_conforms(menu(), "RichMenuRequest")
    end
  end

  describe "CRUD" do
    test "create posts the rich menu object" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "#{@api}/v2/bot/richmenu"
        assert req.body.size == %{width: 2500, height: 1686}
        {:ok, %{status: 200, body: %{"richMenuId" => "rm1"}}}
      end)

      assert {:ok, %{"richMenuId" => "rm1"}} = RichMenu.create(client(), menu())
    end

    test "validate / get / list / delete" do
      expect_request(:post, "#{@api}/v2/bot/richmenu/validate")
      assert {:ok, _} = RichMenu.validate(client(), menu())

      expect_request(:get, "#{@api}/v2/bot/richmenu/rm1")
      assert {:ok, _} = RichMenu.get(client(), "rm1")

      expect_request(:get, "#{@api}/v2/bot/richmenu/list")
      assert {:ok, _} = RichMenu.list(client())

      expect_request(:delete, "#{@api}/v2/bot/richmenu/rm1")
      assert {:ok, _} = RichMenu.delete(client(), "rm1")
    end
  end

  describe "image (api-data host)" do
    test "set_image uploads raw bytes with the given content-type" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.method == :post
        assert req.url == "#{@data}/v2/bot/richmenu/rm1/content"
        assert req.raw_body == <<137, 80, 78, 71>>
        assert {"content-type", "image/png"} in req.headers
        refute {"content-type", "application/json"} in req.headers
        {:ok, %{status: 200, body: ""}}
      end)

      assert {:ok, _} = RichMenu.set_image(client(), "rm1", <<137, 80, 78, 71>>, "image/png")
    end

    test "get_image downloads from the api-data host" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@data}/v2/bot/richmenu/rm1/content"
        {:ok, %{status: 200, body: <<1, 2, 3>>}}
      end)

      assert {:ok, <<1, 2, 3>>} = RichMenu.get_image(client(), "rm1")
    end
  end

  describe "default" do
    test "set / get / cancel default" do
      expect_request(:post, "#{@api}/v2/bot/user/all/richmenu/rm1")
      assert {:ok, _} = RichMenu.set_default(client(), "rm1")

      expect_request(:get, "#{@api}/v2/bot/user/all/richmenu")
      assert {:ok, _} = RichMenu.get_default(client())

      expect_request(:delete, "#{@api}/v2/bot/user/all/richmenu")
      assert {:ok, _} = RichMenu.cancel_default(client())
    end
  end

  describe "per-user linking" do
    test "link / unlink / get_for_user" do
      expect_request(:post, "#{@api}/v2/bot/user/U1/richmenu/rm1")
      assert {:ok, _} = RichMenu.link(client(), "U1", "rm1")

      expect_request(:delete, "#{@api}/v2/bot/user/U1/richmenu")
      assert {:ok, _} = RichMenu.unlink(client(), "U1")

      expect_request(:get, "#{@api}/v2/bot/user/U1/richmenu")
      assert {:ok, _} = RichMenu.get_for_user(client(), "U1")
    end

    test "bulk link / unlink send the right body" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/richmenu/bulk/link"
        assert req.body == %{richMenuId: "rm1", userIds: ["U1", "U2"]}
        {:ok, %{status: 200, body: ""}}
      end)

      RichMenu.link_bulk(client(), ["U1", "U2"], "rm1")

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/richmenu/bulk/unlink"
        assert req.body == %{userIds: ["U1"]}
        {:ok, %{status: 200, body: ""}}
      end)

      RichMenu.unlink_bulk(client(), ["U1"])
    end
  end

  describe "aliases" do
    test "create / update / get / delete / list" do
      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/richmenu/alias"
        assert req.body == %{richMenuAliasId: "a", richMenuId: "rm1"}
        {:ok, %{status: 200, body: ""}}
      end)

      RichMenu.create_alias(client(), "a", "rm1")

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/richmenu/alias/a"
        assert req.body == %{richMenuId: "rm2"}
        {:ok, %{status: 200, body: ""}}
      end)

      RichMenu.update_alias(client(), "a", "rm2")

      expect_request(:get, "#{@api}/v2/bot/richmenu/alias/a")
      assert {:ok, _} = RichMenu.get_alias(client(), "a")

      expect_request(:delete, "#{@api}/v2/bot/richmenu/alias/a")
      assert {:ok, _} = RichMenu.delete_alias(client(), "a")

      expect_request(:get, "#{@api}/v2/bot/richmenu/alias/list")
      assert {:ok, _} = RichMenu.list_aliases(client())
    end
  end

  describe "batch" do
    test "batch / validate_batch / progress" do
      ops = [%{type: "link", from: "rm1", to: "rm2"}]

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/richmenu/batch"
        assert req.body == %{operations: ops, resumeRequestKey: "k"}
        {:ok, %{status: 202, body: ""}}
      end)

      RichMenu.batch(client(), ops, resume_request_key: "k")

      expect_request(:post, "#{@api}/v2/bot/richmenu/validate/batch")
      assert {:ok, _} = RichMenu.validate_batch(client(), ops)

      expect(ExLine.AdapterMock, :request, fn req ->
        assert req.url == "#{@api}/v2/bot/richmenu/progress/batch"
        assert {:requestId, "req-1"} in req.query
        {:ok, %{status: 200, body: %{"phase" => "succeeded"}}}
      end)

      assert {:ok, %{"phase" => "succeeded"}} = RichMenu.batch_progress(client(), "req-1")
    end
  end
end
