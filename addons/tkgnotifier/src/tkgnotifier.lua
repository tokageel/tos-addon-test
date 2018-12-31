---
-- 何かを通知してくれるアドオン.
-- APIバージョン: 1

---
-- 通知ウィンドウに表示する情報.
-- @table TKGNOTIFIER_NOTIFICATION
TKGNOTIFIER_NOTIFICATION = {
  icon, -- string: 表示するアイコンの名称.
  -- 未指定またはnilを指定した場合はデフォルトのアイコンが使用される.
  message, -- string: 表示するメッセージ.
  -- 未指定またはnilを指定した場合は空文字列が使用される.
  kind, -- string: 通知種別.
  -- 同一の通知種別の通知がスタック上に存在する場合、後発の通知で上書きする.
  -- 未指定またはnilを指定した場合は、それぞれを個別の通知として扱う.
  action -- string: 通知を閉じた際のコールバック関数名.
  -- 未指定またはnilを指定した場合はコールバックしない.
  -- 同一の通知種別による通知で通知が上書きされた場合、先発の通知に対するコールバックは呼び出さない.
  -- コールバック関数内から通知スタックを操作する関数は呼び出さないこと.
}

---
-- @local
-- 通知トリガーの列挙.
-- @table TKGNOTIFIER_ENUM_TRIGGER
TKGNOTIFIER_ENUM_TRIGGER = {
  none = 0, -- number: 通知なし.
  onLogined = 1, -- number: ログイン時に通知.
  onCharacterChanged = 2, -- number: ログイン時、キャラクター切替時に通知.
  onMapTransited = 3, -- number: ログイン時、キャラクター切替時、マップ移動時に通知.
  onChannelChanged = 4, -- number: ログイン時、キャラクター切替時、マップ移動時、チャンネル切り替え時に通知.
}

---
-- @local
-- アドオン概要.
-- @field name アドオン名.
-- @field author 作者名.
-- @field version バージョン.
-- @field apiVersion APIバージョン.
-- @table Addon
local Addon = {
  name = "TKGNOTIFIER",
  author = "TOKAGEEL",
  version = "1.0.0",
  apiVersion = 1
}

-- グローバルスコープへの格納.
_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][Addon.author] = _G["ADDONS"][Addon.author] or {}
_G["ADDONS"][Addon.author][Addon.name] = _G["ADDONS"][Addon.author][Addon.name] or {}
local g = _G["ADDONS"][Addon.author][Addon.name]
-- デバッグ機能の有無.
local debugIsEnabled = false
-- 最後に確認したサーバID.
local lastServerId
-- 最後に確認したキャラクター名.
local lastPcName
-- 最後に確認したマップ名.
local lastMapName
-- 通知スタック.
local stack = {}

---
-- @local
-- 指定した文字列をシステムログとしてチャットウィンドウへ出力する.
-- @param message 出力する文字列.
local function log(message)
  if debugIsEnabled then
    CHAT_SYSTEM(string.format("[TKGNOTIFIER] %s", tostring(message)), "616161")
  end
end

---
-- @local
-- このアドオンのバージョン情報をシステムメッセージとして出力する.
function TKGNOTIFIER_PRINT_VERSION()
  CHAT_SYSTEM(string.format("%s - v%s", Addon.name, tostring(Addon.version)), "616161")
end

---
-- APIのバージョンを返す.
-- @return APIバージョン（number）.
function TKGNOTIFIER_GET_API_VERSION()
  log("TKGNOTIFIER_GET_API_VERSION")
  return Addon.apiVersion
end

---
-- 指定した内容の通知ウィンドウを表示する.
-- @param notification 表示する通知の内容（TKGNOTIFIER_NOTIFICATION）.
-- @see TKGNOTIFIER_NOTIFICATION
function TKGNOTIFIER_NOTIFY(notification)
  log("TKGNOTIFIER_NOTIFY")
  if (type(notification) ~= "table") then
    log("notification is not table")
    return
  end

  local theNotification = TKGNOTIFIER_CREATE_VALID_NOTIFICATION(notification)

  -- 同一種別の通知をスタックから取り除く
  if (theNotification.kind ~= nil) then
    for index, noti in pairs(stack) do
      if (theNotification.kind == noti.kind) then
        table.remove(stack, index)
        break
      end
    end
  end

  table.insert(stack, theNotification)
  TKGNOTIFIER_FRAME_ON_STACK_CHANGED(stack)
end

---
-- @local
-- 指定したNotificationから使用可能な形に補正したNotificationを生成して返す.
-- @param notification 元となる通知（TKGNOTIFIER_NOTIFICATION）.
-- @return 通知可能な状態に修正したNotification.
-- @see TKGNOTIFIER_NOTIFICATION
function TKGNOTIFIER_CREATE_VALID_NOTIFICATION(notification)
  local theNotification = {}
  -- アイコン
  if (type(notification.icon) == "string") then
    theNotification.icon = notification.icon
  else
    -- 指定が不正な場合は適当なアイコンを設定
    theNotification.icon = "news_btn"
  end
  -- メッセージ
  theNotification.message = tostring(notification.message)
  -- 種別
  if (type(notification.kind) == "string") then
    theNotification.kind = notification.kind
  end
  -- アクション
  if (type(notification.action) == "string") then
    theNotification.action = notification.action
  end
  return theNotification
end

---
-- 直近の通知を削除する.
-- 削除した通知がコールバック関数を指定されている場合、コールバック関数を呼び出す.
function TKGNOIFIER_POP()
  log("TKGNOTIFIER_POP")
  local action
  if #stack > 0 then
    local notification = stack[#stack]
    if (notification.action ~= nil) then
      action = notification.action
    end
    table.remove(stack)
    TKGNOTIFIER_FRAME_ON_STACK_CHANGED(stack)
  end
  if (action ~= nil) then
    log("callback " .. action)
    pcall(loadstring(action))
  end
end

---
-- @local
-- 指定したロケールに対応するリソースをリソーステーブルから探して返す.
-- @param resources リソーステーブル. 少なくともENロケール用のリソースを含むこと.
-- @param locale ロケール.
-- @return 指定したロケールに対応するリソース. そのようなロケールが存在しなかった場合、ENロケール用のリソース.
function TKGNOTIFIER_GET_RESOURCE(resources, locale)
  for k, v in pairs(resources) do
    if locale == k then
      return v
    end
  end
  return resources["EN"]
end

---
-- @local
-- 呼び出しタイミングから通知トリガーを同定する.
-- @return 通知トリガー.
-- @see TKGNOTIFIER_ENUM_TRIGGER
function TKGNOTIFIER_DICIDE_TRIGGER()
  log("TKGNOTIFIER_DICIDE_TRIGGER")
  local trigger
  local pcName = GETMYPCNAME()
  local mapName = session.GetMapName()
  local serverId = GetServerGroupID()
  if (lastServerId ~= serverId) or (lastPcName == nil) then
    trigger = TKGNOTIFIER_ENUM_TRIGGER.onLogined
  elseif (lastPcName == pcName) then
    if (lastMapName == mapName) then
      trigger = TKGNOTIFIER_ENUM_TRIGGER.onChannelChanged
    else
      trigger = TKGNOTIFIER_ENUM_TRIGGER.onMapTransited
    end
  else
    trigger = TKGNOTIFIER_ENUM_TRIGGER.onCharacterChanged
  end
  lastServerId = serverId
  lastPcName = pcName
  lastMapName = mapName
  return trigger
end

---
-- @local
-- アドオン初期化処理.
-- フレームワークからの呼び出しを期待しているため、直接呼び出さないこと.
-- @param addon アドオン.
-- @param frame アドオンのフレーム.
function TKGNOTIFIER_ON_INIT(addon, frame)
  log("TKGNOTIFIER_ON_INIT")
  g.addon = addon
  g.frame = frame

  -- 設定読み込み
  if not g.loaded then
    -- デフォルト設定
    g.settings = {
      locale = "JP",
      mail = {
        trigger = TKGNOTIFIER_ENUM_TRIGGER.onLogined,
        threshold_day = 7
      },
      medal = {
        trigger = TKGNOTIFIER_ENUM_TRIGGER.onLogined,
        threshold = 5
      },
      item = {
        trigger = TKGNOTIFIER_ENUM_TRIGGER.onCharacterChanged,
        threshold_day = 1
      }
    }
    log("loadJSON")
    local settingsFilePath = string.format("../addons/%s/settings.json", string.lower(Addon.name))

    local acutil = require("acutil")
    local settings, err = acutil.loadJSON(settingsFilePath, g.settings)
    if not err then
      -- マージした設定値の検証
      debugIsEnabled = settings and settings.debug and settings.debug.enable
      local validate = function(val, min, max)
        return math.max(min, math.min(max, val))
      end
      settings.mail.trigger = validate(settings.mail.trigger, 0, 4)
      settings.mail.threshold_day = math.max(1, settings.mail.threshold_day)
      settings.item.trigger = validate(settings.item.trigger, 0, 4)
      settings.item.threshold_day = math.max(1, settings.item.threshold_day)
      settings.medal.trigger = validate(settings.medal.trigger, 0, 4)
      settings.medal.threshold = validate(settings.medal.threshold, 1, 5)
      g.settings = settings
    else
      log(tostring(err))
    end
    TKGNOTIFIER_PRINT_VERSION()
  end

  -- 関連機能へ設定値を通知
  local trigger = TKGNOTIFIER_DICIDE_TRIGGER()
  TKGNOTIFIER_SETTINGS_INIT(g.settings)
  TKGNOTIFIER_FRAME_INIT(g.settings, trigger)
  TKGNOTIFIER_MEDAL_INIT(g.settings, trigger)
  TKGNOTIFIER_ITEM_INIT(g.settings, trigger)
  TKGNOTIFIER_MAIL_INIT(g.settings, trigger)

  if (#stack > 0) then
    TKGNOTIFIER_FRAME_ON_STACK_CHANGED(stack)
  end

  g.loaded = true
end
