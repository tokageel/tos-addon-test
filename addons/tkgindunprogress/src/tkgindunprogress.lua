---
-- IDの進捗率を自キャラ周辺に表示するアドオン.

---
-- @local
-- アドオン概要.
-- @field name アドオン名.
-- @field author 作者名.
-- @field version バージョン.
-- @table Addon
local Addon = {
  name = "TKGINDUNPROGRESS",
  author = "TOKAGEEL",
  version = "1.0.2"
}

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][Addon.author] = _G["ADDONS"][Addon.author] or {}
_G["ADDONS"][Addon.author][Addon.name] = _G["ADDONS"][Addon.author][Addon.name] or {}
local g = _G["ADDONS"][Addon.author][Addon.name]

-- デバッグ機能の有無.
local debugIsEnabled = false

---
-- @local
-- 指定した文字列をシステムログとしてチャットウィンドウへ出力する.
-- @param message 出力する文字列.
local function log(message)
  if debugIsEnabled then
    CHAT_SYSTEM(string.format("[TKGINDUNPROGRESS] %s", tostring(message)), "616161")
  end
end

--- @local ID進捗度（0-5）.
local current_rank = 0
--- @local ID進捗度に対応する表示情報.
local rank_table = {}
rank_table["5"] = { icon="test_indun_S" }
rank_table["4"] = { icon="test_indun_A" }
rank_table["3"] = { icon="test_indun_B" }
rank_table["2"] = { icon="test_indun_C" }
rank_table["1"] = { icon="test_indun_D" }

---
-- @local
-- OPEN_INDUN_REWARD_HUDのコールバックハンドラ.
-- @param frame アドオンのフレーム.
-- @param msg 未使用.
-- @param argStr 未使用.
-- @param argNum ID進捗率（0-100）.
function TKGINDUNPROGRESS_ON_PROGRESS_UPDATED(frame, msg, argStr, argNum)
  --log("TKGINDUNPROGRESS_ON_PROGRESS_UPDATED")
  --log(string.format("msg=%s, str=%s, num=%d", msg, argStr, argNum))

  -- 進捗度算出
  local rank = math.floor(argNum / 20)
  if (rank == 0) or (rank == current_rank) then
    --log(string.format("rank=%d, cur=%d", rank, current_rank))
    return
  end
  current_rank = rank

  -- 表示内容取得
  local info = rank_table[tostring(rank)]
  if info == nil then
    log("info == nil")
    return
  end
  local icon = GET_CHILD_RECURSIVELY(frame, "icon")
  if icon and info.icon then
    icon:SetImage(info.icon)
    -- フレーム表示後は一定時間後に非表示にする
    frame:ShowWindow(1)
    frame:SetDuration(10.0)
  end

  -- 進捗100%到達時は効果音鳴動させよう
  if rank == 5 then
    imcSound.PlaySoundEvent("sys_levelup")
  end
end

---
-- @local
-- アドオン初期化処理.
-- フレームワークからの呼び出しを期待しているため、直接呼び出さないこと.
-- @param addon アドオン.
-- @param frame アドオンのフレーム.
function TKGINDUNPROGRESS_ON_INIT(addon, frame)
  log("TKGINDUNPROGRESS_ON_INIT")
  g.addon = addon
  g.frame = frame

  -- フレーム位置は自キャラ追従
  FRAME_AUTO_POS_TO_OBJ(frame, session.GetMyHandle(), -100, -150, 1, 1)
  -- OPEN_INDUN_REWARD_HUDはID内で一定時間ごとに（進捗率の更新有無によらず）繰り返し発行される
  addon:RegisterMsg("OPEN_INDUN_REWARD_HUD", "TKGINDUNPROGRESS_ON_PROGRESS_UPDATED")
end
