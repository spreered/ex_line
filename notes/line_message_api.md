# LINE Messaging API — SDK 功能盤點 (Elixir hex package 規劃用)

> 來源：
> - Overview: <https://developers.line.biz/en/docs/messaging-api/>
> - API Reference: <https://developers.line.biz/en/reference/messaging-api/>
>
> 視角：站在「要做 Elixir SDK」的人，聚焦在 SDK 該封裝的東西。
> Base URL：`https://api.line.me`（多數 endpoint） / `https://api-data.line.me`（content 下載 / image 上傳等資料型 endpoint）。

---

## 0. 常用度標記說明

- **核心**：任何 bot 都會用到，SDK 第一階段必做。
- **進階**：行銷、統計、rich menu 等，第二階段。
- **少用**：特定情境（beacon、coupon、membership、audience 細項）。

---

## 1. API Endpoints 清單（依功能分組）

> 認證欄：**Token** = Channel Access Token（`Authorization: Bearer <token>`）；**Secret** = Channel Secret（webhook 設定類）；**ID+Secret** = Channel ID + Channel Secret（發 token 用）。

### 1.1 Send messages（發送訊息）— 核心

> 參考：[Send reply message](https://developers.line.biz/en/reference/messaging-api/#send-reply-message) ｜ [Send push message](https://developers.line.biz/en/reference/messaging-api/#send-push-message) ｜ [Send multicast message](https://developers.line.biz/en/reference/messaging-api/#send-multicast-message) ｜ [Send narrowcast message](https://developers.line.biz/en/reference/messaging-api/#send-narrowcast-message) ｜ [Get narrowcast progress](https://developers.line.biz/en/reference/messaging-api/#get-narrowcast-progress-status) ｜ [Send broadcast message](https://developers.line.biz/en/reference/messaging-api/#send-broadcast-message) ｜ [Mark as read](https://developers.line.biz/en/reference/messaging-api/#mark-as-read) ｜ [Display a loading indicator](https://developers.line.biz/en/reference/messaging-api/#display-a-loading-indicator)

| Method | Path | 用途 | 認證 | 常用度 |
|---|---|---|---|---|
| POST | `/v2/bot/message/reply` | 用 replyToken 回覆訊息 | Token | 核心 |
| POST | `/v2/bot/message/push` | 主動推送給單一使用者 | Token | 核心 |
| POST | `/v2/bot/message/multicast` | 推送給多位指定 userId（同內容） | Token | 核心 |
| POST | `/v2/bot/message/narrowcast` | 依屬性/受眾條件投放 | Token | 進階 |
| POST | `/v2/bot/message/broadcast` | 推送給所有好友 | Token | 進階 |
| GET | `/v2/bot/message/narrowcast/progress/status` | 查 narrowcast 投放進度 | Token | 進階 |
| POST | `/v2/bot/message/push/mark-as-read` | 將訊息標記為已讀 | Token | 少用 |
| POST | `/v2/bot/message/push/loading-indicator` | 顯示輸入中載入動畫 | Token | 進階 |

### 1.2 Message validation（送出前驗證訊息物件）— 進階

> 參考：[Validate reply](https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-reply-message) ｜ [Validate push](https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-push-message) ｜ [Validate multicast](https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-multicast-message) ｜ [Validate narrowcast](https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-narrowcast-message) ｜ [Validate broadcast](https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-broadcast-message)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/message/validate/reply` | 驗證 reply 訊息物件 | Token |
| POST | `/v2/bot/message/validate/push` | 驗證 push 訊息物件 | Token |
| POST | `/v2/bot/message/validate/multicast` | 驗證 multicast 訊息物件 | Token |
| POST | `/v2/bot/message/validate/narrowcast` | 驗證 narrowcast 訊息物件 | Token |
| POST | `/v2/bot/message/validate/broadcast` | 驗證 broadcast 訊息物件 | Token |

### 1.3 Quota / Sent count（用量與統計）— 進階

> 參考：[Get quota](https://developers.line.biz/en/reference/messaging-api/#get-quota) ｜ [Get consumption](https://developers.line.biz/en/reference/messaging-api/#get-consumption) ｜ [Get number of reply messages](https://developers.line.biz/en/reference/messaging-api/#get-number-of-reply-messages) ｜ [Get number of push messages](https://developers.line.biz/en/reference/messaging-api/#get-number-of-push-messages) ｜ [Get number of multicast messages](https://developers.line.biz/en/reference/messaging-api/#get-number-of-multicast-messages) ｜ [Get number of broadcast messages](https://developers.line.biz/en/reference/messaging-api/#get-number-of-broadcast-messages)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/message/quota` | 取得當月訊息目標上限 | Token |
| GET | `/v2/bot/message/quota/consumption` | 取得當月已發送數 | Token |
| GET | `/v2/bot/message/reply/count` | reply 訊息數 | Token |
| GET | `/v2/bot/message/push/count` | push 訊息數 | Token |
| GET | `/v2/bot/message/multicast/count` | multicast 訊息數 | Token |
| GET | `/v2/bot/message/broadcast/count` | broadcast 訊息數 | Token |

### 1.4 Get content（取得使用者送來的內容 / 媒體）— 核心

> 走 `https://api-data.line.me`。
>
> 參考：[Get content](https://developers.line.biz/en/reference/messaging-api/#get-content) ｜ [Verify video or audio preparation status](https://developers.line.biz/en/reference/messaging-api/#verify-video-or-audio-preparation-status) ｜ [Get image or video preview](https://developers.line.biz/en/reference/messaging-api/#get-image-or-video-preview)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/message/{messageId}/content` | 下載使用者送來的圖片/影片/檔案 | Token |
| GET | `/v2/bot/message/{messageId}/content/transcoding/status` | 查媒體轉檔/準備狀態 | Token |
| GET | `/v2/bot/message/{messageId}/content/preview` | 取得圖片/影片預覽圖 | Token |

### 1.5 Webhook settings（webhook 端點設定）— 核心

> 注意：這幾個是少數用 **Channel Secret** 認證的 endpoint。
>
> 參考：[Set webhook endpoint URL](https://developers.line.biz/en/reference/messaging-api/#set-webhook-endpoint-url) ｜ [Get webhook endpoint information](https://developers.line.biz/en/reference/messaging-api/#get-webhook-endpoint-information) ｜ [Test webhook endpoint](https://developers.line.biz/en/reference/messaging-api/#test-webhook-endpoint)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| PUT | `/v2/bot/channel/webhook/endpoint` | 設定 webhook URL | Secret |
| GET | `/v2/bot/channel/webhook/endpoint` | 取得 webhook URL 資訊 | Secret |
| POST | `/v2/bot/channel/webhook/test` | 測試 webhook 端點是否可達 | Secret |

### 1.6 Channel access token 管理（認證）— 核心

> 參考：[Issue channel access token v2.1](https://developers.line.biz/en/reference/messaging-api/#issue-channel-access-token-v2-1) ｜ [Verify v2.1 token](https://developers.line.biz/en/reference/messaging-api/#verify-channel-access-token-v2-1) ｜ [Get all valid v2.1 key IDs](https://developers.line.biz/en/reference/messaging-api/#get-all-valid-channel-access-token-key-ids-v2-1) ｜ [Revoke v2.1 token](https://developers.line.biz/en/reference/messaging-api/#revoke-channel-access-token-v2-1) ｜ [Issue stateless token](https://developers.line.biz/en/reference/messaging-api/#issue-stateless-channel-access-token) ｜ [Issue short-lived token](https://developers.line.biz/en/reference/messaging-api/#issue-shortlived-channel-access-token) ｜ [Verify short-/long-lived token](https://developers.line.biz/en/reference/messaging-api/#verify-channel-access-token) ｜ [Revoke short-/long-lived token](https://developers.line.biz/en/reference/messaging-api/#revoke-longlived-or-shortlived-channel-access-token)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/oauth/accessToken` | 發行 v2.1 token（JWT-based, 30 天） | ID+Secret (JWT) |
| GET | `/v2/oauth/verify` | 驗證 v2.1 token | Token |
| GET | `/v2/oauth/accessToken/key/ids` | 取得所有有效 v2.1 key ID | Token |
| POST | `/v2/oauth/revoke` | 撤銷 v2.1 token | Token |
| POST | `/v2/oauth/accessToken/issue` | 發行 stateless channel access token | ID+Secret |
| POST | `/v2/oauth/accessToken/issue/shortLived` | 發行短效 token | ID+Secret |

> 註：reference 中 `/v2/oauth/verify`、`/v2/oauth/revoke` 同時用於 short-lived/long-lived token 的驗證/撤銷（GET vs POST 依 token 類型）。

### 1.7 Manage audience（受眾管理，narrowcast 用）— 進階/少用

> 參考：[Manage Audience（章節）](https://developers.line.biz/en/reference/messaging-api/#manage-audience-group) ｜ [Create upload audience (JSON)](https://developers.line.biz/en/reference/messaging-api/#create-upload-audience-group) ｜ [Create upload audience (file)](https://developers.line.biz/en/reference/messaging-api/#create-upload-audience-group-by-file) ｜ [Add user IDs (JSON)](https://developers.line.biz/en/reference/messaging-api/#update-upload-audience-group) ｜ [Add user IDs (file)](https://developers.line.biz/en/reference/messaging-api/#update-upload-audience-group-by-file) ｜ [Create click audience](https://developers.line.biz/en/reference/messaging-api/#create-click-audience-group) ｜ [Create imp audience](https://developers.line.biz/en/reference/messaging-api/#create-imp-audience-group) ｜ [Rename audience](https://developers.line.biz/en/reference/messaging-api/#set-description-audience-group) ｜ [Delete audience](https://developers.line.biz/en/reference/messaging-api/#delete-audience-group) ｜ [Get audience](https://developers.line.biz/en/reference/messaging-api/#get-audience-group) ｜ [Get audiences](https://developers.line.biz/en/reference/messaging-api/#get-audience-groups) ｜ [Get shared audience](https://developers.line.biz/en/reference/messaging-api/#get-shared-audience) ｜ [Get shared audience list](https://developers.line.biz/en/reference/messaging-api/#get-shared-audience-list)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/audience` | 建立 upload audience（JSON 傳 userId） | Token |
| POST | `/v2/bot/audience/upload` | 建立 upload audience（檔案上傳） | Token |
| PUT | `/v2/bot/audience/{audienceId}` | 追加 userId（JSON） | Token |
| PUT | `/v2/bot/audience/{audienceId}/update` | 追加 userId（檔案） | Token |
| POST | `/v2/bot/audience/click` | 建立 click audience | Token |
| POST | `/v2/bot/audience/imp` | 建立 impression audience | Token |
| PUT | `/v2/bot/audience/{audienceId}/description` | 改名 audience | Token |
| DELETE | `/v2/bot/audience/{audienceId}` | 刪除 audience | Token |
| GET | `/v2/bot/audience/{audienceId}` | 取得單一 audience | Token |
| GET | `/v2/bot/audiences` | 取得多個 audience | Token |
| GET | `/v2/bot/audience/shared/{sharedAudienceId}` | 取得共享 audience | Token |
| GET | `/v2/bot/audience/shared` | 共享 audience 清單 | Token |

### 1.8 Insight（統計分析）— 進階

> 參考：[Get number of message deliveries](https://developers.line.biz/en/reference/messaging-api/#get-number-of-delivery-messages) ｜ [Get number of followers](https://developers.line.biz/en/reference/messaging-api/#get-number-of-followers) ｜ [Get demographic](https://developers.line.biz/en/reference/messaging-api/#get-demographic) ｜ [Get message event](https://developers.line.biz/en/reference/messaging-api/#get-message-event) ｜ [Get statistics per unit](https://developers.line.biz/en/reference/messaging-api/#get-statistics-per-unit) ｜ [Get number of unit name types](https://developers.line.biz/en/reference/messaging-api/#get-the-number-of-unit-name-types-assigned-during-this-month) ｜ [Get list of unit names](https://developers.line.biz/en/reference/messaging-api/#get-a-list-of-unit-names-assigned-during-this-month)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/insight/message/delivery` | 訊息送達數 | Token |
| GET | `/v2/bot/insight/followers` | 好友數 | Token |
| GET | `/v2/bot/insight/demographic` | 好友屬性分布 | Token |
| GET | `/v2/bot/insight/message/event` | 訊息互動統計（點擊等） | Token |
| GET | `/v2/bot/insight/statistics` | 依 unit 的統計 | Token |
| GET | `/v2/bot/insight/unit/count` | 當月 unit 名稱類型數 | Token |
| GET | `/v2/bot/insight/unit` | 當月 unit 名稱 | Token |

### 1.9 Users（使用者）— 核心

> 參考：[Get profile](https://developers.line.biz/en/reference/messaging-api/#get-profile) ｜ [Get follower IDs](https://developers.line.biz/en/reference/messaging-api/#get-follower-ids)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/profile/{userId}` | 取得使用者 profile | Token |
| GET | `/v2/bot/followers/ids` | 取得好友 userId 列表（分頁） | Token |

### 1.10 Bot info（帳號資訊）— 核心

> 參考：[Get bot info](https://developers.line.biz/en/reference/messaging-api/#get-bot-info)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/info` | 取得 bot/官方帳號資訊 | Token |

### 1.11 Group / Room 管理 — 進階

> 參考：[Get group summary](https://developers.line.biz/en/reference/messaging-api/#get-group-summary) ｜ [Get number of users in group](https://developers.line.biz/en/reference/messaging-api/#get-members-group-count) ｜ [Get group member user IDs](https://developers.line.biz/en/reference/messaging-api/#get-group-member-user-ids) ｜ [Get group member profile](https://developers.line.biz/en/reference/messaging-api/#get-group-member-profile) ｜ [Leave group](https://developers.line.biz/en/reference/messaging-api/#leave-group) ｜ [Get number of users in room](https://developers.line.biz/en/reference/messaging-api/#get-members-room-count) ｜ [Get room member user IDs](https://developers.line.biz/en/reference/messaging-api/#get-room-member-user-ids) ｜ [Leave room](https://developers.line.biz/en/reference/messaging-api/#leave-room)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/group/{groupId}/summary` | 群組摘要（名稱/圖示） | Token |
| GET | `/v2/bot/group/{groupId}/members/count` | 群組成員數 | Token |
| GET | `/v2/bot/group/{groupId}/members/ids` | 群組成員 userId | Token |
| GET | `/v2/bot/group/{groupId}/members/{userId}` | 群組成員 profile | Token |
| POST | `/v2/bot/group/{groupId}/leave` | 離開群組 | Token |
| GET | `/v2/bot/room/{roomId}/members/count` | 多人聊天室成員數 | Token |
| GET | `/v2/bot/room/{roomId}/members/ids` | 聊天室成員 userId | Token |
| GET | `/v2/bot/room/{roomId}/members/{userId}` | 聊天室成員 profile | Token |
| POST | `/v2/bot/room/{roomId}/leave` | 離開聊天室 | Token |

### 1.12 Rich menu — 進階

> 參考：[Rich menu（章節）](https://developers.line.biz/en/reference/messaging-api/#rich-menu) ｜ [Create rich menu](https://developers.line.biz/en/reference/messaging-api/#create-rich-menu) ｜ [Validate rich menu object](https://developers.line.biz/en/reference/messaging-api/#validate-rich-menu-object) ｜ [Upload rich menu image](https://developers.line.biz/en/reference/messaging-api/#upload-rich-menu-image) ｜ [Download rich menu image](https://developers.line.biz/en/reference/messaging-api/#download-rich-menu-image) ｜ [Get rich menu list](https://developers.line.biz/en/reference/messaging-api/#get-rich-menu-list) ｜ [Get rich menu](https://developers.line.biz/en/reference/messaging-api/#get-rich-menu) ｜ [Delete rich menu](https://developers.line.biz/en/reference/messaging-api/#delete-rich-menu) ｜ [Set default rich menu](https://developers.line.biz/en/reference/messaging-api/#set-default-rich-menu)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/richmenu` | 建立 rich menu | Token |
| POST | `/v2/bot/richmenu/validate` | 驗證 rich menu 物件 | Token |
| POST | `/v2/bot/richmenu/{richMenuId}/content` | 上傳 rich menu 圖片（api-data） | Token |
| GET | `/v2/bot/richmenu/{richMenuId}/content` | 下載 rich menu 圖片（api-data） | Token |
| GET | `/v2/bot/richmenu/list` | rich menu 清單 | Token |
| GET | `/v2/bot/richmenu/{richMenuId}` | rich menu 詳情 | Token |
| DELETE | `/v2/bot/richmenu/{richMenuId}` | 刪除 rich menu | Token |
| POST | `/v2/bot/richmenu/default` | 設定預設 rich menu | Token |
| GET | `/v2/bot/richmenu/default` | 取得預設 rich menu ID | Token |
| DELETE | `/v2/bot/richmenu/default` | 清除預設 rich menu | Token |

#### Per-user rich menu

> 參考：[Link rich menu to user](https://developers.line.biz/en/reference/messaging-api/#link-rich-menu-to-user) ｜ [Batch control rich menus of users](https://developers.line.biz/en/reference/messaging-api/#batch-control-rich-menus-of-users)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/richmenu/{richMenuId}/user/{userId}` | 綁定 rich menu 給單一使用者 | Token |
| POST | `/v2/bot/richmenu/bulk/link` | 批次綁定多位使用者 | Token |
| GET | `/v2/bot/user/{userId}/richmenu` | 取得使用者目前 rich menu ID | Token |
| DELETE | `/v2/bot/richmenu/{richMenuId}/user/{userId}` | 解除單一使用者綁定 | Token |
| POST | `/v2/bot/richmenu/bulk/unlink` | 批次解除綁定 | Token |

#### Rich menu alias / batch（tab 切換用）

> 參考：[Rich menu alias](https://developers.line.biz/en/reference/messaging-api/#rich-menu-alias) ｜ [Batch control rich menus of users](https://developers.line.biz/en/reference/messaging-api/#batch-control-rich-menus-of-users)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/richmenu/alias` | 建立 alias | Token |
| POST | `/v2/bot/richmenu/alias/{aliasId}` | 更新 alias | Token |
| DELETE | `/v2/bot/richmenu/alias/{aliasId}` | 刪除 alias | Token |
| GET | `/v2/bot/richmenu/alias/{aliasId}` | 取得 alias | Token |
| GET | `/v2/bot/richmenu/alias/list` | alias 清單 | Token |
| POST | `/v2/bot/richmenu/users/bulk/manage` | 批次切換多位使用者 rich menu | Token |
| GET | `/v2/bot/richmenu/users/bulk/manage` | 批次切換進度 | Token |
| POST | `/v2/bot/richmenu/users/bulk/manage/validate` | 驗證批次切換請求 | Token |

### 1.13 Account Link（帳號連結）— 少用

> 參考：[Issue link token](https://developers.line.biz/en/reference/messaging-api/#issue-link-token)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/user/{userId}/linkToken` | 發行 link token（連結外部帳號） | Token |

### 1.14 Membership（付費會員）— 少用

> 參考：[Membership（章節）](https://developers.line.biz/en/reference/messaging-api/#membership) ｜ [Get a user's membership subscription status](https://developers.line.biz/en/reference/messaging-api/#get-a-users-membership-subscription-status) ｜ [Get membership user IDs](https://developers.line.biz/en/reference/messaging-api/#get-membership-user-ids) ｜ [Get membership plans](https://developers.line.biz/en/reference/messaging-api/#get-membership-plans)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| GET | `/v2/bot/user/{userId}/membership/subscription/status` | 使用者訂閱狀態 | Token |
| GET | `/v2/bot/membership/users` | 會員使用者清單 | Token |
| GET | `/v2/bot/membership/plans` | 會員方案清單 | Token |

### 1.15 Coupon（優惠券）— 少用

> 參考：[Coupons（章節）](https://developers.line.biz/en/reference/messaging-api/#coupons) ｜ [Create coupon](https://developers.line.biz/en/reference/messaging-api/#create-coupon) ｜ [Discontinue coupon](https://developers.line.biz/en/reference/messaging-api/#discontinue-coupon) ｜ [Get coupons list](https://developers.line.biz/en/reference/messaging-api/#get-coupons-list) ｜ [Get coupon](https://developers.line.biz/en/reference/messaging-api/#get-coupon)

| Method | Path | 用途 | 認證 |
|---|---|---|---|
| POST | `/v2/bot/coupon` | 建立 coupon | Token |
| PUT | `/v2/bot/coupon/{couponId}/discontinue` | 停用 coupon | Token |
| GET | `/v2/bot/coupon/list` | coupon 清單 | Token |
| GET | `/v2/bot/coupon/{couponId}` | coupon 詳情 | Token |

---

## 2. Message Objects（訊息物件型別）

所有訊息物件共用：`type`（必填）、`quickReply`（選填）、`sender`（選填，覆寫顯示名稱/頭像）。
單一發送請求最多帶 **5 個** message 物件。

> 參考：[Message objects（章節）](https://developers.line.biz/en/reference/messaging-api/#message-objects)
> ｜ [text](https://developers.line.biz/en/reference/messaging-api/#text-message)
> ｜ [textV2](https://developers.line.biz/en/reference/messaging-api/#text-message-v2)
> ｜ [sticker](https://developers.line.biz/en/reference/messaging-api/#sticker-message)
> ｜ [image](https://developers.line.biz/en/reference/messaging-api/#image-message)
> ｜ [video](https://developers.line.biz/en/reference/messaging-api/#video-message)
> ｜ [audio](https://developers.line.biz/en/reference/messaging-api/#audio-message)
> ｜ [location](https://developers.line.biz/en/reference/messaging-api/#location-message)
> ｜ [imagemap](https://developers.line.biz/en/reference/messaging-api/#imagemap-message)
> ｜ [template（buttons/confirm/carousel/image_carousel 皆在此 anchor 下）](https://developers.line.biz/en/reference/messaging-api/#template-messages)
> ｜ [flex](https://developers.line.biz/en/reference/messaging-api/#flex-message)
>
> Flex 教學/元件：[Flex Message elements](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/) ｜ [Send Flex Messages](https://developers.line.biz/en/docs/messaging-api/using-flex-messages/)
> 訊息型別總覽（docs）：[Message types](https://developers.line.biz/en/docs/messaging-api/message-types/) ｜ Sticker 清單：[Sticker list](https://developers.line.biz/en/docs/messaging-api/sticker-list/)

| Type | 必要欄位 | 重點說明 |
|---|---|---|
| **text** | `type:"text"`, `text` | 文字上限 5000 字；可內嵌 LINE emoji（`emojis` 陣列，含 `index`/`productId`/`emojiId`） |
| **textV2** | `type:"textV2"`, `text` | 新版文字，支援 mention（`substitution` 物件，`{user1}` 佔位）與 emoji |
| **sticker** | `type:"sticker"`, `packageId`, `stickerId` | 官方貼圖 |
| **image** | `type:"image"`, `originalContentUrl`, `previewImageUrl` | HTTPS、JPEG/PNG；原圖 ≤10MB |
| **video** | `type:"video"`, `originalContentUrl`, `previewImageUrl` | 可帶 `trackingId`（搭配 video viewing complete event） |
| **audio** | `type:"audio"`, `originalContentUrl`, `duration` | m4a；duration 毫秒 |
| **location** | `type:"location"`, `title`, `address`, `latitude`, `longitude` | |
| **imagemap** | `type:"imagemap"`, `baseUrl`, `altText`, `baseSize{width,height}`, `actions[]` | 可點擊區塊地圖；actions 為 URI/message action；可選 `video` |
| **template — buttons** | `type:"template"`, `altText`, `template{type:"buttons", text, actions[]}` | 選填 `thumbnailImageUrl`, `title`, `defaultAction` |
| **template — confirm** | `template{type:"confirm", text, actions[2]}` | 兩個 action（是/否） |
| **template — carousel** | `template{type:"carousel", columns[]}` | 每 column 有 `text`/`actions[]`，選填圖、title；最多 10 columns |
| **template — image_carousel** | `template{type:"image_carousel", columns[]}` | 每 column = `imageUrl` + 單一 `action` |
| **flex** | `type:"flex"`, `altText`, `contents` | `contents` 為 bubble 或 carousel；bubble 由 header/hero/body/footer 組成，元件含 box/text/image/button/separator 等 |

> SDK 建議：每種訊息物件提供 builder/struct 與驗證（對應 `/validate/*` endpoint）。

### 2.1 Action objects（按鈕/quick reply 共用）

> 參考：[Action objects（章節）](https://developers.line.biz/en/reference/messaging-api/#action-objects)
> ｜ [postback](https://developers.line.biz/en/reference/messaging-api/#postback-action)
> ｜ [message](https://developers.line.biz/en/reference/messaging-api/#message-action)
> ｜ [uri](https://developers.line.biz/en/reference/messaging-api/#uri-action)
> ｜ [datetimepicker](https://developers.line.biz/en/reference/messaging-api/#datetime-picker-action)
> ｜ [camera](https://developers.line.biz/en/reference/messaging-api/#camera-action)
> ｜ [cameraRoll](https://developers.line.biz/en/reference/messaging-api/#camera-roll-action)
> ｜ [location](https://developers.line.biz/en/reference/messaging-api/#location-action)
> ｜ [richmenuswitch](https://developers.line.biz/en/reference/messaging-api/#richmenu-switch-action)
> ｜ [clipboard](https://developers.line.biz/en/reference/messaging-api/#clipboard-action)

`postback`、`message`、`uri`、`datetimepicker`、`camera`、`cameraRoll`、`location`、`richmenuswitch`、`clipboard`。

---

## 3. 共用概念

### 3.1 認證 — Channel Access Token 種類

> 參考（docs）：[Channel access token（總覽）](https://developers.line.biz/en/docs/basics/channel-access-token/) ｜ [Generate JSON Web Token（v2.1 assertion）](https://developers.line.biz/en/docs/messaging-api/generate-json-web-token/)
> 參考（reference）：[Issue v2.1 token](https://developers.line.biz/en/reference/messaging-api/#issue-channel-access-token-v2-1) ｜ [Issue stateless token](https://developers.line.biz/en/reference/messaging-api/#issue-stateless-channel-access-token) ｜ [Issue short-lived token](https://developers.line.biz/en/reference/messaging-api/#issue-shortlived-channel-access-token)

| 種類 | 取得方式 | 效期 | 適用 |
|---|---|---|---|
| **長期 token (long-lived)** | LINE Developers Console 產生 | 無到期 | 簡單情境（不建議大量使用） |
| **v2.1 token (JWT-based)** | `POST /v2/oauth/accessToken`，用 assertion JWT（以 channel 的 private key 簽 RS256）換取 | 最長 30 天，可多把並存（key ID） | 推薦正式環境，可輪替 |
| **stateless token** | `POST /v2/oauth/accessToken/issue`（channel id+secret，client_credentials） | 15 分鐘 | 不需管理、即發即用 |
| **short-lived token** | `POST /v2/oauth/accessToken/issue/shortLived` | 短效 | 臨時用途 |

> SDK 應抽象「token provider」介面，支援靜態 token 與 v2.1 自動換發/快取/輪替。

### 3.2 Webhook 簽章驗證

> 參考：[Verify webhook signature](https://developers.line.biz/en/docs/messaging-api/verify-webhook-signature/) ｜ [Receiving messages (webhooks)](https://developers.line.biz/en/docs/messaging-api/receiving-messages/)

- Header：`x-line-signature`。
- 演算法：以 **Channel Secret** 為 key，對 **raw request body** 算 **HMAC-SHA256**，Base64 編碼後與 header 比對（須 constant-time 比較）。
- SDK 必做：提供 `verify_signature(body, signature, channel_secret)`，以及 Plug middleware（保留 raw body）。

### 3.3 Webhook event 類型

> 參考：[Webhook Event Objects（reference）](https://developers.line.biz/en/reference/messaging-api/#webhook-event-objects) ｜ [Receiving messages（docs）](https://developers.line.biz/en/docs/messaging-api/receiving-messages/)

`message`、`unsend`、`follow`、`unfollow`、`join`、`leave`、`memberJoined`、`memberLeft`、`postback`、`videoPlayComplete`、`beacon`、`accountLink`、`membership`、`things`（部分舊事件）。

- 共用欄位：`type`、`mode`（active/standby）、`timestamp`、`source`（user/group/room + ID）、`webhookEventId`、`deliveryContext.isRedelivery`、`replyToken`（部分事件）。
- `message` event 內含 message 物件（text/image/video/audio/file/location/sticker），text message 會帶 **quoteToken**。

### 3.4 其他共用機制

> 參考：[Quick reply](https://developers.line.biz/en/docs/messaging-api/using-quick-reply/) ｜ [Retry failed API requests（X-Line-Retry-Key）](https://developers.line.biz/en/docs/messaging-api/retrying-api-request/) ｜ [Send messages（含 sender/quote token 用法）](https://developers.line.biz/en/docs/messaging-api/sending-messages/)

| 概念 | 說明 | SDK 對應 |
|---|---|---|
| **Quick reply** | 訊息底部最多 13 個快速回覆按鈕（`quickReply.items[].action`，可含 image action） | 各 message builder 支援 |
| **Sender** | 覆寫單則訊息的顯示 `name` / `iconUrl` | message 共用欄位 |
| **Quote token** | 由收到的 text/sticker message 取得，發送時放入 `quoteToken` 可引用回覆 | reply/push 參數 |
| **Retry key / Idempotency** | Header `X-Line-Retry-Key`（UUID）；同 key 重送不重複發訊（適用 reply/push/multicast/narrowcast/broadcast） | client 自動產生/可帶入 |
| **Rate limit** | 多數 endpoint 預設 **2,000 req/s**；部分較低：narrowcast/broadcast 60/hr、audience 60/min、multicast 200/s、loading 100/s、richmenu 建立刪除 100/hr、batch 切換 3/hr 等。超限回 **429 Too Many Requests** | client retry/backoff |
| **Error response** | JSON：`{"message": "...", "details": [{"message": "...", "property": "..."}]}`；常見 HTTP 400/401/403/409/429/500 | 統一錯誤型別 |

---

## 4. 建議的 SDK 模組切分

```
Line                         # 入口、版本
├── Line.Client              # HTTP client（base url 切換 api / api-data）、header 注入、retry-key、429 backoff
├── Line.Auth                # token provider 介面
│   ├── Line.Auth.Static     # 靜態長期 token
│   ├── Line.Auth.V2_1       # JWT 換發、key id 管理、撤銷
│   └── Line.Auth.Stateless  # stateless token
├── Line.Message             # message structs + builders（text/sticker/image/.../flex）
│   ├── Line.Message.Flex    # bubble/carousel/box/text/... DSL
│   ├── Line.Message.Template
│   ├── Line.Message.Action  # postback/uri/datetimepicker/...
│   └── Line.Message.QuickReply
├── Line.Api.Message         # reply/push/multicast/narrowcast/broadcast + validate + count + quota
├── Line.Api.Content         # 下載媒體 / preview / transcoding status
├── Line.Api.Profile         # profile / followers
├── Line.Api.Bot             # bot info
├── Line.Api.Group           # group / room 管理
├── Line.Api.RichMenu        # richmenu CRUD / per-user / alias / bulk
├── Line.Api.Audience        # 受眾管理
├── Line.Api.Insight         # 統計
├── Line.Api.Membership      # 會員（少用）
├── Line.Api.Coupon          # 優惠券（少用）
├── Line.Api.AccountLink     # link token
├── Line.Webhook             # event structs + 解析（JSON → struct）
│   ├── Line.Webhook.Signature   # HMAC-SHA256 驗章
│   └── Line.Webhook.Plug        # Phoenix/Plug 整合（raw body + 驗章 + 解析）
└── Line.Error               # 統一錯誤型別
```

### 建議實作優先順序

1. **P0 核心**：`Client` + `Auth.Static` + `Message`（text/sticker/image/template/flex）+ `Api.Message`(reply/push) + `Webhook`(signature + 解析 message/follow/postback) + `Api.Content` + `Api.Profile`。
2. **P1 進階**：multicast/broadcast/narrowcast、quota/count、`Api.RichMenu`、`Api.Bot`、`Api.Group`、`Auth.V2_1`、validate endpoints、quick reply / sender / quote token / retry key。
3. **P2 少用**：`Api.Audience`、`Api.Insight`、`Api.Membership`、`Api.Coupon`、`Api.AccountLink`、beacon/membership webhook events。
