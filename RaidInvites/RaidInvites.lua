--[[
  written by topkek
--]]
local default = {
  spamInterval = "120",
  spamMessage = "123 for invite",
  inviteChannels = "guild, whisper",
  inviteKeyword = "123",
  caseSensitive = false,
  guildOnly = false
}

saved = saved or default
local frame = CreateFrame("Frame")
local hidden = true
local enabled = false
local TimeSinceLastUpdate = 0
local UpdateInterval = 1
local numInRaid = 0

function loadRoot(this)
  root = this
  root:EnableKeyboard(false)
end

function announce(self, elapsed)
  if UpdateInterval == nil or UpdateInterval == 0 then
    return
  end
  TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
  while (TimeSinceLastUpdate > UpdateInterval) do
    if enabled and saved.spamMessage ~= "" then
      numInRaid = GetNumGroupMembers() or numInRaid
      if IsInGroup() then
        SendChatMessage(saved.spamMessage .. " - (" .. numInRaid .. "/" .. "40) in raid", "RAID")
      end
      if IsInGuild() then
        SendChatMessage(saved.spamMessage .. " - (" .. numInRaid .. "/" .. "40) in raid", "GUILD")
      end
    end
    TimeSinceLastUpdate = TimeSinceLastUpdate - UpdateInterval
  end
end
frame:SetScript("OnUpdate", announce)

function containsKeyword(msg)
  if saved.inviteKeyword == nil then
    return false
  end
  if saved.caseSensitive then
    if string.match(msg, saved.inviteKeyword) then
      return true
    else
      return false
    end
  else
    if string.match(string.lower(msg), string.lower(saved.inviteKeyword)) then
      return true
    else
      return false
    end
  end
end

function isGuildie(sender)
  local num = select(3, GetNumGuildMembers())
  for i = 1, num do
    local name = GetGuildRosterInfo(tostring(i))
    if name == sender then
      return true
    end
  end
  return false
end

function shouldInvite(msg, sender)
  local player = UnitName("player")
  local realm = GetRealmName()
  local name = player.."-"..realm
  if name ~= sender and containsKeyword(msg) then
    if saved.guildOnly and isGuildie(sender) then
      InviteToGroup(sender)
    elseif not saved.guildOnly then
      InviteToGroup(sender)
    end
  end
end

function parse(...)
  local msg, sender = ...
  if not enabled then
    return
  end
  shouldInvite(msg, sender)
end

function handleEvent(self, event, ...)
  if event == "PLAYER_STARTED_MOVING" then
    root:EnableKeyboard(false)
    clearEditboxFocus()
  elseif event == "CURSOR_UPDATE" then
    root:EnableKeyboard(false)
    clearEditboxFocus()
  elseif event == "PLAYER_LOGIN" then
    spamIntervalEditbox:SetText(saved.spamInterval or "")
    spamMessageEditbox:SetText(saved.spamMessage)
    inviteChannelsEditbox:SetText(saved.inviteChannels)
    inviteKeywordEditbox:SetText(saved.inviteKeyword)
    caseSensitiveCheckbox:SetChecked(saved.caseSensitive)
    guildOnlyCheckBox:SetChecked(saved.guildOnly)
    enabledCheckBox:SetChecked(enabled)
    if hidden then
      root:Hide()
    end
    TimeSinceLastUpdate = tonumber(saved.spamInterval) or 0
    UpdateInterval = tonumber(saved.spamInterval) or nil
  elseif event == "CHAT_MSG_SAY" then
    if isChannel("say") then
      parse(...)
    end
  elseif event == "CHAT_MSG_YELL" then
    if isChannel("yell") then
      parse(...)
    end
  elseif event == "CHAT_MSG_WHISPER" then
    if isChannel("whisper") then
      parse(...)
    end
  elseif event == "CHAT_MSG_GUILD" then
    if isChannel("guild") then
      parse(...)
    end
  elseif event == "CHAT_MSG_CHANNEL" then
    local channel = select(9, ...)
    if isChannel(channel) then
      parse(...)
    end
  elseif event == "GROUP_ROSTER_UPDATE" then
    if enabled then
      ConvertToRaid()
    end
  end
end

function initCaseSensitiveCheckbox(this)
  caseSensitiveCheckbox = this
  caseSensitiveCheckbox:SetChecked(saved.caseSensitive)
  getglobal(caseSensitiveCheckbox:GetName().."Text"):SetText("Case Sensitive")
end

function initGuildOnlyCheckbox(this)
  guildOnlyCheckBox = this
  guildOnlyCheckBox:SetChecked(saved.guildOnly)
  getglobal(guildOnlyCheckBox:GetName().."Text"):SetText("Guild Only")
end

function initEnabledCheckbox(this)
  enabledCheckBox = this
  enabledCheckBox:SetChecked(enabled)
  if enabled then
    frame:SetScript("OnUpdate", announce)
  else
    frame:SetScript("OnUpdate", nil)
  end
  getglobal(enabledCheckBox:GetName().."Text"):SetText("Invites Enabled")
end

function initSpamIntervalEditbox(this)
  spamIntervalEditbox = this
  spamIntervalEditbox:ClearFocus()
  spamIntervalEditbox:SetText(saved.spamInterval)
end

function initSpamMessageEditbox(this)
  spamMessageEditbox = this
  spamMessageEditbox:ClearFocus()
  spamMessageEditbox:SetText(saved.spamMessage)
end

function initInviteChannelsEditbox(this)
  inviteChannelsEditbox = this
  inviteChannelsEditbox:ClearFocus()
  inviteChannelsEditbox:SetText(saved.inviteChannels)
end

function initInviteKeywordEditbox(this)
  inviteKeywordEditbox = this
  inviteKeywordEditbox:ClearFocus()
  inviteKeywordEditbox:SetText(saved.inviteKeyword)
end

function toggle()
  hidden = not hidden
  if hidden then
    root:Hide()
  else
    root:Show()
  end
  root:EnableKeyboard(false)
end

function trim(s)
  return s:match("^%s*(.-)%s*$")
end

function split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    if trim(match) ~= "" then
      table.insert(result, trim(match));
    end
  end
  return result;
end

function isChannel(name)
  local text = inviteChannelsEditbox:GetText()
  local names = split(text, ",")
  for i = 1, #names do
    if string.lower(name) == string.lower(names[i]) then
      return true
    end
  end
  return false
end

function captureInputs()
  saved.spamInterval = tonumber(spamIntervalEditbox:GetText())
  saved.spamMessage = spamMessageEditbox:GetText()
  TimeSinceLastUpdate = tonumber(saved.spamInterval) or 0
  UpdateInterval = tonumber(saved.spamInterval) or nil
  saved.inviteChannels = inviteChannelsEditbox:GetText()
  saved.inviteKeyword = inviteKeywordEditbox:GetText()
end

function editboxChanged()
  if enabled then
    enabled = false
    enabledCheckBox:SetChecked(false)
    frame:SetScript("OnUpdate", nil)
  end
  saved.spamInterval = spamIntervalEditbox:GetText()
  saved.spamMessage = spamMessageEditbox:GetText()
  saved.inviteChannels = inviteChannelsEditbox:GetText()
  saved.inviteKeyword = inviteKeywordEditbox:GetText()
  captureInputs()
end

function clearEditboxFocus()
  spamIntervalEditbox:ClearFocus()
  spamIntervalEditbox:HighlightText(0, 0)
  spamMessageEditbox:ClearFocus()
  spamMessageEditbox:HighlightText(0, 0)
  inviteChannelsEditbox:ClearFocus()
  inviteChannelsEditbox:HighlightText(0, 0)
  inviteKeywordEditbox:ClearFocus()
  inviteKeywordEditbox:HighlightText(0, 0)
  root:EnableKeyboard(false)
end

function escapePressed()
  clearEditboxFocus()
end

function handleKey(key)
  if key == "ESCAPE" then
    escapePressed()
  end
end

function caseSensitiveChecked()
  saved.caseSensitive = not saved.caseSensitive
end

function guildOnlyChecked()
  saved.guildOnly = not saved.guildOnly
end

function enabledChecked()
  enabled = not enabled
  if enabled then
    TimeSinceLastUpdate = saved.spamInterval
    frame:SetScript("OnUpdate", announce)
  else
    frame:SetScript("OnUpdate", nil)
  end
end

function focusEditbox()
  root:EnableKeyboard(true)
end

function slashCommand(msg)
  toggle()
end

SLASH_RAIDINVITE1 = "/rinv"
SLASH_RAIDINVITE2 = "/rinvs"
SLASH_RAIDINVITE3 = "/raidinv"
SLASH_RAIDINVITE4 = "/raidinvs"
SLASH_RAIDINVITE5 = "/rinvite"
SLASH_RAIDINVITE6 = "/rinvites"
SLASH_RAIDINVITE7 = "/raidinvite"
SLASH_RAIDINVITE8 = "/raidinvites"
SlashCmdList["RAIDINVITE"] = slashCommand