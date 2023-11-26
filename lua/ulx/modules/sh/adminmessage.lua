local CATEGORY_NAME = "Administrator Channel"

-- Initialize default positions and time
local DEFAULT_POS_X = 5 / 10
local DEFAULT_POS_Y = 20 / 10
local DEFAULT_TIME = 15

-- Table to store individual player settings on the server
local playerSettings = {}

if SERVER then
    util.AddNetworkString("SendCenterMessage")
    util.AddNetworkString("UpdateMessageSettings")
    util.AddNetworkString("AdminMessageColor")

    function ulx.setconfig(calling_ply, posX, posY, time)
        local adjustedPosX = posX / 10
        local adjustedPosY = posY / 10

        -- Save the settings for the calling player
        playerSettings[calling_ply] = { posX = adjustedPosX, posY = adjustedPosY, time = time }

        net.Start("UpdateMessageSettings")
        net.WriteFloat(adjustedPosX)
        net.WriteFloat(adjustedPosY)
        net.WriteFloat(time)
        net.Send(calling_ply)

        ulx.fancyLogAdmin(calling_ply, true, "#A set to X: #s, Y: #s, time: #s", adjustedPosX, adjustedPosY, time)
    end
else
    local displayMessage
    local displayPosX = DEFAULT_POS_X
    local displayPosY = DEFAULT_POS_Y
    local displayTime = DEFAULT_TIME

    net.Receive("UpdateMessageSettings", function()
        displayPosX = net.ReadFloat()
        displayPosY = net.ReadFloat()
        displayTime = net.ReadFloat()
    end)

    function DisplayCenterMessage(msg, posX, posY, time)
        displayMessage = msg
        displayPosX = posX or displayPosX
        displayPosY = posY or displayPosY
        displayTime = time or displayTime

        surface.PlaySound("common/warning.wav")

        -- Add timer to clear the message after displayTime seconds
        timer.Simple(displayTime, function()
            displayMessage = nil
        end)
    end

    function DrawCenterMessage()
        if displayMessage then
            local w = ScrW()
            local tw, th = surface.GetTextSize(displayMessage)

            draw.SimpleText(displayMessage, "DermaLarge", w * displayPosX, th * displayPosY, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    hook.Add("HUDPaint", "DisplayCenterMessage", DrawCenterMessage)

    net.Receive("SendCenterMessage", function()
        local msg = net.ReadString()

        DisplayCenterMessage(msg, displayPosX, displayPosY, displayTime)
    end)

    net.Receive("AdminMessageColor", function()
        local msg = net.ReadString()
        chat.AddText(Color(255, 0, 0, 255), msg)
    end)
end

-- Shared code
function SendCenterMessageToAllPlayers(msg)
    if SERVER then
        net.Start("SendCenterMessage")
        net.WriteString(msg)
        net.Broadcast()
    end
end

function ulx.adminmessage(calling_ply, msg)
    local playerName

    if IsValid(calling_ply) then
        playerName = calling_ply:Nick()
    else
        playerName = "(consoles)"
    end

    local formattedMsg = "[Administrator Messages] " .. playerName .. ": " .. msg

    SendCenterMessageToAllPlayers(formattedMsg)

    net.Start("AdminMessageColor")
    net.WriteString(formattedMsg)
    net.Broadcast()
end

local adminmessage = ulx.command(CATEGORY_NAME, "ulx adminmessage", ulx.adminmessage, "@", true, true)
adminmessage:addParam { type = ULib.cmds.StringArg, hint = "messages", ULib.cmds.takeRestOfLine }
adminmessage:defaultAccess(ULib.ACCESS_ADMIN)
adminmessage:help("Send messages to all players in the center of the screen and in the chat box.")

local setconfig = ulx.command(CATEGORY_NAME, "ulx setconfig", ulx.setconfig, "!setconfig")
setconfig:addParam { type = ULib.cmds.NumArg, hint = "X position", default = DEFAULT_POS_X * 10, min = 0, max = 1000, ULib.cmds.optional, ULib.cmds.round }
setconfig:addParam { type = ULib.cmds.NumArg, hint = "Y position", default = DEFAULT_POS_Y * 10, min = 0, max = 1000, ULib.cmds.optional, ULib.cmds.round }
setconfig:addParam { type = ULib.cmds.NumArg, hint = "times", default = DEFAULT_TIME, min = 1, max = 60, ULib.cmds.optional, ULib.cmds.round }
setconfig:defaultAccess(ULib.ACCESS_ADMIN)
setconfig:help("Setting the default message location and time.")
