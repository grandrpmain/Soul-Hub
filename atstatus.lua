local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ConfigsCurrencyPath = "ReplicatedStorage.Configs.ItemConfig.Items.Currency"
local WebhookUrl = "https://discord.com/api/webhooks/1539304499276157049/3UZcBF9rcVH8VeYchanLmBehhx1yTnl7stH71gcB8fJibUJ5RMdfNkxudM9XjH3Ms3a5"

-- Helper: Safely resolve path string to an instance
local function FindCurrencyFolder(path)
    local current = game
    for _, name in ipairs(string.split(path, ".")) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local CurrencyFolder = FindCurrencyFolder(ConfigsCurrencyPath)
if not CurrencyFolder then 
    warn("[JujuZero Tracker]: Could not locate path:", ConfigsCurrencyPath)
    return 
end

print(string.format("[JujuZero Tracker]: Found %d entries under '%s'", #CurrencyFolder:GetChildren(), CurrencyFolder.Name))

-- Debug pass: Print available items
for _, child in ipairs(CurrencyFolder:GetChildren()) do
    local val = child:FindFirstChild("Value") and child.Value or 0
    print(string.format("   -> [%s] = %s", child.Name, tostring(val)))
end

local ItemsToTrack = {"CursedCrystal", "GoldCoin"}
local ItemCountsTable = {}
local DebounceTable = {}

-- Helper: Fetch item value safely
local function GetItemCount(itemName)
    local itemObj = CurrencyFolder:FindFirstChild(itemName)
    if not itemObj then return 0 end
    
    if itemObj:IsA("ValueBase") then
        return itemObj.Value
    elseif itemObj:FindFirstChild("Value") then
        return itemObj.Value.Value
    end
    return 0
end

-- Helper: Safe Webhook HTTP Sender
local function SendWebhook(itemName, count)
    local payload = {
        ["player"] = LocalPlayer.DisplayName or LocalPlayer.Name,
        ["currency"] = itemName,
        ["count"] = count,
        ["timestamp"] = os.time(),
        ["game_name"] = "Jujutsu Zero"
    }

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httpRequest then
        httpRequest({
            Url = WebhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    else
        warn("[JujuZero Tracker]: Executor does not support HTTP requests.")
    end
end

-- Setup tracking for each item
for _, itemName in ipairs(ItemsToTrack) do
    local initialCount = GetItemCount(itemName)
    ItemCountsTable[itemName] = initialCount

    local itemObj = CurrencyFolder:FindFirstChild(itemName)
    if itemObj then
        local target = itemObj:IsA("ValueBase") and itemObj or itemObj:FindFirstChild("Value")
        if target then
            target.Changed:Connect(function(newValue)
                if DebounceTable[itemName] then return end
                DebounceTable[itemName] = true

                print(string.format("[JujuZero Tracker]: %s updated to %s!", itemName, tostring(newValue)))
                ItemCountsTable[itemName] = newValue

                task.spawn(function()
                    SendWebhook(itemName, newValue)
                    task.wait(1)
                    DebounceTable[itemName] = false
                end)
            end)
        end
    end
end

print(string.format("[JujuZero Tracker]: %d currencies now actively tracked.", #ItemsToTrack))
