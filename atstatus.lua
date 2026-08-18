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

-- Helper: Format Numbers with Commas safely in Luau
local function FormatNumber(numStr)
    local clean = tostring(numStr):gsub("[^%d]", "")
    if #clean == 0 then return numStr end
    
    local formatted = clean:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end
    return formatted
end

-- Helper: Send Formatted Discord Embed
local function SendDiscordEmbed(currencyName, rawAmount)
    local formattedAmount = FormatNumber(rawAmount)

    local payload = {
        ["username"] = "Jujutsu Zero Tracker",
        ["avatar_url"] = "https://i.imgur.com/8N3L4yP.png",
        ["embeds"] = {
            {
                ["title"] = "Currency Tracker Update",
                ["color"] = 65280, -- Green
                ["fields"] = {
                    { ["name"] = "Player", ["value"] = LocalPlayer.DisplayName or LocalPlayer.Name, ["inline"] = true },
                    { ["name"] = "Currency", ["value"] = currencyName, ["inline"] = true },
                    { ["name"] = "Amount", ["value"] = formattedAmount, ["inline"] = false }
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
        print(string.format("[JujuZero Tracker]: Discord update sent! %s = %s", currencyName, formattedAmount))
    else
        warn(string.format("[JujuZero Tracker]: Failed to send (Status: %s)", tostring(response.StatusCode)))
    end
end

-- Locate the target UI label displaying Cursed Crystals
local function FindCurrencyLabel()
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        if desc:IsA("TextLabel") and (desc.Text:find("104") or desc.Text:find("594")) then
            return desc
        end
    end
    return nil
end

local targetLabel = FindCurrencyLabel()

if targetLabel then
    print("[JujuZero Tracker]: Active and attached to UI element!")
    
    -- Send initial update
    SendDiscordEmbed("Cursed Crystal", targetLabel.Text)
    
    -- Monitor live updates
    local lastText = targetLabel.Text
    local debounce = false

    targetLabel:GetPropertyChangedSignal("Text"):Connect(function()
        if debounce or targetLabel.Text == lastText then return end
        debounce = true
        lastText = targetLabel.Text

        SendDiscordEmbed("Cursed Crystal", targetLabel.Text)

        task.wait(2) -- Rate-limit protection
        debounce = false
    end)
else
    warn("[JujuZero Tracker]: Could not find UI Label. Keep your Supplies/Inventory menu open when launching the script!")
end
