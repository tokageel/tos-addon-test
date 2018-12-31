---
-- 設定管理機能.
-- システム設定画面の下端に設定項目を追加する.

-- デバッグ機能の有無.
local debugIsEnabled = false
-- リソース一覧.
local resources = {
  EN = {
    list = {
      triggers = {
        "None",
        "Login",
        "Character changed",
        "Map transited",
        "Channel changed"
      }
    },
    string = {
      settings_title = "TKGNOTIFIER",
      settings_mail = "Mail expiration",
      settings_item = "Item expiration",
      settings_medal = "Free TP",
      settings_trigger = "Notification trigger: ",
      settings_threshold_days = "Threshold (day): ",
      settings_threshold_points = "Threshold (points): "
    }
  },
  JP = {
    list = {
      triggers = {
        "通知しない",
        "ログイン時",
        "CC時",
        "マップ移動時",
        "チャンネル移動時"
      }
    },
    string = {
      settings_title = "TKGNOTIFIER設定",
      settings_mail = "メール期限通知設定",
      settings_item = "アイテム期限通知設定",
      settings_medal = "無料TP蓄積通知設定",
      settings_trigger = "通知契機：",
      settings_threshold_days = "閾値（日）：",
      settings_threshold_points = "閾値（ポイント）："
    }
  }
}
-- リソース.
local R = resources.JP

-- 閾値（日）ドロップリスト項目一覧.
local thresholdDays = {
  "1",
  "3",
  "7",
  "14"
}
-- 閾値（ポイント）ドロップリスト項目一覧.
local thresholdPoints = {
  "1",
  "2",
  "3",
  "4",
  "5"
}

---
-- 指定した文字列をシステムログとしてチャットウィンドウへ出力する.
-- @param message 出力する文字列.
local function log(message)
  if debugIsEnabled then
    CHAT_SYSTEM(string.format("[TKGNOTIFIER_SETTINGS] %s", tostring(message)), "616161")
  end
end

---
-- 設定画面から設定値を取得して
-- @param parent 設定画面上のウィジェット.
function TKGNOTIFIER_SETTINGS_UPDATE(parent)
  log("TKGNOTIFIER_SETTINGS_UPDATE")
  local frame = parent:GetTopParentFrame()
  if not frame then
    log("top frame is not found")
    return
  end
  -- 全ドロップリストの参照確認
  local allDroplist = {
    mail = {
      trigger = GET_CHILD_RECURSIVELY(frame, "tkgnotifier_mail_trigger_droplist"),
      threshold = GET_CHILD_RECURSIVELY(frame, "tkgnotifier_mail_threshold_droplist")
    },
    item = {
      trigger = GET_CHILD_RECURSIVELY(frame, "tkgnotifier_item_trigger_droplist"),
      threshold = GET_CHILD_RECURSIVELY(frame, "tkgnotifier_item_threshold_droplist")
    },
    medal = {
      trigger = GET_CHILD_RECURSIVELY(frame, "tkgnotifier_medal_trigger_droplist"),
      threshold = GET_CHILD_RECURSIVELY(frame, "tkgnotifier_medal_threshold_droplist")
    }
  }
  for k, v in pairs(allDroplist) do
    if (v.trigger == nil) or (v.threshold == nil) then
      log("drop list is not avalable")
      return
    end
  end
  -- グローバル領域に格納されている設定値を参照
  local g = _G["ADDONS"]["TOKAGEEL"]["TKGNOTIFIER"]
  if (g == nil) or (g.settings == nil) then
    log("no settings")
    return
  end

  -- 通知なし（Index=0）が選択された場合は閾値設定のリストは無効にする
  for _, t in pairs(allDroplist) do
    t.threshold:SetEnable(math.min(t.trigger:GetSelItemIndex(), 1))
  end

  -- ドロップリストから設定値を読み込み
  g.settings.mail.trigger = tonumber(allDroplist.mail.trigger:GetSelItemIndex())
  g.settings.mail.threshold_day = tonumber(allDroplist.mail.threshold:GetSelItemCaption())
  g.settings.item.trigger = tonumber(allDroplist.item.trigger:GetSelItemIndex())
  g.settings.item.threshold_day = tonumber(allDroplist.item.threshold:GetSelItemCaption())
  g.settings.medal.trigger = tonumber(allDroplist.medal.trigger:GetSelItemIndex())
  g.settings.medal.threshold = tonumber(allDroplist.medal.threshold:GetSelItemCaption())

  -- 設定値をJSON出力
  local settingsFilePath = "../addons/tkgnotifier/settings.json"
  local acutil = require('acutil')
  acutil.saveJSON(settingsFilePath, g.settings)
end

---
-- 設定画面のアドオン設定項目用グループを取得する.
-- グループボックスが未生成の場合は設定画面の下端にグループボックスを生成する.
-- @param caption グループのタイトル文字列.
-- @return アドオン設定項目用のグループボックス. 取得にも生成にも失敗した場合はnil.
local function TKGNOTIFIER_SETTINGS_CREATE_OR_GET_GROUP(caption)
  log("TKGNOTIFIER_SETTINGS_CREATE_OR_GET_GROUP")
  -- 設定画面
  local optionFrame = ui.GetFrame("systemoption")
  if not optionFrame then
    log("systemoption frame is not found")
    return nil
  end
  -- 設定画面のコンテンツ領域
  local bg2 = GET_CHILD(optionFrame, "bg2")
  if not bg2 then
    log("bg2 group box is not found")
    return nil
  end
  -- 設定画面のアドオン設定領域を取得または生成
  local idSettingsBox = "tkgnotifier_settings_box"
  local gbox = GET_CHILD(bg2, idSettingsBox)
  if not gbox then
    -- 設定画面の下端を求める
    local bottomYPos = 0
    for i = 0, bg2:GetChildCount() - 1 do
      local widget = bg2:GetChildByIndex(i)
      bottomYPos = math.max(bottomYPos, (widget:GetY() + widget:GetHeight()))
    end

    -- 設定画面の下端にグループを作成
    gbox = bg2:CreateOrGetControl("groupbox", idSettingsBox, 0, 0, 560, 400)
    gbox = tolua.cast(gbox, "ui::CGroupBox")
    gbox:SetGravity(ui.CENTER_HORZ, ui.TOP)
    gbox:SetOffset(0, bottomYPos)
    gbox:SetSkinName("")

    -- 水平線を追加
    local boardLine = gbox:CreateOrGetControl(
      "labelline", "tkgnotifier_labelline", 0, 0, gbox:GetWidth(), 4)
    -- タイトルラベルを追加
    local title = gbox:CreateOrGetControl(
      "richtext", "tkgnotifier_title", 0, 0, gbox:GetWidth(), 10);
    title:SetOffset(0, 0)
    title:SetMargin(10, 10, 0, 0)
    title:SetText(string.format("{@st43}%s{/}", caption))
  end
  return gbox
end

---
-- 指定したグループボックスの子要素となるラベルを返す.
-- 指定した名前のラベルが未生成の場合は生成する.
-- @param gbox ラベルの親となるグループボックス（ui::CGroupBox）.
-- @param name ラベルの名前.
-- @param caption ラベルに表示する文字列.
-- @return 生成したラベル（ui::CRichText）.
local function TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, name, caption)
  log("TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL")
  local label = gbox:CreateOrGetControl("richtext", name, 0, 0, 200, 40)
  label = tolua.cast(label, "ui::CRichText")
  label:SetTextAlign("left", "top")
  label:SetText("{@st66b}" .. tostring(caption) .. "{/}")
  return label
end

---
-- 指定したグループボックスの子要素となるドロップリストを返す.
-- 指定した名前のドロップリストが未生成の場合は生成する.
-- ドロップリストの項目はこの関数の呼び出しごとに呼び出しごとに再生成される.
-- @param gbox ドロップリストの親となるグループボックス（ui::CGroupBox）.
-- @param name ドロップリストの名前.
-- @param selectValue ドロップリストで選択状態にする項目の値.
-- itemsに存在しない値を指定した場合、ドロップリストの末尾に項目を追加した上で選択状態とする.
-- @param items ドロップリストに表示する項目の一覧.
-- @param isDisable 取得したドロップリストを無効状態に設定する場合はtrue.
-- @return 取得したドロップリスト.
local function TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(gbox, name, selectValue, items, isDisable)
  log("TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST")
  local dropList = gbox:CreateOrGetControl("droplist", name, 0, 0, 200, 40)
  dropList = tolua.cast(dropList, "ui::CDropList")
  dropList:SetGravity(ui.LEFT, ui.TOP)
  dropList:SetSkinName("droplist_normal")
  dropList:SetTextAlign("left", "top")
  dropList:SetFontName("white_20_ol")
  dropList:ClearItems()
  local selectIndex
  for i = 1, #items do
    local index = (i - 1)
    dropList:AddItem(tostring(index), items[i], 0)
    if (items[i] == selectValue) then
      selectIndex = index
    end
  end
  -- 選択対象がリストの中にない場合はリストに追加する
  if (selectIndex == nil) then
    selectIndex = #items
    dropList:AddItem(tostring(selectIndex), selectValue, 0)
  end
  dropList:SelectItem(selectIndex)
  dropList:SetSelectedScp("TKGNOTIFIER_SETTINGS_UPDATE")
  if isDisable then
    dropList:SetEnable(0)
  end
  return dropList
end

---
-- 設定管理機能を初期化する.
-- @param settings 設定値.
function TKGNOTIFIER_SETTINGS_INIT(settings)
  if settings then
    if settings.locale then
      R = TKGNOTIFIER_GET_RESOURCE(resources, settings.locale)
    end
    debugIsEnabled = settings.debug and settings.debug.enable
  end

  -- 何らかの理由で領域作成失敗した場合は対処不可
  local gbox = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_GROUP(R.string.settings_title)
  if not gbox then
    log("group box is not found")
    return
  end

  -- 各機能の設定項目を生成する
  --
  local label, dropList
  -- メール通知ラベル
  local y = 50
  local yInterval = 30
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_mail_label", R.string.settings_mail)
  label:SetMargin(20, y, 0, 0)
  -- メール通知トリガー
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_mail_trigger_label", R.string.settings_trigger)
  label:SetMargin(40, y, 0, 0)
  dropList = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(
    gbox, "tkgnotifier_mail_trigger_droplist", R.list.triggers[tonumber(settings.mail.trigger) + 1], R.list.triggers, false)
  dropList:SetMargin(label:GetWidth() + 40, y, 0, 0)
  -- メール通知閾値
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_mail_threshold_label", R.string.settings_threshold_days)
  label:SetMargin(40, y, 0, 0)
  dropList = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(
    gbox, "tkgnotifier_mail_threshold_droplist", tostring(settings.mail.threshold_day), thresholdDays, (dropList:GetSelItemIndex() == 0))
  dropList:SetMargin(label:GetWidth() + 40, y, 0, 0)

  -- アイテム通知
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_item_label", R.string.settings_item)
  label:SetMargin(20, y, 0, 0)
  -- アイテム通知トリガー
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_item_trigger_label", R.string.settings_trigger)
  label:SetMargin(40, y, 0, 0)
  dropList = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(
    gbox, "tkgnotifier_item_trigger_droplist", R.list.triggers[tonumber(settings.item.trigger) + 1], R.list.triggers, false)
  dropList:SetMargin(label:GetWidth() + 40, y, 0, 0)
  -- アイテム通知閾値
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_item_threshold_label", R.string.settings_threshold_days)
  label:SetMargin(40, y, 0, 0)
  dropList = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(
    gbox, "tkgnotifier_item_threshold_droplist", tostring(settings.item.threshold_day), thresholdDays, (dropList:GetSelItemIndex() == 0))
  dropList:SetMargin(label:GetWidth() + 40, y, 0, 0)

  -- 無料TP通知
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_medal_label", R.string.settings_medal)
  label:SetMargin(20, y, 0, 0)
  -- 無料TP通知トリガー
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_medal_trigger_label", R.string.settings_trigger)
  label:SetMargin(40, y, 0, 0)
  dropList = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(
    gbox, "tkgnotifier_medal_trigger_droplist", R.list.triggers[tonumber(settings.medal.trigger) + 1], R.list.triggers, false)
  dropList:SetMargin(label:GetWidth() + 40, y, 0, 0)
  -- 無料TP通知閾値
  y = y + yInterval
  label = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_LABEL(gbox, "tkgnotifier_medal_threshold_label", R.string.settings_threshold_points)
  label:SetMargin(40, y, 0, 0)
  dropList = TKGNOTIFIER_SETTINGS_CREATE_OR_GET_DROPLIST(
    gbox, "tkgnotifier_medal_threshold_droplist", tostring(settings.medal.threshold), thresholdPoints, (dropList:GetSelItemIndex() == 0))
  dropList:SetMargin(label:GetWidth() + 40, y, 0, 0)
end
