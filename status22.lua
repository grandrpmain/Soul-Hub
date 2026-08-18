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

-- Helper: Format numbers with commas (e.g. 106638 -> 106,638)
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

-- Helper: Clean raw text values
local function CleanText(str)
    if not str or str == "" or str == "N/A" then return "N/A" end
    local clean = str:gsub("x", ""):gsub("%s+", "")
    local num = tonumber(clean:gsub(",", ""))
    if num then
        return FormatNumber(num)
    end
    return str
end

-- Memory Reader: Scans GC memory for live Cursed Crystal count (AFK Friendly)
local function GetCursedCrystalsFromMemory()
    local totalCrystals = 0
    local visitedTables = {}
    local matchesFound = 0

    for _, tbl in ipairs(getgc(true)) do
        if type(tbl) == "table" and not visitedTables[tbl] then
            visitedTables[tbl] = true
            
            -- Match Cursed Crystal item entry structure from GC
            if rawget(tbl, 1) == "CursedCrystal" or tbl[1] == "CursedCrystal" then
                local count = tonumber(tbl[2]) or 0
                local multiplier = tonumber(tbl[5]) or 1
                
                totalCrystals = totalCrystals + (count * multiplier)
                matchesFound = matchesFound + 1
            end
        end
    end

    if matchesFound > 0 then
        return FormatNumber(totalCrystals)
    end
    
    return "N/A"
end

-- HUD Reader: Get Yen and Luman from HUD labels
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

-- Webhook Embed Sender
local function SendCombinedEmbed(yenVal, lumanVal, crystalVal)
    local payload = {
        ["username"] = "Jujutsu Zero Tracker",
        ["avatar_url"] = "https://i.imgur.com/8N3L4yP.png",
        ["embeds"] = {
            {
                ["title"] = "Currency Tracker Update",
                ["color"] = 65280, -- Green
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

    local response = httpRequest({
        Url = WebhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })

    if response.StatusCode == 200 or response.StatusCode == 204 then
        print("[JujuZero Tracker]: Discord webhook updated successfully!")
    else
        warn(string.format("[JujuZero Tracker]: Webhook failed (Status: %s)", tostring(response.StatusCode)))
    end
end

-- AFK Loop (Runs in background every 5 seconds)
print("[JujuZero Tracker]: Starting background AFK monitor...")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = "", "", ""

    while true do
        local yen, luman = GetHUDCurrencies()
        local crystal = GetCursedCrystalsFromMemory()

        -- Send update whenever any currency balance changes
        if yen ~= lastYen or luman ~= lastLuman or crystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = yen, luman, crystal
            
            print(string.format("[JujuZero Tracker]: Sync -> Yen: %s | Luman: %s | Cursed Crystal: %s", yen, luman, crystal))
            SendCombinedEmbed(yen, luman, crystal)
        end

        task.wait(5)
    end
end)
