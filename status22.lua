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

local function CleanText(str)
    if not str or str == "" or str == "N/A" then return "N/A" end
    local clean = str:gsub("x", ""):gsub("%s+", "")
    local num = tonumber(clean:gsub(",", ""))
    if num then
        return FormatNumber(num)
    end
    return str
end

-- Safe Memory GC Reader (Uses STRICT rawget to prevent Sleitnick Signal __index crashes)
local function GetCrystalFromGC()
    local foundVal = nil

    pcall(function()
        for _, tbl in ipairs(getgc(true)) do
            if typeof(tbl) == "table" then
                -- Method 1: Key-value pair {"Cursed Crystal" = 107514}
                local k1 = rawget(tbl, "Cursed Crystal") or rawget(tbl, "CursedCrystal") or rawget(tbl, "cursed_crystal")
                if typeof(k1) == "number" and k1 > 0 then
                    foundVal = k1
                    break
                end

                -- Method 2: Array entry {"CursedCrystal", 107514} or {Name = "Cursed Crystal", Count = 107514}
                local name = rawget(tbl, "Name") or rawget(tbl, "name") or rawget(tbl, "Item") or rawget(tbl, 1)
                if name == "Cursed Crystal" or name == "CursedCrystal" or name == "cursed_crystal" then
                    local count = rawget(tbl, "Amount") or rawget(tbl, "amount") or rawget(tbl, "Count") or rawget(tbl, "count") or rawget(tbl, "Value") or rawget(tbl, 2)
                    if typeof(count) == "number" and count > 0 and count < 1000000 then
                        foundVal = count
                        break
                    end
                end
            end
        end
    end)

    return foundVal
end

-- Auto-Open Inventory UI and Scan Slots
local function OpenAndScanInventoryUI()
    local foundVal = nil

    pcall(function()
        -- Force-open inventory / supplies frames in PlayerGui
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("GuiObject") then
                        local n = desc.Name:lower()
                        if n:find("supplies") or n:find("inventory") or n:find("menu") then
                            desc.Visible = true
                        end
                    end
                end
            end
        end

        -- Check detail panel or item labels for "Cursed Crystal"
        for _, desc in ipairs(PlayerGui:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text:lower()
                if txt:find("cursed") and txt:find("crystal") then
                    -- Search parent container for quantity label (e.g. x107,514)
                    local container = desc.Parent
                    for level = 1, 5 do
                        if not container or container == PlayerGui then break end
                        for _, child in ipairs(container:GetDescendants()) do
                            if child:IsA("TextLabel") and child.Text:find("x%d") then
                                local cleanNum = child.Text:gsub("x", ""):gsub(",", ""):gsub("%s+", "")
                                local val = tonumber(cleanNum)
                                if val and val > 0 then
                                    foundVal = val
                                    return
                                end
                            end
                        end
                        container = container.Parent
                    end
                end
            end
        end
    end)

    return foundVal
end

-- Combined Cursed Crystal Fetcher
local function GetCursedCrystals()
    -- 1. Try safe memory extraction
    local gcVal = GetCrystalFromGC()
    if gcVal then
        return FormatNumber(gcVal)
    end

    -- 2. Try UI Auto-Open + Direct Slot Scan
    local uiVal = OpenAndScanInventoryUI()
    if uiVal then
        return FormatNumber(uiVal)
    end

    -- 3. Fallback: Search Player Value Objects
    local valObj = nil
    pcall(function()
        for _, obj in ipairs(LocalPlayer:GetDescendants()) do
            if obj:IsA("ValueObject") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if n:find("cursed") or n:find("crystal") then
                    if obj.Value and obj.Value > 0 and obj.Value < 1000000 then
                        valObj = obj.Value
                        break
                    end
                end
            end
        end
    end)

    if valObj then
        return FormatNumber(valObj)
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

-- Main Monitoring Loop
print("[JujuZero Tracker]: Optimized Dual Memory/UI Tracker Active.")

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
