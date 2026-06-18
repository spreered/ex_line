# Plan 1 — Messaging API SDK 實作

> 目標：打造獨立的 LINE **Messaging API** hex（`ex_line` / module `ExLine`），並補齊核心訊息能力。
> 定位：**獨立套件，不整合進 hawk、不處理 hawk 重構**。hawk 的 `lib/line/*` 僅作為實作參考素材。
> **LIFF（含 id_token 驗證）不在本 plan**，見 `plan_liff.md`，等本 plan 告一段落再做。
> 盤點來源：`line_message_api.md`。

---

## 0. 已拍板的設計原則（來自討論）

1. **單一 hex**，套件名 `ex_line`、頂層 module `ExLine`。
2. **憑證一律當「值」傳入，不綁全域**。每個 API 只收它真正需要的那一份憑證，不收「多 channel 合一」的 bundle。
3. app env 只當「單 channel 簡單情境」的便利預設；**多 channel 才是預設支援情境**。
4. Plug / 需要在 runtime 挑 channel 的地方，吃 **resolver function**，SDK 不持有 registry。
5. `EventRouter` / `EventHandler` 這類純路由 DSL 以 `use` macro 放進 SDK。
6. SDK 只做：API client + 訊息 builder + webhook 驗章/解析 + 路由 DSL。app glue（controller/router 接線）留給應用層或之後的 generator。

---

## 1. 憑證設計

Messaging API 範圍只需要兩種憑證，且分屬不同信任邊界，**不該綁成一個 bundle**：

| SDK 用途 | 需要的憑證 |
|---|---|
| reply / push / multicast / content / profile / quota… | Messaging channel **access token** |
| webhook 驗章 | Messaging channel **secret** |

### 1.1 `ExLine.Client`（憑證 + HTTP 設定的值）

```elixir
%ExLine.Client{
  access_token: "...",        # 必要：Messaging channel access token
  channel_id:   "...",        # 選填：部分 token 管理 endpoint 用
  adapter:      ExLine.Client.Req,   # 預設 Req 實作，可注入 mock
  base_url:     "https://api.line.me",
  data_url:     "https://api-data.line.me",
  retry:        [...]         # 429 / transient backoff 設定
}
```

- **建構來源不限**：可從 DB row（多 channel/多租戶）或 app env 建。
  - `ExLine.Client.new(access_token: tok)` — 顯式建。
  - `ExLine.Client.from_env()` — 單 channel 便利預設（讀 `config :ex_line, ...`）。
- 每個 API 函式第一參數收 `%ExLine.Client{}`：`ExLine.Api.Messaging.push(client, user_id, messages, opts)`。
- webhook secret **不放進 client**（屬另一個信任邊界，且驗章發生在收訊端）：`ExLine.Webhook.valid_signature?(body, signature, secret)` 直接收 secret。
- **多 channel 用法**：呼叫端自行依情境組出對應的 `%ExLine.Client{}` 再傳入，SDK 不持有任何 channel registry。

---

## 2. 目標 module 樹（Messaging 範圍）

```
ExLine
├── ExLine.Client                 # 憑證值 + HTTP 設定；new/1, from_env/0
│   ├── ExLine.Client.Adapter     # behaviour（request/…），方便 mock
│   └── ExLine.Client.Req         # Req 實作：header 注入、api↔api-data 切換、retry-key、429 backoff
├── ExLine.Error                  # 統一錯誤型別
│
├── ExLine.Message                # 訊息 builder（text/sticker/image/video/audio/location/imagemap）
│   ├── ExLine.Message.Template   # buttons/confirm/carousel/image_carousel
│   ├── ExLine.Message.Flex       # bubble/carousel/box/text/button… DSL
│   ├── ExLine.Message.Action     # postback/message/uri/datetimepicker/camera/…
│   ├── ExLine.Message.QuickReply # with_quick_reply/2
│   └── ExLine.Message.Sender     # with_sender/2
│
├── ExLine.Api                       # LINE API client（依 endpoint 分群，放 lib/ex_line/api/）
│   ├── ExLine.Api.Messaging         # 發送類：reply/push/multicast/broadcast/narrowcast
│   │                                #   + validate_* / *_count / quota / loading
│   ├── ExLine.Api.Content           # 下載媒體 / preview / transcoding status（api-data host）
│   ├── ExLine.Api.Profile           # get/2、followers/2
│   ├── ExLine.Api.Bot               # info/1
│   ├── ExLine.Api.Group             # group / room 管理
│   └── ExLine.Api.RichMenu          # CRUD / per-user / alias / bulk
│
├── ExLine.Webhook               # event 解析（JSON → struct）+ 型別
│   ├── ExLine.Webhook.Signature # HMAC-SHA256 驗章（收 secret 參數）
│   └── ExLine.Webhook.Plug      # Plug：保留 raw body + 驗章（secret 用 resolver）
│
├── ExLine.EventRouter           # 路由 DSL（use macro）
└── ExLine.EventHandler          # handler behaviour（use macro）
```

進階/少用群（Audience/Insight/Membership/Coupon/AccountLink）排 Phase 3。

---

## 3. 階段與工作項

> 「參考」欄列出 hawk 中可借鏡的對應檔案（僅供實作參考，本 plan 不改 hawk）。

### Phase 0 — 地基（先做，價值最高）

**目標**：建立 mix 專案骨架與最核心的 client / 訊息 / 驗章 / 路由，跑得起來。

| 工作 | 說明 | 參考 |
|---|---|---|
| 建立 mix 專案（deps: req, jason） | 已完成 | — |
| `ExLine.Client` + `ExLine.Client.Adapter` + `ExLine.Client.Req` | Req client：header 注入、api↔api-data host 切換、`X-Line-Retry-Key`、push 結果分類（200/409→ok、429→quota_exceeded、transient/permanent）；adapter 設計成 behaviour 方便 mock | `lib/line/api/client.ex` |
| `ExLine.Error` | 統一錯誤型別（`{:transient, _}` / `{:permanent, _}` / `:quota_exceeded` 正規化） | — |
| `ExLine.Message` + `Template` + `Action` + `QuickReply` + `Sender` | `text_message` / `buttons_message` / `action` / `with_quick_reply` / 泛用 `with_sender/2` | `lib/line/messages.ex` |
| `ExLine.Webhook.Signature` | `valid_signature?(body, signature, secret)`，constant-time 比較，**只收 secret 參數**（不依賴任何 provider/registry） | `verify_signature.ex` |
| `ExLine.Webhook.Plug` + raw body reader | 保留 raw body + 驗章；secret 來源吃 `secret: &resolver/1` opt | `cache_body_reader.ex` |
| `ExLine.EventRouter` / `ExLine.EventHandler` | 路由 DSL macro；`EventHandler` auto-import 指向 `ExLine.*` | `event_router.ex` / `event_handler.ex` |

**驗收**：`reply`/`push` 對 mock adapter 可送出正確 body/header；webhook 驗章單元測試通過；`use ExLine.EventRouter` 可定義 routes 並 dispatch。

---

### Phase 1 — 核心 API（任何 bot 都要）

**目標**：補齊核心訊息能力，並讓 webhook 從 raw map 升級成 struct。

| 工作 | 說明 |
|---|---|
| `ExLine.Api.Messaging.reply/push/multicast` | reply/push 核心；multicast 新增 |
| 訊息 builder 補齊 | 新增 sticker / image / video / audio / location / imagemap；template 補 confirm / carousel / image_carousel |
| `ExLine.Message.Flex` DSL | 正式 Flex builder（bubble/carousel/box/text/image/button/separator） |
| `ExLine.Api.Content` | 下載使用者媒體 / preview / transcoding status（走 `api-data.line.me`，client 需可切 host） |
| `ExLine.Api.Profile` | `get_profile/2` + followers ids |
| `ExLine.Api.Bot` | bot info |
| quota / count / loading | `quota` / `quota_consumption` + `*_count` + `display_loading_animation` |
| `ExLine.Webhook` event 解析 | JSON → struct：message(text/image/…)/follow/unfollow/join/leave/postback/memberJoined…；保留 `quoteToken`、`source`、`replyToken`、`deliveryContext` |

**驗收**：能組出全部訊息型別並通過 `validate_*`（若該 phase 已做）或 fixture 比對；webhook payload 能解析成 struct 並被 EventRouter 正確 match。

---

### Phase 2 — 進階

| 工作 | 說明 |
|---|---|
| `broadcast` / `narrowcast` + progress + `validate_*` | 行銷投放 |
| `*_count`（reply/push/multicast/broadcast） | 統計數量 |
| `ExLine.Api.RichMenu` | CRUD / per-user / alias / bulk（含 api-data 圖片上傳） |
| `ExLine.Api.Group` | group / room summary / members / leave |
| Token provider（選配） | `ExLine.Auth.V2_1`（JWT 換發/key id/撤銷）、`ExLine.Auth.Stateless`；`ExLine.Client` 支援動態取 token |
| retry/backoff 分 endpoint | 依 rate limit 差異（narrowcast 60/hr、richmenu 100/hr…）調整 |

---

### Phase 3 — 少用

`ExLine.Api.Audience` / `ExLine.Api.Insight` / `ExLine.Api.Membership` / `ExLine.Api.Coupon` / `ExLine.Api.AccountLink`；beacon/membership 等 webhook event 補完。

---

## 4. 從 Messaging 範圍刻意排除的東西

- **`verify_id_token` / access token 驗證 / LINE Login profile**：屬於 **LINE Login / LIFF** 信任邊界，**移到 `plan_liff.md`**。Phase 0 不碰 login channel 概念，避免混進 Messaging client。
- LIFF deep link builder — app 專屬，不進 SDK。

---

## 5. 測試策略

- `ExLine.Client.Adapter` behaviour → 測試用 Mox/手寫 mock adapter，斷言送出的 request body/header/host 正確（無網路）。
- Builder / Webhook 解析 → 純函式，fixture 比對（用真實 webhook payload 當 fixture）。
- Signature → 已知 secret/body/signature 向量。
- 真實 API smoke test → 個人測試 channel，憑證走 env，`@tag :external` 預設跳過。

---

## 6. 待決事項

1. **是否公開到 hex.pm？** 影響 description 是否標「Unofficial」、版本策略與 API 嚴謹度。（命名已定 `ex_line` / `ExLine`。）
2. **HTTP lib**：用 **Req**（不引入 Tesla/Finch 直用）。
3. **訊息物件用 struct 還是 map builder？** 建議維持 map builder（輕、好序列化），但提供 `validate_*` 與 typespec。

---

## 7. 第一步建議

從 **Phase 0** 開始：建 client / message / webhook signature / event router 並跑通 `reply`/`push` + 驗章測試，再往 Phase 1 推。
