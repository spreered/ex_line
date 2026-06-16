# Plan 2 — LIFF 支援（延後，等 Messaging API 告一段落再做）

> 目標：在 Messaging API（見 `plan_message_api.md`）穩定後，加入 **LIFF / LINE Login 後端能做的部分**：token 驗證原語、LIFF-on-LiveView 編排、LIFF app 管理。
> 定位：**獨立套件，不整合進 hawk、不處理 hawk 重構**。hawk 的 LIFF 實作僅作為參考素材。
> **前置條件**：Plan 1 的 Phase 0 + Phase 1 完成（`ExLine.Client` / `ExLine.Error` / HTTP adapter 已就緒，本 plan 直接複用）。
> 盤點來源：`line_liff.md`。

---

## 0. 範圍界定（先講清楚什麼不做）

LIFF 主體是前端 JS（`@line/liff`），SDK **不負責也無法實作** `liff.init/login/getProfile/sendMessages/openWindow/scanCodeV2…`。
後端能做、SDK 該封裝的只有三類，外加一套「LiveView 整合的 know-how」：

| 類別 | 內容 | 階段 |
|---|---|---|
| **Token 驗證原語** | id_token / access_token 驗證、LINE Login profile、friendship | Phase A |
| **LiveView LIFF 編排** | 兩段式 on_mount + per-token 強制斷線 + 前端 deferred-connect handshake + generator | Phase B |
| **LIFF app 管理** | `/liff/v1/apps` CRUD | Phase C |

---

## 0.5 關鍵概念：兩種「access token」完全不同

LIFF 場景最常見的混淆。**使用者 access token** 才是本 plan Phase A 處理的對象：

| | **使用者 access token**（LIFF/LINE Login） | channel access token（Messaging） |
|---|---|---|
| 代表 | 一個**使用者**的授權 | 你的 **bot / channel** 本身 |
| 來源 | 前端 `liff.getAccessToken()` | 後端用 channel id+secret 簽發 |
| 用途 | 代表使用者去問 LINE Login 資料 | Messaging API（push/reply…），屬 Plan 1 |
| 效期 | ~12h，**LIFF 關掉就 revoke** | 30 天 / stateless 等 |
| 本質 | 不透明字串（不含資料） | — |

### id_token vs 使用者 access token：何時選哪個

- **id_token = 身分快照**。登入當下把 profile claim（sub/name/picture/email）一起塞在 JWT 裡，驗一次同時拿到身分 + profile。**一次性**，適合「登入辨識」。
- **使用者 access token = 期間通行證**。在 ~12h 內後端可**反覆**代表使用者向 LINE 查資料（profile/friendship）。適合「session 期間後端要持續查」。
- 若授權時**沒要 `openid` scope，就拿不到 id_token，只有 access token** → 只能走 access token + `/v2/profile`。
- access token ~12h 失效，**不適合當長期身分**；長期身分仍靠 id_token 驗完後建自己的 session。
- **兩條路 SDK 都提供，讓使用者自選。**

---

## 1. 憑證（延續 Plan 1 原則：依 channel 切，當值傳入）

LIFF 牽涉的是 **LINE Login channel**（與 Messaging channel 不同），需要的憑證：

| SDK 用途 | 需要的憑證 |
|---|---|
| id_token 驗證 | **Login** channel id（做 `client_id` 比對） |
| access_token 驗證 | 無（帶 access_token 本身查詢） |
| LINE Login profile / friendship | 使用者 access token（Bearer） |
| LIFF app 管理 | **Login** channel 的 channel access token（Bearer） |

→ 新增獨立憑證值 `%ExLine.Login{channel_id: ..., channel_access_token: ...}`，**不與 `ExLine.Client`（Messaging）混用**。endpoint 走 `api.line.me`，複用 Plan 1 的 HTTP adapter。

---

## 2. 目標 module 樹（LIFF 範圍）

```
ExLine.Login                   # LINE Login channel 憑證值 + OAuth2 endpoints
├── verify_id_token/2          # POST /oauth2/v2.1/verify（id_token + client_id, 選填 nonce/user_id）
├── verify_access_token/1      # GET  /oauth2/v2.1/verify（scope/client_id/expires_in）
├── get_profile/1              # GET  /v2/profile（Bearer 使用者 access token）
└── get_friendship/1           # GET  /friendship/v1/status（Bearer，查官方帳號好友狀態）

ExLine.Liff
├── ExLine.Liff.Apps           # /liff/v1/apps CRUD（Bearer channel access token）
├── ExLine.Liff.LiveAuth       # LiveView on_mount helper（吃 callback，泛用化兩段式編排）
└── ExLine.Liff.Plug           # （選配）controller plug helper：驗 id_token → 放 sub 進 assigns
```

前端：`priv/static/line_liff.js`（或 npm snippet）——封裝 deferred-connect + CSRF 輪替握手。

---

## 3. 階段與工作項

### Phase A — Token 驗證原語（小、純 HTTP，最先做）

| 工作 | 說明 |
|---|---|
| `ExLine.Login.verify_id_token/2` | POST `/oauth2/v2.1/verify`，**補 `nonce` / `user_id` 選填參數**，回結構化 claims（`sub`/`name`/`picture`/`email`…）。預設走 verify endpoint；可選 local ES256+JWKS 驗簽為進階模式 |
| `ExLine.Login.verify_access_token/1` | GET `/oauth2/v2.1/verify`，回 `scope`/`client_id`/`expires_in` + `valid?` helper |
| `ExLine.Login.get_profile/1` | GET `/v2/profile`（Bearer 使用者 access token），回 `userId`/`displayName`/`pictureUrl`/`statusMessage`。**注意與 Messaging `ExLine.Profile.get_profile` 是不同 endpoint** |
| `ExLine.Login.get_friendship/1` | GET `/friendship/v1/status`（Bearer），回是否已加官方帳號好友 |

**驗收**：給定 id_token + channel_id 能驗證並取得 claims；`sub` 可直接餵 Plan 1 的 `ExLine.Messaging.push`（`sub` = Messaging userId）。

---

### Phase B — LiveView LIFF 編排（招牌功能，慎重做）

把「踩過坑的編排」泛用化。典型流程（參考，非照搬）：
- 前端：`liff.init({withLoginOnExternalBrowser:true})` → 取 idToken/decode aud → POST login endpoint → **拿回新 CSRF、換 meta、之後才 connect LiveSocket**。
- 後端 controller：`verify_id_token` → 建/取 user → 寫 session → 回 CSRF；不同 user 登入同一情境用 per-token PubSub 強制斷線。
- `on_mount`：**兩段式**——未連線 mount 直接 pass；連線後有 user pass + `subscribe_disconnect`；連線後無 user redirect。

**SDK 提供（library 化的部分）：**

| 元件 | 設計 |
|---|---|
| `ExLine.Liff.LiveAuth`（on_mount helper） | 泛用兩段式規則 + `subscribe_disconnect`，參數化：`fetch_user_by_token`、`session_key`、`disconnect_topic`、redirect target。使用者 `on_mount {ExLine.Liff.LiveAuth, opts}` |
| `priv/static/line_liff.js` | 封裝 deferred-connect + CSRF 輪替握手成一個函式，使用者帶 liff id + login endpoint 呼叫 |
| per-token disconnect helper | `ExLine.Liff.LiveAuth.broadcast_disconnect/1` + topic 慣例，供 controller 端呼叫 |

**SDK 不做、用 generator 產出（app glue）：**

| 元件 | generator |
|---|---|
| `line_login` controller（建 user + 挑 channel + 寫 session 策略） | `mix line.gen.liff_auth` 吐起手式 controller，使用者自己擁有/複寫 |
| router 接線（live_session / pipeline 範例） | generator 一併產出範例片段 + 說明 |

**設計關鍵**：controller 怎麼「建 user / 挑哪個 LINE Login channel」是 app 決定。SDK 只提供原語 + on_mount helper + JS + scaffold，**絕不寫死 user model 或 channel registry**（延續 resolver 原則）。

**驗收**：用 generator 在乾淨 Phoenix app 跑出可登入的 LIFF LiveView；切換不同 user 觸發強制斷線；多 channel/多 LIFF app 並存無互相污染。

---

### Phase C — LIFF app 管理 API

| 工作 | 說明 |
|---|---|
| `ExLine.Liff.Apps.list/1` `create/2` `update/3` `delete/2` | `/liff/v1/apps`，Bearer **channel access token**；每 channel 上限 30 app |

少用，最後做。

---

## 4. 與 Plan 1 的交界

- **複用**：`ExLine.Client` 的 HTTP adapter / `ExLine.Error` / retry 設定。
- **不混用憑證**：`ExLine.Login`（login channel）與 `ExLine.Client`（messaging channel）是兩個值，分開傳。
- **接點**：`verify_id_token` 的 `sub` = `ExLine.Profile` / Messaging 的 `userId`，文件明確標註，讓「LIFF 登入 → 直接推播」順暢。

---

## 5. 待決事項

1. **前端 JS 怎麼散佈**？`priv/static` 附帶檔、npm 套件、或只給 generator 產出的 snippet。預設先用 generator 產 snippet。
2. **local 驗簽要不要做**？官方建議直接用 verify endpoint。預設只做 endpoint 版，ES256+JWKS 列為日後進階。
3. **on_mount helper 的 session 形狀**：傾向「給預設慣例 + 可覆寫」。

---

## 6. 啟動條件

待 `plan_message_api.md` 的 Phase 0–1 完成後，再啟動本 plan，從 **Phase A** 開始。
