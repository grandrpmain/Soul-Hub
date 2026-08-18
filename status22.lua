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

-- Helper: Clean up raw text formatting
local function CleanText(str)
    if not str or str == "" then return "N/A" end
    return str:gsub("x", ""):gsub("%s+", "")
end

-- Helper: Send Multi-Currency Discord Embed
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
                ["footer"] = { ["text"] = "Jujutsu Zero Monitoring" },
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
        print("[JujuZero Tracker]: Webhook update sent successfully!")
    else
        warn(string.format("[JujuZero Tracker]: Webhook failed (Status: %s)", tostring(response.StatusCode)))
    end
end

-- Dynamic UI Finder (Reads live values directly from UI structure)
local function GetCurrencies()
    local yenText, lumanText, crystalText = "N/A", "N/A", "N/A"

    -- 1. Fetch HUD Currencies (Yen & Luman)
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

    -- 2. Fetch Cursed Crystal dynamically from Inventory UI
    local fullMenus = PlayerGui:FindFirstChild("FullMenus")
    if fullMenus then
        for _, desc in ipairs(fullMenus:GetDescendants()) do
            if desc:IsA("TextLabel") and (desc.Text:find("x") or desc.Text:find("%d")) then
                local parent = desc.Parent
                local isCrystal = false
                
                -- Traverse parent hierarchy for "Cursed" or "Crystal" keywords
                while parent and parent ~= fullMenus do
                    local nameLower = parent.Name:lower()
                    if nameLower:find("cursed") or nameLower:find("crystal") then
                        isCrystal = true
                        break
                    end
                    parent = parent.Parent
                end

                -- Fallback: Check sibling element names/images
                if not isCrystal and desc.Parent then
                    for _, sibling in ipairs(desc.Parent.Parent:GetDescendants()) do
                        local sName = sibling.Name:lower()
                        if sName:find("crystal") or sName:find("cursed") then
                            isCrystal = true
                            break
                        end
                    end
                end

                if isCrystal then
                    crystalText = desc.Text
                    break
                end
            end
        end
    end

    return yenText, lumanText, crystalText
end

-- Active Monitoring Loop
print("[JujuZero Tracker]: Initializing dynamic UI tracker...")

task.spawn(function()
    local lastYen, lastLuman, lastCrystal = "", "", ""
    
    while task.wait(2) do
        local currentYen, currentLuman, currentCrystal = GetCurrencies()
        
        -- Trigger update if any balance changes
        if currentYen ~= lastYen or currentLuman ~= lastLuman or currentCrystal ~= lastCrystal then
            lastYen, lastLuman, lastCrystal = currentYen, currentLuman, currentCrystal
            
            print(string.format("[JujuZero Tracker]: Live Sync -> Yen: %s | Luman: %s | Crystal: %s", currentYen, currentLuman, currentCrystal))
            SendCombinedEmbed(currentYen, currentLuman, currentCrystal)
        end
    end
end)
