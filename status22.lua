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

-- Helper: Format numbers with commas
local function FormatNumber(n)
    local num = tonumber(n)
    if not num then return tostring(n or "N/A") end
    local formatted = tostring(num)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Helper: Clean raw text formatting
local function CleanText(str)
    if not str or str == "" or str == "N/A" then return "N/A" end
    local clean = str:gsub("x", ""):gsub("%s+", "")
    local num = tonumber(clean:gsub(",", ""))
    if num then
        return FormatNumber(num)
    end
    return str
end

-- Reliable Dual-Reader for Cursed Crystals
local function GetCursedCrystals()
    -- Strategy 1: Check PlayerGui inventory frames directly
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text:find("x%d") then
            local parent = desc.Parent
            local isCrystal = false
            
            -- Check if parent element relates to Cursed Crystal
            while parent and parent ~= PlayerGui do
                local pName = parent.Name:lower()
                if pName:find("cursed") or pName:find("crystal") then
                    isCrystal = true
                    break
                end
                parent = parent.Parent
            end
            
            if isCrystal then
                local clean = desc.Text:gsub("x", ""):gsub(",", ""):gsub("%s+", "")
                local val = tonumber(clean)
                if val then
                    return FormatNumber(val)
                end
            end
        end
    end

    -- Strategy 2: Precise GC memory lookup (No duplicate summing / multipliers)
    local highestCount = 0
    local visited = {}

    for _, tbl in ipairs(getgc(true)) do
        if type(tbl) == "table" and not visited[tbl] then
            visited[tbl] = true
            if rawget(tbl, 1) == "CursedCrystal" or tbl[1] == "CursedCrystal" then
                local count = tonumber(tbl[2]) or 0
                if count > highestCount then
                    highestCount = count
                end
            end
        end
    end

    if highestCount > 0 then
        return FormatNumber(highestCount)
    end

    return "N/A"
end

-- Get Yen and Luman from HUD
local function GetHUDCurrencies()
    local yenText, lumanText = "N/A", "N/A"
    local hud = PlayerGui:FindFirstChild("HUD")
    
    if hud then
        for _, desc in ipairs(hud:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:find("%d") then
                local cleanNum = desc.Text:gsub(",", ""):gsub("%s+", "")
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

-- Send Webhook Payload
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

    httpRequest({
        Url = WebhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end

-- Main Monitor Loop
print("[JujuZero Tracker]: Tracker initialized with dual UI/Memory reader.")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = "", "", ""

    while true do
        local yen, luman = GetHUDCurrencies()
        local crystal = GetCursedCrystals()

        if yen ~= lastYen or luman ~= lastLuman or crystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = yen, luman, crystal
            SendCombinedEmbed(yen, luman, crystal)
        end

        task.wait(5)
    end
end)
