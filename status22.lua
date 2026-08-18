local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local WebhookUrl = "https://discord.com/api/webhooks/1539304499276157049/3UZcBF9rcVH8VeYchanLmBehhx1yTnl7stH71gcB8fJibUJ5RMdfNkxudM9XjH3Ms3a5"
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

if not httpRequest then
    warn("[JujuZero Tracker]: Executor does not support HTTP requests.")
    return
end

-- Helper: Format numbers with commas safely without tonumber base crashes
local function FormatNumber(n)
    if not n then return "N/A" end
    local str = tostring(n)
    str = (str:gsub("x", ""))
    str = (str:gsub("%s+", ""))
    local cleanStr = (str:gsub(",", ""))
    
    local num = tonumber(cleanStr)
    if not num then return tostring(n) end

    local formatted = tostring(num)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function CleanText(str)
    if not str or str == "" or str == "N/A" then return "N/A" end
    return FormatNumber(str)
end

-- Direct Path Targeted Reader for Cursed Crystals
local function GetCursedCrystals()
    local crystalVal = nil

    -- Target 1: Event Shop Header Currency Amount Label
    pcall(function()
        local fullMenus = PlayerGui:FindFirstChild("FullMenus")
        if fullMenus then
            local loveEvent = fullMenus:FindFirstChild("LoveEvent_FullMenu")
            if loveEvent then
                local amountLabel = loveEvent.CanvasGroup.Frame.ImageLabel.Frame.EventShopHeader.Currency:FindFirstChild("AmountLabel")
                if amountLabel and amountLabel:IsA("TextLabel") and amountLabel.Text ~= "" then
                    crystalVal = amountLabel.Text
                end
            end
        end
    end)

    if crystalVal and crystalVal ~= "" then
        return FormatNumber(crystalVal)
    end

    -- Target 2: Any "AmountLabel" inside a "Currency" frame anywhere in FullMenus
    pcall(function()
        local fullMenus = PlayerGui:FindFirstChild("FullMenus")
        if fullMenus then
            for _, desc in ipairs(fullMenus:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Name == "AmountLabel" and desc.Parent and desc.Parent.Name == "Currency" then
                    if desc.Text and desc.Text ~= "" then
                        crystalVal = desc.Text
                        return
                    end
                end
            end
        end
    end)

    if crystalVal and crystalVal ~= "" then
        return FormatNumber(crystalVal)
    end

    -- Target 3: FullMenus Inventory Scrolling Frame Slot Items
    pcall(function()
        local inventory = PlayerGui.FullMenus:FindFirstChild("Inventory")
        if inventory then
            for _, desc in ipairs(inventory:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text:find("x%d") then
                    local cleanNum = (desc.Text:gsub("x", ""))
                    cleanNum = (cleanNum:gsub(",", ""))
                    cleanNum = (cleanNum:gsub("%s+", ""))
                    
                    local val = tonumber(cleanNum)
                    if val and val > 0 then
                        crystalVal = desc.Text
                        return
                    end
                end
            end
        end
    end)

    if crystalVal and crystalVal ~= "" then
        return FormatNumber(crystalVal)
    end

    return "N/A"
end

-- Read HUD Currencies (Yen & Luman)
local function GetHUDCurrencies()
    local yenText, lumanText = "N/A", "N/A"
    local hud = PlayerGui:FindFirstChild("HUD")
    
    if hud then
        for _, desc in ipairs(hud:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:find("%d") then
                local cleanNum = (desc.Text:gsub(",", ""))
                cleanNum = (cleanNum:gsub("%s+", ""))
                local val = tonumber(cleanNum)
                if val then
                    if val > 10000000 then
                        yenText = desc.Text
                    elseif val > 50000 then
                        lumanText = desc.Text
                    end
                end
            end
        end
    end
    
    return yenText, lumanText
end

-- Send Discord Webhook Payload
local function SendCombinedEmbed(yenVal, lumanVal, crystalVal)
    local payload = {
        ["username"] = "Jujutsu Zero Tracker",
        ["avatar_url"] = "https://i.imgur.com/8N3L4yP.png",
        ["embeds"] = {
            {
                ["title"] = "Currency Tracker Update",
                ["color"] = 65280,
                ["fields"] = {
                    { ["name"] = "Player", ["value"] = LocalPlayer.DisplayName or LocalPlayer.Name, ["inline"] = false },
                    { ["name"] = "Yen", ["value"] = CleanText(yenVal), ["inline"] = true },
                    { ["name"] = "Luman", ["value"] = CleanText(lumanVal), ["inline"] = true },
                    { ["name"] = "Cursed Crystal", ["value"] = CleanText(crystalVal), ["inline"] = true }
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

-- Main Monitoring Loop
print("[JujuZero Tracker]: Targeted UI Path Tracker Initialized.")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = nil, nil, nil

    while true do
        local yen, luman = GetHUDCurrencies()
        local crystal = GetCursedCrystals()

        if yen ~= lastYen or luman ~= lastLuman or crystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = yen, luman, crystal
            print(string.format("[JujuZero Tracker]: Yen: %s | Luman: %s | Cursed Crystal: %s", tostring(yen), tostring(luman), tostring(crystal)))
            SendCombinedEmbed(yen, luman, crystal)
        end

        task.wait(5)
    end
end)
