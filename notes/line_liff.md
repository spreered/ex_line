# LINE LIFF — Elixir SDK / 後端支援功能清單

> 調研日期：2026-06-16
> 來源：LINE Developers 官方文件
> - [LIFF overview](https://developers.line.biz/en/docs/liff/)
> - [LIFF SDK reference](https://developers.line.biz/en/reference/liff/)
> - [LIFF server API reference](https://developers.line.biz/en/reference/liff-server/)
> - [LINE Login API reference](https://developers.line.biz/en/reference/line-login/)
> - [Using user profile](https://developers.line.biz/en/docs/liff/using-user-profile/)
> - [Verify ID token](https://developers.line.biz/en/docs/line-login/verify-id-token/)

---

## 0. 核心觀念：LIFF 大部分是「前端 JS」，後端能做的是「token 驗證 + LINE Login API + LIFF app 管理」

**LIFF (LINE Front-end Framework)** 是一個在 LINE App 內（或外部瀏覽器）執行的 **Web App 平台**。
它本質上是一套 **前端 JavaScript SDK**（`@line/liff`），讓網頁能拿到 LINE 平台的使用者資料。

LIFF app 必須掛在一個 **LINE Login channel** 之下（在 LINE Developers Console 或透過 LIFF server API 註冊）。

對 **Elixir SDK** 而言，「後端真正能做、該做」的事情只有三類：

| 類別 | 後端能做的事 | 對應 API |
|------|-------------|----------|
| **Token 驗證** | 驗證前端 `liff.getIDToken()` / `liff.getAccessToken()` 傳來的 token | LINE Login OAuth2 verify endpoints |
| **取得 Profile** | 用 access token 向 LINE 取得使用者 profile | `GET /v2/profile` |
| **LIFF app 管理** | 用 channel access token CRUD LIFF apps | LIFF server API (`/liff/v1/apps`) |

> **安全重點（官方明文警告）：**
> 不要把 `liff.getProfile()` / `liff.getDecodedIDToken()` 在前端解碼後的「使用者資料」直接送到後端當作可信來源。
> 後端要信任的話，**只接收 ID token / access token 本身，並由後端向 LINE 驗證**。前端解碼結果可被竄改。

---

## 1. LIFF 前端 SDK 方法概覽（SDK 不負責實作，但作者要知道前端會拿到什麼）

> 標 🔑 = 會產生「後端需要驗證 / 處理的 token」。
> 參考：[LIFF SDK reference](https://developers.line.biz/en/reference/liff/)（下表 Ref 欄 anchor 均已對官方頁面實際 `id` 核對）

### 初始化與環境

> 參考：[LIFF SDK reference](https://developers.line.biz/en/reference/liff/)

| 方法 / 屬性 | 用途 | Ref |
|------------|------|-----|
| `liff.init()` | 初始化 LIFF app，並向 LINE 平台取得使用者 token（登入態下會拿到 access token / ID token）。 | [#initialize-liff-app](https://developers.line.biz/en/reference/liff/#initialize-liff-app) |
| `liff.ready` | Promise，`liff.init()` 第一次完成後 resolve。 | [#ready](https://developers.line.biz/en/reference/liff/#ready) |
| `liff.id` | 取得初始化時帶入的 LIFF app ID。 | [#id](https://developers.line.biz/en/reference/liff/#id) |
| `liff.getOS()` | 取得執行環境（`ios` / `android` / `web`）。 | [#get-os](https://developers.line.biz/en/reference/liff/#get-os) |
| `liff.getVersion()` | 取得 LIFF SDK 版本。 | [#get-version](https://developers.line.biz/en/reference/liff/#get-version) |
| `liff.getLineVersion()` | 在 LIFF 瀏覽器內取得使用者的 LINE 版本，否則回 `null`。 | [#get-line-version](https://developers.line.biz/en/reference/liff/#get-line-version) |
| `liff.getAppLanguage()` | 取得 LINE App 語系（RFC 5646）。 | [#get-app-language](https://developers.line.biz/en/reference/liff/#get-app-language) |
| `liff.isInClient()` | 判斷是在 LINE 內建（LIFF）瀏覽器，還是外部瀏覽器執行。 | [#is-in-client](https://developers.line.biz/en/reference/liff/#is-in-client) |
| `liff.getContext()` | 取得 context：聊天室型別（utou/group/room/external）、userId、view size 等。 | [#get-context](https://developers.line.biz/en/reference/liff/#get-context) |
| `liff.isApiAvailable()` | 判斷某個 LIFF API 在當前環境是否可用。 | [#is-api-available](https://developers.line.biz/en/reference/liff/#is-api-available) |

### 認證與 Token 🔑

> 參考：[LIFF SDK reference](https://developers.line.biz/en/reference/liff/)

| 方法 | 用途 | 後端關聯 | Ref |
|------|------|---------|-----|
| `liff.login()` | 在外部 / in-app 瀏覽器觸發 LINE Login。 | 🔑 登入後產生 token，後端可驗證 | [#login](https://developers.line.biz/en/reference/liff/#login) |
| `liff.logout()` | 登出使用者。 | — | [#logout](https://developers.line.biz/en/reference/liff/#logout) |
| `liff.isLoggedIn()` | 是否已登入。 | — | [#is-logged-in](https://developers.line.biz/en/reference/liff/#is-logged-in) |
| `liff.getAccessToken()` | 取得 **access token**（有效約 12 小時；關閉 LIFF app 後會被 revoke）。 | 🔑 **後端應驗證** | [#get-access-token](https://developers.line.biz/en/reference/liff/#get-access-token) |
| `liff.getIDToken()` | 取得 **ID token**（JWT，含 profile claim）。 | 🔑 **後端應驗證** | [#get-id-token](https://developers.line.biz/en/reference/liff/#get-id-token) |
| `liff.getDecodedIDToken()` | 取得「前端已解碼」的 ID token payload（displayName、picture、email）。 | ⚠️ 不可當可信來源送後端 | [#get-decoded-id-token](https://developers.line.biz/en/reference/liff/#get-decoded-id-token) |

### Profile 與權限

> 參考：[LIFF SDK reference](https://developers.line.biz/en/reference/liff/)、[Using user profile](https://developers.line.biz/en/docs/liff/using-user-profile/)

| 方法 | 用途 | Ref |
|------|------|-----|
| `liff.getProfile()` | 取得使用者 profile（userId、displayName、pictureUrl、statusMessage）。⚠️ 不可直接送後端當可信資料。 | [#get-profile](https://developers.line.biz/en/reference/liff/#get-profile) |
| `liff.getFriendship()` | 取得使用者與該 channel 綁定的 LINE 官方帳號之好友狀態。 | [#get-friendship](https://developers.line.biz/en/reference/liff/#get-friendship) |
| `liff.requestFriendship()` | 顯示加好友 / 解除封鎖官方帳號的 subwindow。 | [#request-friendship](https://developers.line.biz/en/reference/liff/#request-friendship) |
| `liff.permission.getGrantedAll()` | 取得使用者已授權的 scope 陣列。 | [#permission-get-granted-all](https://developers.line.biz/en/reference/liff/#permission-get-granted-all) |
| `liff.permission.query()` | 查詢某個 scope 是否已授權。 | [#permission-query](https://developers.line.biz/en/reference/liff/#permission-query) |
| `liff.permission.requestAll()` | （LINE MINI App）顯示權限同意畫面。 | [#permission-request-all](https://developers.line.biz/en/reference/liff/#permission-request-all) |

### 訊息與分享 🔑（會用到 access token / scope）

> 參考：[LIFF SDK reference](https://developers.line.biz/en/reference/liff/)

| 方法 | 用途 | Ref |
|------|------|-----|
| `liff.sendMessages()` | 以使用者身分送最多 5 則訊息到當前聊天室（需 `chat_message.write` scope）。 | [#send-messages](https://developers.line.biz/en/reference/liff/#send-messages) |
| `liff.shareTargetPicker()` | 顯示好友 / 群組選擇器，分享開發者預先準備的訊息。 | [#share-target-picker](https://developers.line.biz/en/reference/liff/#share-target-picker) |

### 裝置與導覽

> 參考：[LIFF SDK reference](https://developers.line.biz/en/reference/liff/)

| 方法 | 用途 | Ref |
|------|------|-----|
| `liff.scanCodeV2()` | 啟動 2D code 掃描器，回傳掃描字串（iOS 14.3+/Android/支援 WebRTC 的 web）。 | [#scan-code-v2](https://developers.line.biz/en/reference/liff/#scan-code-v2) |
| `liff.scanCode()` | （已棄用）舊版 2D code 掃描，僅限 Android LIFF 瀏覽器。 | [#scan-code](https://developers.line.biz/en/reference/liff/#scan-code) |
| `liff.openWindow()` | 在 LINE in-app 或外部瀏覽器開啟 URL。 | [#open-window](https://developers.line.biz/en/reference/liff/#open-window) |
| `liff.closeWindow()` | 關閉 LIFF app。 | [#close-window](https://developers.line.biz/en/reference/liff/#close-window) |
| `liff.permanentLink.createUrl()` / `createUrlBy()` / `setExtraQueryParam()` | 產生 / 設定當前或指定頁面的永久連結。 | [#permanent-link-create-url](https://developers.line.biz/en/reference/liff/#permanent-link-create-url) |
| `liff.use()` | 啟用 LIFF API 模組或 plugin。 | [#use](https://developers.line.biz/en/reference/liff/#use) |
| `liff.i18n.setLang()` | 設定顯示語言（RFC 5646）。 | [#i18n-set-lang](https://developers.line.biz/en/reference/liff/#i18n-set-lang) |
| `liff.createShortcutOnHomeScreen()` | （LINE MINI App）將捷徑加到裝置主畫面。 | [#create-shortcut-on-home-screen](https://developers.line.biz/en/reference/liff/#create-shortcut-on-home-screen) |

> **結論**：第 1 節這些全是「前端的事」，Elixir SDK **不需要也無法實作**。
> 唯一與後端有關的是這三個 token 來源：`liff.login()` → `liff.getIDToken()` / `liff.getAccessToken()`。

---

## 2. 後端相關的 LINE Login / OAuth2 endpoints（Elixir SDK 真正能實作的）

所有 endpoint base host：`https://api.line.me`

### 2.1 驗證 ID Token

> 參考：[LINE Login API reference — Verify ID token](https://developers.line.biz/en/reference/line-login/#verify-id-token)（另見 [Verify ID token 文件頁](https://developers.line.biz/en/docs/line-login/verify-id-token/)）

| 項目 | 內容 |
|------|------|
| **Method / Path** | `POST https://api.line.me/oauth2/v2.1/verify` |
| **用途** | 由後端驗證前端送來的 ID token（JWT）是否有效，並安全取得 profile claim。 |
| **認證** | 無需 channel access token；以 `client_id`（channel ID）做為比對。Content-Type: `application/x-www-form-urlencoded`。 |

**Request body 參數：**

| 參數 | 必填 | 說明 |
|------|------|------|
| `id_token` | ✅ | 前端 `liff.getIDToken()` 取得的 ID token |
| `client_id` | ✅ | 預期的 channel ID（你的 LINE Login channel ID） |
| `nonce` | ⛔ 選填 | 預期的 nonce 值（若簽發時有帶） |
| `user_id` | ⛔ 選填 | 預期的 user ID |

**Response body（即驗證通過後的 JWT claims）：**

| 欄位 | 型別 | 說明 |
|------|------|------|
| `iss` | String | 簽發者，固定 `https://access.line.me` |
| `sub` | String | **使用者 ID（= Messaging API 的 userId）** |
| `aud` | String | Channel ID |
| `exp` | Number | 過期時間（UNIX 秒） |
| `iat` | Number | 簽發時間（UNIX 秒） |
| `auth_time` | Number | 使用者認證時間（UNIX 秒） |
| `nonce` | String | 簽發時帶入的 nonce |
| `amr` | Array | 使用者使用的認證方法清單 |
| `name` | String | 顯示名稱（需 `profile` scope） |
| `picture` | String | 頭像 URL（需 `profile` scope） |
| `email` | String | Email（需 **`email` scope**） |

### 2.2 驗證 Access Token

> 參考：[LINE Login API reference — Verify access token](https://developers.line.biz/en/reference/line-login/#verify-access-token)

| 項目 | 內容 |
|------|------|
| **Method / Path** | `GET https://api.line.me/oauth2/v2.1/verify` |
| **用途** | 驗證 access token 是否有效、查詢其 scope 與剩餘效期。 |
| **認證** | 以 query param 帶 access token。 |

**Query 參數：** `access_token`（必填）

**Response：**

| 欄位 | 型別 | 說明 |
|------|------|------|
| `scope` | String | 此 access token 被授予的權限 |
| `client_id` | String | 簽發此 token 的 channel ID |
| `expires_in` | Number | 剩餘有效秒數 |

> 驗證後建議檢查 `client_id` 是否等於自家 channel ID、`expires_in > 0`。

### 2.3 取得 User Profile（LINE Login）

> 參考：[LINE Login API reference — Get user profile](https://developers.line.biz/en/reference/line-login/#get-user-profile)

| 項目 | 內容 |
|------|------|
| **Method / Path** | `GET https://api.line.me/v2/profile` |
| **用途** | 用 access token 向 LINE 取得使用者 profile（後端可信來源）。 |
| **認證** | Header `Authorization: Bearer {access token}` |

**Response：**

| 欄位 | 說明 |
|------|------|
| `userId` | 使用者 ID（= Messaging API userId） |
| `displayName` | 顯示名稱 |
| `pictureUrl` | 頭像 URL（HTTPS） |
| `statusMessage` | 狀態訊息 |

### 2.4 LIFF App 管理 API（LIFF server API）

> 參考：[LIFF server API reference](https://developers.line.biz/en/reference/liff-server/)

| 項目 | 內容 |
|------|------|
| **認證（全部）** | Header `Authorization: Bearer {channel access token}`（LINE Login channel 的 channel access token） |
| **base** | `https://api.line.me/liff/v1/apps` |
| **限制** | 每個 channel 最多 30 個 LIFF app |

| 操作 | Method | Path | 用途 | Ref |
|------|--------|------|------|-----|
| **Add** | `POST` | `/liff/v1/apps` | 新增一個 LIFF app，回傳 `liffId` | [#add-liff-app](https://developers.line.biz/en/reference/liff-server/#add-liff-app) |
| **Get all** | `GET` | `/liff/v1/apps` | 取得 channel 下所有 LIFF apps | [#get-all-liff-apps](https://developers.line.biz/en/reference/liff-server/#get-all-liff-apps) |
| **Update** | `PUT` | `/liff/v1/apps/{liffId}` | 更新設定（所有欄位皆選填，部分更新） | [#update-liff-app](https://developers.line.biz/en/reference/liff-server/#update-liff-app) |
| **Delete** | `DELETE` | `/liff/v1/apps/{liffId}` | 刪除 LIFF app | [#delete-liff-app](https://developers.line.biz/en/reference/liff-server/#delete-liff-app) |

**Add / Update request body 主要欄位：**

| 欄位 | 必填(Add) | 說明 |
|------|-----------|------|
| `view.type` | ✅ | `compact` / `tall` / `full` |
| `view.url` | ✅ | HTTPS endpoint URL |
| `view.moduleMode` | ⛔ | 是否 module mode（boolean） |
| `description` | ⛔ | LIFF app 名稱 |
| `features.qrCode` | ⛔ | 是否啟用 2D code reader（boolean） |
| `permanentLinkPattern` | ⛔ | `concat` |
| `scope` | ⛔ | 陣列：`openid` / `email` / `profile` / `chat_message.write` |
| `botPrompt` | ⛔ | `normal` / `aggressive` / `none` |

**Get all response** 每個 app 物件包含：`liffId`、`view`(type/url/moduleMode)、`description`、`features`(ble/qrCode)、`permanentLinkPattern`、`scope`、`botPrompt`。

---

## 3. ID Token / Access Token 說明

> 參考：
> - [Verify ID token（docs）](https://developers.line.biz/en/docs/line-login/verify-id-token/) — 含 [payload claims](https://developers.line.biz/en/docs/line-login/verify-id-token/#payload) / [signature 驗簽](https://developers.line.biz/en/docs/line-login/verify-id-token/#signature)
> - [LINE Login API reference — Verify ID token](https://developers.line.biz/en/reference/line-login/#verify-id-token)
> - [LINE Login API reference — Verify access token](https://developers.line.biz/en/reference/line-login/#verify-access-token)

### 3.1 ID Token（JWT，OpenID Connect）

**結構**：三段 base64url（以 `.` 分隔）：

1. **Header** — `alg`（簽章演算法）、`typ` = `"JWT"`、選填 `kid`
2. **Payload** — claims（見 2.1 response 表）
3. **Signature** — 防竄改簽章

**簽章演算法**：
- **ES256**（ECDSA P-256 / SHA-256）：native app、LINE SDK、**LIFF app** 使用
- **HS256**（HMAC SHA-256）：web login 使用

**驗證該做的檢查**（若自行驗，否則交給 `/oauth2/v2.1/verify`）：
- `iss` 必須 = `https://access.line.me`
- `aud` 必須 = 自家 channel ID
- `exp` 不可過期
- `nonce` 必須符合送出授權請求時的值（若有）

> **官方建議**：直接 POST 到 `/oauth2/v2.1/verify`，由 LINE server-side 驗簽並回傳 claims，**不需自己實作驗簽邏輯**（尤其 ES256 + JWKS 較繁瑣）。Elixir SDK 兩種都可提供，但 verify endpoint 是最穩的預設路徑。

**Scope 與 claim 關係：**
- `openid` → 才能拿到 ID token
- `profile` → `name` / `picture`
- `email` → `email` claim

### 3.2 Access Token

- 由 `liff.getAccessToken()` 取得，有效約 **12 小時**，**關閉 LIFF app 後即被 revoke**。
- 後端用途：`GET /oauth2/v2.1/verify`（查 scope/效期）+ `GET /v2/profile`（取 profile）。

### 3.3 與 Messaging API 的 userId 關係

- ID token 的 **`sub`** claim、`/v2/profile` 的 **`userId`**，**就是 Messaging API 使用的 userId**。
- 因此後端驗證 LIFF token 後拿到的 `sub` / `userId`，可直接拿去 Messaging API 推播（push message）給該使用者。
- **注意**：userId 是 **per-channel provider 範圍**一致；同一 provider 下 LINE Login channel 與 Messaging API channel 的 userId 一致，跨 provider 則不同。

---

## 4. 建議 SDK 該封裝哪些

### 4.1 不負責（前端 JS 的事，Elixir 無從實作）

- `liff.init` / `login` / `logout` / `isLoggedIn`
- `liff.getProfile` / `getDecodedIDToken`（前端解碼，不可信）
- `liff.sendMessages` / `shareTargetPicker` / `openWindow` / `scanCodeV2` / `getContext` 等所有 UI / 裝置 / 訊息互動
- → SDK 文件可附一句說明：「這些在瀏覽器以 `@line/liff` 完成，後端只會收到下面的 token」。

### 4.2 後端應封裝（Elixir SDK 真正的價值）

| 模組（建議） | 封裝內容 |
|--------------|----------|
| **`LineLiff.IdToken`** | `verify/2`（POST `/oauth2/v2.1/verify`，帶 `id_token` + `client_id`，選填 `nonce` / `user_id`），回傳結構化 claims（含 `sub`/`name`/`picture`/`email`）。可選提供 local JWT 驗簽（ES256 + JWKS）作為進階模式。 |
| **`LineLiff.AccessToken`** | `verify/1`（GET `/oauth2/v2.1/verify`），回傳 `scope` / `client_id` / `expires_in`；提供 `valid?/1`、scope 檢查 helper。 |
| **`LineLiff.Profile`** | `get/1`（GET `/v2/profile`，Bearer access token），回傳 `userId` / `displayName` / `pictureUrl` / `statusMessage`。 |
| **`LineLiff.Apps`**（管理 API） | `list/1`、`create/2`、`update/3`、`delete/2`（`/liff/v1/apps`，Bearer **channel access token**）。 |
| **`LineLiff.Client`**（共用） | HTTP client、base URL、channel ID / channel access token 設定、錯誤處理、回應反序列化。 |

### 4.3 模組切分原則

- **依「認證方式」切**：
  - ID token / access token verify → 不需 channel access token（以 channel ID 比對）
  - Profile → 需使用者 access token（Bearer）
  - Apps 管理 → 需 **channel access token**（Bearer）
- **Plug / Phoenix helper（加分）**：提供一個 `verify_id_token` 的 plug，從 request header 取 token、呼叫 `LineLiff.IdToken.verify`、把驗證後的 `sub`(userId) 放進 `conn.assigns`，作為後端 session 建立的入口。
- **與 Messaging API 串接**：`sub` / `userId` 可直接餵給既有的 LINE Messaging API SDK 推播，建議在文件標明此一致性。

---

## 重點摘要

1. **LIFF 絕大部分是前端 JS（`@line/liff`）**，Elixir 後端不負責也無法實作那些 UI / 裝置 / 訊息方法。
2. **後端能做的只有 3 類**：token 驗證（ID/access）、取 profile、LIFF app 管理 CRUD。
3. **三個關鍵 endpoint**：`POST /oauth2/v2.1/verify`（ID token）、`GET /oauth2/v2.1/verify`（access token）、`GET /v2/profile`；外加 `/liff/v1/apps`（需 channel access token）。
4. **`sub` / `userId` = Messaging API 的 userId**，驗證後可直接推播。
5. **安全鐵則**：前端解碼的 profile 不可信，後端只信任「自己向 LINE 驗證過的 token」。
6. **建議模組**：`IdToken` / `AccessToken` / `Profile` / `Apps` / `Client`，並依「需不需要 channel access token」切分。
