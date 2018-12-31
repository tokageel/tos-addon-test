---
-- UI管理機能.

-- デバッグ機能の有無.
local debugIsEnabled = false

---
-- デバッグONの場合指定した文字列をシステムログとしてチャットウィンドウへ出力する.
-- @param message 出力する文字列.
local function log(message)
  if debugIsEnabled then
    CHAT_SYSTEM(string.format("[TKGNOTIFIER_FRAME] %s", tostring(message)), "616161")
  end
end

---
-- UI管理機能の初期化処理.
-- @param settings 設定値.
function TKGNOTIFIER_FRAME_INIT(settings, trigger)
  log("TKGNOTIFIER_FRAME_INIT")
  if trigger == TKGNOTIFIER_ENUM_TRIGGER.onLogined then
    debugIsEnabled = settings and settings.debug and settings.debug.enable
  end
end

---
-- フレーム表示時のコールバック.
-- @param frame 表示対象のフレーム.
function TKGNOTIFIER_FRAME_OPEN(frame)
  log("TKGNOTIFIER_FRAME_OPEN")
  if not frame then
    return
  end
  local x = 0
  local y = 0

  -- クエスト欄の上辺りに画面右詰めで表示
  local questFrame = ui.GetFrame("questinfoset_2")
  if questFrame then
    x = questFrame:GetX() + (questFrame:GetWidth() - frame:GetWidth())
    y = questFrame:GetY() - frame:GetHeight()
  end
  frame:SetOffset(x, y)
end

---
-- フレームを非表示時のコールバック.
-- @param frame 非表示対象のフレーム.
function TKGNOTIFIER_FRAME_CLOSE(frame)
  log("TKGNOTIFIER_FRAME_CLOSE")
end

---
-- ウィジェットクリック時のコールバック.
-- @param frame 指定されたウィジェットを含むフレーム.
-- @param ctrl 指定されたウィジェット.
-- @param argStr LBtnUpArgStrで指定された引数.
-- @param argNum 引数の数.
function TKGNOTIFIER_FRAME_ON_CLICKED(frame, ctrl, argStr, argNum)
  log("TKGNOTIFIER_FRAME_ON_CLICKED")
  TKGNOIFIER_POP()
end

---
-- アイコンとメッセージを指定して通知を表示する.
-- @param icon アイコン.
-- @param message メッセージ.
function TKGNOTIFIER_FRAME_ON_STACK_CHANGED(stack)
  log("TKGNOTIFIER_FRAME_ON_STACK_CHANGED")
  local frameName = "tkgnotifier"
  local frame = ui.GetFrame(frameName)
  if (frame == nil) then
    log("frame is nil")
    return
  end

  -- すでに通知を表示済みの場合は一度閉じる
  if (frame:IsVisible() == 1) then
    ui.CloseFrame("tkgnotifier")
  end
  -- スタックが空の場合はそのまま処理終了
  log("stack.length=" .. tostring(#stack))
  if (#stack == 0) then
    log("stack is empty")
    return
  end

  -- スタックから要素を一つ取り出して表示
  local notification = stack[#stack]
  local richText = GET_CHILD_RECURSIVELY(frame, "message")
  if richText then
    richText:SetText(notification.message)
  end
  local picture = GET_CHILD_RECURSIVELY(frame, "icon")
  if picture then
    picture:SetImage(notification.icon)
  end
  ui.OpenFrame(frameName)
end
