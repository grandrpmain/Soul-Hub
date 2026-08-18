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

-- Helper: Clean text formatting
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
        print("[JujuZero Tracker]: Consolidated webhook update sent successfully!")
    else
        warn(string.format("[JujuZero Tracker]: Webhook failed (Status: %s)", tostring(response.StatusCode)))
    end
end

-- Locate HUD labels (Yen & Luman) and Inventory label (Cursed Crystal)
local yenLabel, lumanLabel, crystalLabel

local hud = PlayerGui:FindFirstChild("HUD")
if hud then
    local hudLabels = {}
    for _, desc in ipairs(hud:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text:find("%d") then
            table.insert(hudLabels, desc)
        end
    end

    -- Identify Yen vs Luman by character/value match or position
    for _, label in ipairs(hudLabels) do
        local cleanNum = label.Text:gsub(",", "")
        if cleanNum:find("657") or (tonumber(cleanNum) and tonumber(cleanNum) > 10000000) then
            yenLabel = label
        elseif cleanNum:find("2207") or (tonumber(cleanNum) and tonumber(cleanNum) > 100000 and tonumber(cleanNum) < 10000000) then
            lumanLabel = label
        end
    end
    
    -- Fallback assignment if numbers fluctuate significantly
    if not yenLabel and #hudLabels >= 1 then yenLabel = hudLabels[1] end
    if not lumanLabel and #hudLabels >= 2 then lumanLabel = hudLabels[2] end
end

-- Scan Inventory for Cursed Crystal UI Label
for _, desc in ipairs(PlayerGui:GetDescendants()) do
    if desc:IsA("TextLabel") and (desc.Text:find("x10") or desc.Text:find("x106") or desc.Text:find("106,")) then
        crystalLabel = desc
        break
    end
end

-- Print hook status to console
print(string.format("[JujuZero Tracker]: Yen = %s", yenLabel and yenLabel.Text or "Not Found"))
print(string.format("[JujuZero Tracker]: Luman = %s", lumanLabel and lumanLabel.Text or "Not Found"))
print(string.format("[JujuZero Tracker]: Cursed Crystal = %s", crystalLabel and crystalLabel.Text or "Not Found"))

-- Run initial post and bind real-time listeners
if yenLabel or lumanLabel or crystalLabel then
    SendCombinedEmbed(
        yenLabel and yenLabel.Text or "N/A",
        lumanLabel and lumanLabel.Text or "N/A",
        crystalLabel and crystalLabel.Text or "N/A"
    )

    local debounce = false
    local function OnCurrencyChanged()
        if debounce then return end
        debounce = true
        task.wait(0.5)

        SendCombinedEmbed(
            yenLabel and yenLabel.Text or "N/A",
            lumanLabel and lumanLabel.Text or "N/A",
            crystalLabel and crystalLabel.Text or "N/A"
        )

        task.wait(2) -- Rate-limit protection
        debounce = false
    end

    if yenLabel then yenLabel:GetPropertyChangedSignal("Text"):Connect(OnCurrencyChanged) end
    if lumanLabel then lumanLabel:GetPropertyChangedSignal("Text"):Connect(OnCurrencyChanged) end
    if crystalLabel then crystalLabel:GetPropertyChangedSignal("Text"):Connect(OnCurrencyChanged) end
else
    warn("[JujuZero Tracker]: Could not locate UI labels. Keep your inventory menu open when running the script!")
end
