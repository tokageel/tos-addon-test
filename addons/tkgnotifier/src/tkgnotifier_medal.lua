---
-- 無料TP蓄積通知機能.
-- 無料TPが一定値以上蓄積した場合に通知する.

-- 無料TP蓄積通知の設定.
local medalSettings
-- デバッグ機能の有無.
local debugIsEnabled = false
-- この機能で使用する通知種別.
local notificationKind = "TKGNOTIFIER_MEDAL"
-- リソース一覧.
local resources = {
  EN = {
    icon = {
      medal = "icon_item_tospoint"
    },
    string = {
      saved_free_medal = "You have saved free TP: %d points."
    }
  },
  JP = {
    icon = {
      medal = "icon_item_tospoint"
    },
    string = {
      saved_free_medal = "無料TPが%dポイント溜まっています。"
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
    CHAT_SYSTEM(string.format("[TKGNOTIFIER_MEDAL] %s", tostring(message)), "616161")
  end
end

---
-- 呼び出しタイミングと閾値が条件に合う場合、期限切れが近いメールの存在を通知する.
function TKGNOTIFIER_MEDAL_NOTIFY_IF_NEEDED(trigger)
  log("TKGNOTIFIER_MEDAL_NOTIFY_IF_NEEDED")

  -- 通知タイミングチェック
  log(string.format("trigger=%d (settings=%d)", trigger, medalSettings.trigger))
  if (medalSettings.trigger < trigger) then
    return
  end

  -- 閾値チェック
  local accountObj = GetMyAccountObj()
  local medal = accountObj.Medal
  log(string.format("medal=%d (settings=%d)", medal, medalSettings.threshold))
  if (medal >= medalSettings.threshold) then
    local message = string.format(R.string.saved_free_medal, medal)
    TKGNOTIFIER_NOTIFY({
      icon = R.icon.medal,
      message = message,
      kind = notificationKind
    })
  end
end

---
-- 指定した設定値を使用して設定を構築する.
-- @param settings 設定値.
function TKGNOTIFIER_MEDAL_LOAD_SETTINGS(settings)
  log("TKGNOTIFIER_MEDAL_LOAD_SETTINGS")

  medalSettings = settings.medal

  -- 指定された設定をマージ
  if settings.locale then
    R = TKGNOTIFIER_GET_RESOURCE(resources, settings.locale)
  end
  debugIsEnabled = settings.debug and settings.debug.enable
end

---
-- メール通知機能を初期化する.
-- @param settings 設定値.
function TKGNOTIFIER_MEDAL_INIT(settings, trigger)
  log("TKGNOTIFIER_MEDAL_INIT")

  -- ログイン時のみ設定読み込み
  if trigger <= TKGNOTIFIER_ENUM_TRIGGER.onLogined then
    TKGNOTIFIER_MEDAL_LOAD_SETTINGS(settings)
  end

  TKGNOTIFIER_MEDAL_NOTIFY_IF_NEEDED(trigger)
end
