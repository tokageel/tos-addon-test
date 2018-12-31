---
-- 期限付きアイテム通知機能.
-- 期限が近いアイテムが存在する場合に通知する.

-- 期限付きアイテム通知の設定.
local itemSettings
-- デバッグ機能の有無.
local debugIsEnabled = false
-- リソース一覧.
local resources = {
  EN = {
    string = {
      deadline_is_nearling = "%s: After it expired in %.1f days."
    }
  },
  JP = {
    string = {
      deadline_is_nearling = "%s: 使用期限まで%.1f日です。"
    }
  }
}

-- リソース.
local R = resources.JP

---
-- 指定した文字列をシステムログとしてチャットウィンドウへ出力する.
-- @param message 出力する文字列.
local function log(message)
  if debugIsEnabled then
    CHAT_SYSTEM(string.format("[TKGNOTIFIER_ITEM] %s", tostring(message)), "616161")
  end
end

---
-- 呼び出しタイミングと閾値が条件に合う場合、期限切れが近いメールの存在を通知する.
function TKGNOTIFIER_ITEM_NOTIFY_IF_NEEDED(trigger)
  log("TKGNOTIFIER_ITEM_NOTIFY_IF_NEEDED")

  -- 通知タイミングチェック
  log(string.format("trigger=%d (settings=%d)", trigger, itemSettings.trigger))
  if (itemSettings.trigger < trigger) then
    return
  end

  -- 閾値チェック
  local thresholdInSec = itemSettings.threshold_day * 24 * 60 * 60
  local itemList = GET_SCHEDULED_TO_EXPIRED_ITEM_LIST(thresholdInSec)
  if (itemList ~= nil) and (#itemList > 0) then
    itemList = SORT_ITEM_LIST_BY_LIFETIME(itemList)
    for _, item in pairs(itemList) do
      local remainInSec = imcTime.GetDifSec(
        imcTime.GetSysTimeByStr(item.ItemLifeTime),
        geTime.GetServerSystemTime())
      local message = string.format(R.string.deadline_is_nearling, item.Name, remainInSec / 60 / 60 / 24)
      TKGNOTIFIER_NOTIFY({
        icon = item.Icon,
        message = message
      })
    end
  end
end

---
-- 指定した設定値を使用して設定を構築する.
-- @param settings 設定値.
function TKGNOTIFIER_ITEM_LOAD_SETTINGS(settings)
  log("TKGNOTIFIER_ITEM_LOAD_SETTINGS")
  itemSettings = settings.item
  if settings.locale then
    R = TKGNOTIFIER_GET_RESOURCE(resources, settings.locale)
  end
  debugIsEnabled = settings.debug and settings.debug.enable
end

---
-- メール通知機能を初期化する.
-- @param settings 設定値.
-- @param trigger 呼び出しのトリガー.
function TKGNOTIFIER_ITEM_INIT(settings, trigger)
  log("TKGNOTIFIER_ITEM_INIT")

  -- ログイン時のみ設定読み込み
  if trigger <= TKGNOTIFIER_ENUM_TRIGGER.onLogined then
    TKGNOTIFIER_ITEM_LOAD_SETTINGS(settings)
  end

  TKGNOTIFIER_ITEM_NOTIFY_IF_NEEDED(trigger)
end
