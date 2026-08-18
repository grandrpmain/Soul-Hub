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

-- Helper: Format numbers with commas (e.g. 107514 -> 107,514)
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

-- Helper: Clean raw text
local function CleanText(str)
    if not str or str == "" or str == "N/A" then return "N/A" end
    local clean = str:gsub("x", ""):gsub("%s+", "")
    local num = tonumber(clean:gsub(",", ""))
    if num then
        return FormatNumber(num)
    end
    return str
end

-- Smart Cursed Crystal Finder
local function GetCursedCrystals()
    -- Priority 1: Scan PlayerGui inventory slots directly (matches x107,514)
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text:find("x%d") then
            local cleanStr = desc.Text:gsub("x", ""):gsub(",", ""):gsub("%s+", "")
            local val = tonumber(cleanStr)

            if val then
                -- Search slot frame and ancestors up 4 levels for item name or icon match
                local container = desc.Parent
                for level = 1, 4 do
                    if not container or container == PlayerGui then break end

                    for _, child in ipairs(container:GetDescendants()) do
                        local nameMatch = false
                        
                        if child:IsA("TextLabel") then
                            local t = child.Text:lower()
                            if t:find("cursed") or t:find("crystal") then nameMatch = true end
                        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            local img = (child.Image or ""):lower()
                            local n = child.Name:lower()
                            if n:find("cursed") or n:find("crystal") or img:find("crystal") then nameMatch = true end
                        end

                        if nameMatch then
                            return FormatNumber(val)
                        end
                    end
                    container = container.Parent
                end
            end
        end
    end

    -- Priority 2: Check for direct text format ("Cursed Crystal: 107,514")
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local t = desc.Text:lower()
            if t:find("cursed") and t:find("crystal") then
                local numStr = desc.Text:match("[%d%,]+")
                if numStr then
                    local val = tonumber((numStr:gsub(",", "")))
                    if val and val > 0 then
                        return FormatNumber(val)
                    end
                end
            end
        end
    end

    -- Priority 3: Search LocalPlayer ValueObjects
    for _, obj in ipairs(LocalPlayer:GetDescendants()) do
        if obj:IsA("ValueObject") or obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
            local n = obj.Name:lower()
            if n:find("cursed") or n:find("crystal") then
                local val = tonumber(obj.Value)
                if val and val > 0 and val < 1000000 then -- Filter out 1M+ stat counters
                    return FormatNumber(val)
                end
            end
        end
    end

    -- Priority 4: Filtered GC memory fallback (picks exact stack < 1M)
    local targetCount = 0
    local visited = {}

    for _, tbl in ipairs(getgc(true)) do
        if type(tbl) == "table" and not visited[tbl] then
            visited[tbl] = true
            if rawget(tbl, 1) == "CursedCrystal" or tbl[1] == "CursedCrystal" then
                local count = tonumber(tbl[2]) or 0
                -- Exclude stat pools (>1M) and prioritize stack amount (~100k)
                if count > targetCount and count < 1000000 then
                    targetCount = count
                end
            end
        end
    end

    if targetCount > 0 then
        return FormatNumber(targetCount)
    end

    return "N/A"
end

-- Read HUD Currencies
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

    httpRequest({
        Url = WebhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end

-- Background Monitoring Loop
print("[JujuZero Tracker]: Active inventory slot scanner initialized.")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = "", "", ""

    while true do
        local yen, luman = GetHUDCurrencies()
        local crystal = GetCursedCrystals()

        if yen ~= lastYen or luman ~= lastLuman or crystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = yen, luman, crystal
            print(string.format("[JujuZero Tracker]: Yen: %s | Luman: %s | Cursed Crystal: %s", yen, luman, crystal))
            SendCombinedEmbed(yen, luman, crystal)
        end

        task.wait(5)
    end
end)
