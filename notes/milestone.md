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

## M2 — Phase 1：核心 API

- [ ] `ExLine.Messaging.reply/4`、`push/4`、`multicast/4`（multicast 為新增）
- [ ] 訊息 builder 補齊：`sticker` / `image` / `video` / `audio` / `location` / `imagemap`
- [ ] template 補齊：`confirm` / `carousel` / `image_carousel`
- [ ] `ExLine.Message.Flex`：正式 Flex DSL（bubble/carousel/box/text/image/button/separator）
- [ ] `ExLine.Content`：下載媒體 / preview / transcoding status（走 api-data host）
- [ ] `ExLine.Profile`：`get_profile/2`（搬自 hawk）+ followers ids
- [ ] `ExLine.Bot`：bot info
- [ ] quota / count / loading：`quota` / `quota_consumption`（搬自 hawk）+ `*_count` + `display_loading_animation`（搬自 hawk）
- [ ] `ExLine.Webhook` event 解析：JSON → struct（message/follow/unfollow/join/leave/postback/memberJoined…），保留 quoteToken/source/replyToken/deliveryContext
- [ ] **驗收**：能組出全部訊息型別並通過 fixture 比對；webhook payload 解析成 struct 並被 EventRouter 正確 match

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
