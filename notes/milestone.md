# ex_line — 開發里程碑

> 套件 `ex_line` / 頂層 module `ExLine`。先完成 **Messaging API**（M0–M4），再做 **LIFF**（M5–M7）。
> 細節見 [plan_message_api.md](./plan_message_api.md) 與 [plan_liff.md](./plan_liff.md)；盤點見 [line_message_api.md](./line_message_api.md)、[line_liff.md](./line_liff.md)。
> 勾選規則：`- [ ]` 未完成、`- [x]` 已完成。

---

## M0 — 專案地基

- [x] `mix new . --app ex_line --module ExLine`（無 `--sup`）
- [x] git init + `.gitignore`（補 .DS_Store / LSP / secrets / `.claude/settings.local.json`）
- [x] 設計文件歸檔到 `notes/`
- [x] `mix.exs` 加依賴：`{:req, "~> 0.5"}`、`{:jason, "~> 1.4"}`、`{:plug, "~> 1.16", optional: true}`
- [x] `mix.exs` 補測試/品質依賴：`{:ex_doc, ...}`（dev）、`{:mox, ...}`（test，給 adapter mock）
- [x] 第一個 commit

---

# Part 1 — Messaging API

## M1 — Phase 0：地基 / 解耦（從 hawk 搬並去耦合）

- [x] `ExLine.Client`：憑證值 struct（`access_token` / `channel_id` / `base_url` / `data_url` / `retry`）+ `new/1` + `from_env/0`
- [x] `ExLine.Client.Adapter`：HTTP behaviour（方便 mock）
- [x] `ExLine.Client.Req`：Req 實作；header 注入、`X-Line-Retry-Key`；push 結果分類（200/409→ok、429→quota_exceeded、transient/permanent）放在 `ExLine.Messaging`/`ExLine.Error`（api↔api-data host 切換已具備，待 M2 Content 實際使用）
- [x] `ExLine.Error`：統一錯誤型別（`:transient`/`:quota_exceeded`/`:permanent`/`:network` + `retryable?/1`）
- [x] `ExLine.Message`（+ `Template` / `Action`）：`text`/`sticker`/`with_quick_reply`/`with_sender` + `Action.message/postback/uri` + `Template.buttons/confirm`（`with_quick_reply`/`with_sender` 以函式收進 `ExLine.Message`，未獨立成 QuickReply/Sender 模組）
- [x] `ExLine.Webhook.Signature`：`valid?(body, signature, secret)`，自前 constant-time 比較（不依賴 plug），`sign/2` helper
- [x] `ExLine.Webhook.Plug` + `ExLine.Webhook.BodyReader`：secret 吃 `secret:`（binary 或 `fn conn -> secret end` resolver）；plug 為 optional dep，模組以 `Code.ensure_loaded?(Plug)` 保護
- [x] `ExLine.EventRouter` / `ExLine.EventHandler`：路由 macro，`EventHandler` auto-import `ExLine.Message`
- [x] **驗收**：mock adapter 下 `reply`/`push` 送出正確 body/header（含 retry-key）；驗章單元測試通過；`use ExLine.EventRouter` 可定義 routes 並 dispatch（17 doctests + 32 tests, 0 failures）

## M1.5 — OpenAPI conformance 基礎（開發流程 / QA）

> 以官方 `line-openapi` 為真相來源驗證「我們的格式 == LINE 預期格式」，建立 spec-driven TDD loop。資料驅動：spec 更新只需重 vendor yaml，assertion 自動跟著走。

- [x] 加 test-only 依賴：`open_api_spex`（原生吃 OpenAPI 3.0，免 JSON Schema 預處理）、`yaml_elixir`（讀 .yml 成 map）
- [x] vendor 官方 spec：`messaging-api.yml` 釘 commit `779d8ca9e632` 放 `test/support/line_openapi/`（+ README 記版本；webhook.yml 等之後再加）
- [x] `mix.exs` 啟用 `elixirc_paths(:test)`，讓 `test/support` 共用 helper
- [x] conformance helper：`assert_conforms(value, "TextMessage")`（含 strip discriminator 繞過 open_api_spex 對 LINE 多型模式的不相容）
- [x] 對現有 builder/信封補 conformance 測試：text/sticker/buttons/confirm/action + push/reply/multicast request（12 passed）
- [x] 回報暴露出的落差：text 1..5000 / messages 1..5 builder 未強制（conformance 只驗合法樣本，不會紅）→ 留待 builder 輸入驗證另議；request body 因 strip discriminator 退成驗 base 屬性，每型別嚴格度由具體型別測試補足
- [x] **驗收**：`mix test` 66 passed、`--warnings-as-errors` 乾淨、dialyzer 0 errors
- [x] **重構測試結構**：把 conformance 測試打散進各 module test 檔的 `describe "conformance"`（tag `:conformance`），刪除 `conformance_test.exs`；helper 留 `test/support/`
- [x] **更新 CLAUDE.md**：加 conformance 概念 + spec-driven TDD loop + 測試結構慣例（tagged describe）
- [x] **建 `line-spec-coverage` skill**：(a) 依 commit 更新 vendored spec + diff；(b) 解析 spec operationId/訊息子型別 比對已實作，產出覆蓋率表（對應 namespace + 缺項），對照 milestone
- [ ] TDD loop 確立：之後 M2 每加一型別先寫 `assert_conforms` → 紅 → 實作 → 綠；LINE 改版則重 vendor yaml → diff → 重跑 → 修紅

> **覆蓋率快照（2026-06，messaging-api.yml）**：endpoint 3/73、訊息 3/11、template 2/4、action 3/9。缺的訊息型別（textV2/image/video/audio/location/imagemap/flex/coupon）是 M2 主菜。
> **待補的其他 spec**：webhook.yml（M2 event）、channel-access-token.yml（M3 token）、insight.yml / manage-audience.yml（M4）、liff.yml（Plan 2）。

## M2 — Phase 1：核心 API

- [x] `ExLine.Messaging.reply/4`、`push/4`、`multicast/4`（reply/push 於 M1 完成；multicast 新增，含 retry_key 與 notification_disabled）
- [x] 訊息 builder 補齊：`image` / `video` / `audio` / `location` / `imagemap` / `textV2`（mention/substitution）（`text`/`sticker` 已完成；`coupon` 訊息少用，列選配）
- [x] text 強化：`emojis`、`quoteToken`（引用回覆）支援
- [x] template 補齊：`carousel` / `image_carousel`（`buttons`/`confirm` 已完成）
- [x] action builder 補齊：`datetimepicker` / `camera` / `camera_roll` / `location` / `richmenu_switch` / `clipboard`（`message`/`postback`/`uri` 已完成）
- [x] `ExLine.Message.Flex`：正式 Flex DSL（bubble/carousel/box/text/image/button/separator）
- [x] `ExLine.Content`：下載媒體 / preview / transcoding status（走 api-data host）
- [x] `ExLine.Profile`：`get/2`（Messaging API getProfile，非 LIFF）+ `followers/2`
- [x] `ExLine.Bot`：`info/1`
- [x] quota / count / loading：`quota` / `quota_consumption` + `sent_count/3` + `display_loading_animation`
### webhook event 解析（已定設計：強化版 Plan A，forward-compatible）

> 官方明文:LINE 會**不通知**新增 event/message 型別、enum 值、欄位（non-breaking additions），server 必須照常運作。官方 SDK 的做法是 fallback 成 `UnknownEvent`/`UnknownMessageContent` + 容忍未知欄位。我們對齊。

- [x] vendor `webhook.yml`（釘 commit `779d8ca9e632`）；conformance helper 改吃兩份 spec，依 schema 名挑；fixture 驗 `CallbackRequest`
- [x] `ExLine.Webhook.parse/1`：**total，永不 raise**——未知 type → fallback、未知欄位 → 忽略、單顆壞 → 退 `UnknownEvent`（`parse_event` 以 rescue 保底）
- [x] event struct：高頻事件正式 struct（MessageEvent/PostbackEvent/Follow/Unfollow/Join/Leave/MemberJoined/MemberLeft）+ `Source`（user/group/room）+ message content struct（text/image/video/audio/file/location/sticker）
- [x] fallback：未知事件 → `%ExLine.Webhook.UnknownEvent{type, raw}`；未知 message content → `ExLine.Webhook.Message.Unknown`
- [x] **每個 event/message struct 都帶 `raw:` 原始 map**
- [x] `ExLine.EventRouter` 改寫成 match struct + matcher 擴充：`text "..."`、`message :kind`、`postback`、`follow`/`unfollow`/`join`/`leave`/`member_joined`/`member_left`、強制 `default`
- [ ] 長尾事件（beacon/accountLink/membership/activated/deactivated/botResumed/botSuspended/module/pnp/unsend/videoPlayComplete）先走 `UnknownEvent`，之後逐一補正式 struct（選配）
- [x] **驗收**：fixture 符合 `CallbackRequest`；`parse/1` 對已知/未知/壞掉 payload 都不 raise；EventRouter 正確 dispatch（含 UnknownEvent → default）（135 passed）

> **app glue（非 SDK 核心，文件/generator 說明）**：controller 先回 200、用 supervised async task 逐 event 處理、失敗隔離（hawk 的 `Task.Supervisor.async_nolink` 模式）。

- [ ] **M2 驗收（builder/API 部分）**：每個訊息/template/action 型別有 conformance 測試（spec-driven TDD：先 `assert_conforms` 紅 → 實作 綠）

## M3 — Phase 2：進階

- [ ] `broadcast` / `narrowcast` + narrowcast progress
- [ ] `validate_*`（reply/push/multicast/narrowcast/broadcast 送出前驗證）
- [ ] `*_count`（reply/push/multicast/broadcast）
- [ ] `ExLine.RichMenu`：CRUD / per-user / alias / bulk（含 api-data 圖片上傳）
- [ ] `ExLine.Group`：group / room summary / members / leave
- [ ] Token provider（選配）：`ExLine.Auth.V2_1`（JWT 換發/key id/撤銷）、`ExLine.Auth.Stateless`；`ExLine.Client` 支援動態取 token（可能需要 supervision tree → 屆時補 `--sup`/`application`）
- [ ] retry/backoff 依 endpoint rate limit 分級

## M4 — Phase 3：少用

- [ ] `ExLine.Audience`（受眾管理）
- [ ] `ExLine.Insight`（統計）
- [ ] `ExLine.Membership`
- [ ] `ExLine.Coupon`
- [ ] `ExLine.AccountLink`（link token）
- [ ] beacon / membership 等 webhook event 補完

### ✅ Messaging API 告一段落檢查點

- [ ] 文件 / `ex_doc` 產出可讀
- [ ] 對照 hawk 既有行為驗證等價（reply/push/驗章/profile）
- [ ] （決定後）發佈 0.1.0 到 hex.pm 或內部

---

# Part 2 — LIFF（待 Messaging 告一段落後啟動）

> 前置：M1 + M2 完成（複用 `ExLine.Client` / `ExLine.Error` / HTTP adapter）。
> 釐清：使用者 access token ≠ channel access token；id_token 與 access token 兩條路皆提供。

## M5 — Phase A：Token 驗證原語

- [ ] `ExLine.Login`：LINE Login channel 憑證值（`channel_id` / `channel_access_token`）
- [ ] `ExLine.Login.verify_id_token/2`：POST `/oauth2/v2.1/verify`（補 `nonce` / `user_id` 選填），回結構化 claims（`sub`/`name`/`picture`/`email`）（hawk 已驗證的路徑）
- [ ] `ExLine.Login.verify_access_token/1`：GET `/oauth2/v2.1/verify`，回 `scope`/`client_id`/`expires_in` + `valid?` helper
- [ ] `ExLine.Login.get_profile/1`：GET `/v2/profile`（Bearer 使用者 access token）
- [ ] `ExLine.Login.get_friendship/1`：GET `/friendship/v1/status`（Bearer，查官方帳號好友狀態）
- [ ] **驗收**：給定 id_token + channel_id 能驗證取得 claims；`sub` 可直接餵 `ExLine.Messaging.push`

## M6 — Phase B：LiveView LIFF 編排（招牌功能）

- [ ] `ExLine.Liff.LiveAuth`：on_mount helper，泛用兩段式規則 + `subscribe_disconnect`，參數化 `fetch_user_by_token` / `session_key` / `disconnect_topic` / redirect target
- [ ] `ExLine.Liff.LiveAuth.broadcast_disconnect/1` + per-token topic 慣例
- [ ] 前端 `line_liff.js`：封裝 deferred-connect + CSRF 輪替握手
- [ ] `mix line.gen.liff_auth` generator：吐起手式 `line_login` controller + router 接線範例（使用者自己擁有/複寫）
- [ ] **驗收**：用 generator 在乾淨 Phoenix app 跑出可登入的 LIFF LiveView；切換 user 觸發強制斷線；多 channel / 多 LIFF app 並存無互相污染

## M7 — Phase C：LIFF App 管理 API

- [ ] `ExLine.Liff.Apps`：`list/1` / `create/2` / `update/3` / `delete/2`（`/liff/v1/apps`，Bearer channel access token）
- [ ] **驗收**：能對既有 LIFF app 做 CRUD

---

## 待決事項（不阻塞開發，但要記得拍板）

- [ ] 是否公開到 hex.pm（影響 description「Unofficial」標註、版本策略）
- [ ] 訊息物件維持 map builder（傾向 yes）還是改 struct
- [ ] LIFF 前端 JS 散佈方式（generator snippet / priv 靜態檔 / npm）
- [ ] id_token 是否提供 local ES256+JWKS 驗簽（預設只用 verify endpoint）
