--[[
  written by topkek
--]]
local default = {
  spamInterval = "120",
  spamMessage = "123 for invite",
  inviteChannels = "guild, whisper",
  inviteKeyword = "123",
  raidSize = 40,
  caseSensitive = false,
  guildOnly = false,
}

saved = saved or default
local frame = CreateFrame("Frame")
local hidden = true
local enabled = false
local TimeSinceLastUpdate = 0
local UpdateInterval = 1
local numInRaid = 1

function initialize()
  spamIntervalEditbox:SetText(saved.spamInterval or "")
  spamMessageEditbox:SetText(saved.spamMessage)
  inviteChannelsEditbox:SetText(saved.inviteChannels)
  inviteKeywordEditbox:SetText(saved.inviteKeyword)
  raidSizeEditbox:SetText(saved.raidSize)
  caseSensitiveCheckbox:SetChecked(saved.caseSensitive)
  guildOnlyCheckBox:SetChecked(saved.guildOnly)
  if hidden then
    root:Hide()
  end
  TimeSinceLastUpdate = tonumber(saved.spamInterval) or 0
  UpdateInterval = tonumber(saved.spamInterval) or nil
end

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
      if numInRaid == 0 then
        numInRaid = 1
      end
      if IsInGroup() then
        if saved.raidSize > 5 then
          SendChatMessage(saved.spamMessage .. " - (" .. numInRaid .. "/" .. saved.raidSize .. ") in group", "RAID")
        else
          SendChatMessage(saved.spamMessage .. " - (" .. numInRaid .. "/" .. saved.raidSize .. ") in group", "PARTY")
        end
      end
      if IsInGuild() then
        SendChatMessage(saved.spamMessage .. " - (" .. numInRaid .. "/" .. saved.raidSize ..") in group", "GUILD")
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

function converter()
  local max = tonumber(saved.raidSize) or 40
  if max > 5 then
    ConvertToRaid()
  else
    ConvertToParty()
  end
end

function isGuildie(sender)
  GuildRoster();
  local num = select(3, GetNumGuildMembers())
  for i = 1, num do
    local name = GetGuildRosterInfo(i)
    if name == sender then
      return true
    end
  end
  return false
end

function shouldInvite(msg, sender)
  numInRaid = GetNumGroupMembers() or numInRaid
  local max = tonumber(saved.raidSize) or 40
  local player = UnitName("player")
  local realm = GetRealmName()
  local name = player.."-"..realm
  if names ~= sender and numInRaid >= max and saved.debug then
    print("|cffFF0000Raid full.|r")
    return
  end
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
    initialize()
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
      converter()
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

function initRaidSizeEditbox(this)
  raidSizeEditbox = this
  raidSizeEditbox:ClearFocus()
  raidSizeEditbox:SetText(saved.raidSize)
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
  TimeSinceLastUpdate = saved.spamInterval or 0
  UpdateInterval = saved.spamInterval or nil
  saved.raidSize = tonumber(raidSizeEditbox:GetText())
  saved.raidSize = saved.raidSize or 40
  if saved.raidSize > 40 then
    saved.raidSize = 40
  end
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
  saved.raidSize = raidSizeEditbox:GetText()
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
  raidSizeEditbox:ClearFocus()
  raidSizeEditbox:HighlightText(0, 0)
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

function enabledChecked(type)
  initialize()
  if type == "click" then
    enabled = not enabled
  elseif type == "slash" then
    enabled = true
  end
  if enabled then
    converter()
    TimeSinceLastUpdate = saved.spamInterval
    frame:SetScript("OnUpdate", announce)
  else
    frame:SetScript("OnUpdate", nil)
  end
  enabledCheckBox:SetChecked(enabled)
end

function focusEditbox()
  root:EnableKeyboard(true)
end

function isEscaped(msg, i)
  if i > 2 and string.sub(msg, i - 1, i - 1) == "\\" then
    return true
  end
end

function getArguments(msg)
  if string.sub(msg, 1, 1) ~= "\"" then
    return "", ""
  end
  local keyword = ""
  local gmsg = ""
  local inQuote = false
  local firstArg = false
  for i = 1, #msg do
    if string.sub(msg, i, i) == "\"" and not inQuote then
      if firstArg then
        if string.sub(msg, i - 1, i - 1) ~= " " then
          return "", ""
        end
      end
      inQuote = true
    elseif string.sub(msg, i, i) == "\"" and inQuote and not isEscaped(msg, i) then
      inQuote = false
      if not firstArg then
        if string.sub(msg, i + 1, i + 1) ~= " " then
          return "", ""
        end
        firstArg = true
      else
        return keyword, gmsg
      end
    elseif inQuote then
      if not firstArg then
        if not (string.sub(msg, i, i) == "\\" and string.sub(msg, i + 1, i + 1) == "\"") then
          keyword = keyword .. string.sub(msg, i, i)
        end
      else
        if not (string.sub(msg, i, i) == "\\" and string.sub(msg, i + 1, i + 1) == "\"") then
          gmsg = gmsg .. string.sub(msg, i, i)
        end
      end
    end
  end
  return "", ""
end

function slashCommand(msg)
  if (msg ~= "") then
    saved.inviteKeyword, saved.spamMessage = getArguments(msg)
    if saved.inviteKeyword == "" or saved.spamMessage == "" then
      print("Incorrect arguments.")
      return
    end
    print("Invites enabled: " .. saved.inviteKeyword)
    enabledChecked("slash")
    return
  end
  toggle()
  enabledCheckBox:SetChecked(enabled)
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
