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

-- Auto-Open Inventory / Supplies Frames in UI
local function EnsureSuppliesOpen()
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("GuiObject") then
                        local n = obj.Name:lower()
                        if n:find("supplies") or n:find("inventory") or n:find("all items") then
                            obj.Visible = true
                        end
                    end
                end
            end
        end
    end)
end

-- Direct UI Inventory Slot Reader (Zero GC Memory Scanning)
local function GetCursedCrystalsFromUI()
    EnsureSuppliesOpen()

    local resultAmount = nil

    pcall(function()
        -- Scan every TextLabel in PlayerGui for item quantities (e.g. x107,514)
        for _, desc in ipairs(PlayerGui:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:find("x%d") then
                local cleanStr = desc.Text:gsub("x", ""):gsub(",", ""):gsub("%s+", "")
                local val = tonumber(cleanStr)

                if val and val > 0 then
                    local container = desc.Parent
                    
                    -- Check container and ancestors up 4 levels for Cursed Crystal identifiers
                    for level = 1, 4 do
                        if not container or container == PlayerGui then break end

                        local isMatch = false
                        for _, child in ipairs(container:GetDescendants()) do
                            if child:IsA("TextLabel") then
                                local t = child.Text:lower()
                                if t:find("cursed") or t:find("crystal") then
                                    isMatch = true
                                    break
                                end
                            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                                local img = (child.Image or ""):lower()
                                local cn = child.Name:lower()
                                if cn:find("cursed") or cn:find("crystal") or img:find("crystal") then
                                    isMatch = true
                                    break
                                end
                            end
                        end

                        if isMatch then
                            resultAmount = FormatNumber(val)
                            return
                        end
                        container = container.Parent
                    end
                end
            end
        end
    end)

    if resultAmount then return resultAmount end

    -- Secondary UI fallback: Check for active slot detail panel
    pcall(function()
        for _, desc in ipairs(PlayerGui:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:find("x%d") then
                local cleanStr = desc.Text:gsub("x", ""):gsub(",", ""):gsub("%s+", "")
                local val = tonumber(cleanStr)
                -- Match typical inventory crystal stack range
                if val and val > 50000 and val < 500000 then
                    resultAmount = FormatNumber(val)
                end
            end
        end
    end)

    return resultAmount or "N/A"
end

-- Read Yen and Luman from HUD Labels
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

-- Monitor Loop
print("[JujuZero Tracker]: UI-Direct Inventory Reader Initialized.")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = "", "", ""

    while true do
        local yen, luman = GetHUDCurrencies()
        local crystal = GetCursedCrystalsFromUI()

        if yen ~= lastYen or luman ~= lastLuman or crystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = yen, luman, crystal
            print(string.format("[JujuZero Tracker]: Yen: %s | Luman: %s | Cursed Crystal: %s", yen, luman, crystal))
            SendCombinedEmbed(yen, luman, crystal)
        end

        task.wait(5)
    end
end)
