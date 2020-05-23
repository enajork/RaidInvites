--[[
  written by topkek
--]]
local AddOn, config = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame.TimeSinceLastUpdate = 120
local guildMessage = "" -- guild message
local UpdateInterval = 120 -- interval in seconds
local enabled = false
local keyword = ""

function printMessage(self, elapsed)
  self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
  while (self.TimeSinceLastUpdate > UpdateInterval) do
    if enabled and not alt then
      SendChatMessage(guildMessage, "GUILD")
    end
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate - UpdateInterval
  end
end

function filterInvites(msg)
  if string.match(msg, keyword) then
    return true
  end
  return false
end

function wantsInvite(msg, sender)
  local player = UnitName("player")
  if player ~= sender and filterInvites(msg) then
    InviteToGroup(sender)
  end
end

function handleEvents(self, event, ...)
  local msg, sender = ...
  local guid = select(12, ...)
  local _, _, _, _, _, name = GetPlayerInfoByGUID(guid)
  if enabled then
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_WHISPER" then
      wantsInvite(msg:lower(), name)
    end
    ConvertToRaid()
  end
end

frame:SetScript("OnEvent", handleEvents)

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
  enabled = not enabled
  if enabled then
    keyword, guildMessage = getArguments(msg)
    if keyword == "" or guildMessage == "" then
      print("Incorrect arguments.")
      enabled = false
      return
    end
    UpdateInterval = 120
    print("Invites enabled: " .. keyword)
    frame:SetScript("OnUpdate", printMessage)
  else
    print("Invites disabled.")
    frame:SetScript("OnUpdate", nil)
  end
end

SLASH_RAIDINVITE1 = "/rinv"
SLASH_RAIDINVITE2 = "/rinvs"
SlashCmdList["RAIDINVITE"] = slashCommand
