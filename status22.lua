local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate script loops if re-executed
if _G.JujuTrackerRunning then
    _G.JujuTrackerRunning = false
    task.wait(1)
end
_G.JujuTrackerRunning = true

local WebhookUrl = "https://discord.com/api/webhooks/1539304499276157049/3UZcBF9rcVH8VeYchanLmBehhx1yTnl7stH71gcB8fJibUJ5RMdfNkxudM9XjH3Ms3a5"
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

if not httpRequest then
    warn("[JujuZero Tracker]: Executor does not support HTTP requests.")
    return
end

-- Safe Single-Value Number Formatter
local function FormatNumber(val)
    if not val then return "N/A" end
    local str = tostring(val)
    
    local digits = ""
    for digit in str:gmatch("%d") do
        digits = digits .. digit
    end

    if digits == "" then return tostring(val) end

    local num = tonumber(digits)
    if not num then return tostring(val) end

    local formatted = tostring(num)
    while true do
        local res, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        formatted = res
        if count == 0 then break end
    end
    return formatted
end

-- Reads Cursed Crystals strictly from the Event Header Currency Label
local function GetCursedCrystals()
    local result = nil

    -- Target: Exact hierarchy (EventShopHeader -> Currency -> AmountLabel)
    pcall(function()
        local fullMenus = PlayerGui:FindFirstChild("FullMenus")
        if not fullMenus then return end

        for _, desc in ipairs(fullMenus:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Name == "AmountLabel" then
                local parent = desc.Parent
                if parent and parent.Name == "Currency" then
                    local grandParent = parent.Parent
                    if grandParent and grandParent.Name == "EventShopHeader" then
                        if desc.Text and desc.Text ~= "" then
                            result = desc.Text
                            return
                        end
                    end
                end
            end
        end
    end)

    if result and result ~= "" then
        return FormatNumber(result)
    end

    -- Backup Target: Inventory slot with 5+ digit counts (x107,514)
    pcall(function()
        local inventory = PlayerGui.FullMenus:FindFirstChild("Inventory")
        if inventory then
            for _, desc in ipairs(inventory:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text:find("x%d") then
                    local digitsOnly = desc.Text:gsub("[^%d]", "")
                    local val = tonumber(digitsOnly)
                    if val and val > 10000 then -- Target high stack values like 107,514
                        result = desc.Text
                        return
                    end
                end
            end
        end
    end)

    if result and result ~= "" then
        return FormatNumber(result)
    end

    return "N/A"
end

-- Reads Yen and Luman from HUD
local function GetHUDCurrencies()
    local yenText, lumanText = "N/A", "N/A"
    
    pcall(function()
        local hud = PlayerGui:FindFirstChild("HUD")
        if hud then
            for _, desc in ipairs(hud:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text:find("%d") then
                    local rawStr = desc.Text
                    local digits = ""
                    for d in rawStr:gmatch("%d") do digits = digits .. d end
                    local val = tonumber(digits)
                    
                    if val then
                        if val > 10000000 then
                            yenText = rawStr
                        elseif val > 50000 then
                            lumanText = rawStr
                        end
                    end
                end
            end
        end
    end)

    return yenText, lumanText
end

-- Webhook Dispatcher
local function SendWebhook(yenVal, lumanVal, crystalVal)
    local payload = {
        ["username"] = "Jujutsu Zero Tracker",
        ["avatar_url"] = "https://i.imgur.com/8N3L4yP.png",
        ["embeds"] = {
            {
                ["title"] = "Currency Tracker Update",
                ["color"] = 65280,
                ["fields"] = {
                    { ["name"] = "Player", ["value"] = LocalPlayer.DisplayName or LocalPlayer.Name, ["inline"] = false },
                    { ["name"] = "Yen", ["value"] = FormatNumber(yenVal), ["inline"] = true },
                    { ["name"] = "Luman", ["value"] = FormatNumber(lumanVal), ["inline"] = true },
                    { ["name"] = "Cursed Crystal", ["value"] = FormatNumber(crystalVal), ["inline"] = true }
                },
                ["footer"] = { ["text"] = "Jujutsu Zero AFK Monitoring" },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
        }
    }

    pcall(function()
        httpRequest({
            Url = WebhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- Main Loop
print("[JujuZero Tracker v7 Loaded - Exact Header Target]")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = "", "", ""

    while _G.JujuTrackerRunning do
        local yen, luman = GetHUDCurrencies()
        local crystal = GetCursedCrystals()

        if yen ~= lastYen or luman ~= lastLuman or crystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = yen, luman, crystal
            print(string.format("[JujuZero Tracker]: Yen: %s | Luman: %s | Cursed Crystal: %s", tostring(yen), tostring(luman), tostring(crystal)))
            SendWebhook(yen, luman, crystal)
        end

        task.wait(5)
    end
end)
