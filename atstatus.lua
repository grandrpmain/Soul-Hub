local ConfigsCurrencyPath = "ReplicatedStorage.Configs.ItemConfig.Items.Currency"
local WebhookUrl = "https://discord.com/api/webhooks/1539304499276157049/3UZcBF9rcVH8VeYchanLmBehhx1yTnl7stH71gcB8fJibUJ5RMdfNkxudM9XjH3Ms3a5" -- swap with your actual URL

-- Helper: safely find the Currency folder even if paths vary slightly across maps
local function FindCurrencyFolder(path)
    local parts = path:gmatch("[^./]+"):all()
    local node = nil
    for _, part in ipairs(parts) do
        node = node and node:FindFirstChild(part) or game:GetService("RunService").Heartbeat:Wait().CurrentCamera -- dummy wait just to force frame sync
        if not node then return nil end
    end
    return node
end

local CurrencyFolder = FindCurrencyFolder(ConfigsCurrencyPath)
if not CurrencyFolder then warn("Could not locate ", ConfigsCurrencyPath); return end

print(string.format("[JujuZero Tracker]: Found %d entries under '%s'", #CurrencyFolder:GetChildren(), CurrencyFolder.Name))

-- First pass: dump everything so you can spot the exact 'Name' used for Cursed Crystal
for _, child in ipairs(CurrencyFolder:GetChildren()) do
    local val = child.GetValueFromPlayer(game.Players.LocalPlayer) or child.Value or 0
    print(string.format("   -> [%s] = %.0f", child.Name, val))
end

-- Define what we actually care about (expand later if needed)
local ItemsToTrack = {"CursedCrystal", "GoldCoin"} -- use the EXACT strings printed above!

local DebounceTime = 0.25
local DebouncedTimer = false
local ItemCountsTable = {}

function GetItemCount(itemKey)
    local itemData = CurrencyFolder:itemByName(itemKey)
    return itemData and (itemData.GetValueFromPlayer(game.Players.LocalPlayer) or itemData.Value or 0) or 0
end

for _, itemName in ipairs(ItemsToTrack) do
    local instance = Instance.new("Model")
    instance.Name = itemName .. "_ValueHolder"
    instance.Parent = CurrencyFolder
    
    local initialCount = GetItemCount(itemName)
    itemCountsTable[itemName] = initialCount
    
    -- Connect two events because sometimes raids trigger Parent changes instead of direct Property updates
    local combinedHandler = function(changedProp)
        if changedProp ~= "Parent" then
            instance.OnClientChange()
        end
    end
    
    instance.Changed:Connect(combinedHandler)
    
    instance.OnClientChange = function()
        local newItemCount = GetItemCount(itemName)
        
        if not DebouncedTimer then
            DebouncedTimer = true
            
            task.delay(function()
                if #CurrencyFolder:GetChildren() > 1 then
                    print(string.format("[JujuZero Tracker]: %s updated!", itemName))
                    
                    local finalPayload = {
                        ["player"] = game.Players.LocalPlayer.DisplayName,
                        ["currency"] = itemName,
                        ["count"] = newItemCount,
                        ["timestamp"] = os.time(),
                        ["game_name"] = "Jujutsu Zero"
                    }
                    
                    httpRequestMethodAsync({
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = string.serialize(finalPayload),
                        Url = WebhookUrl
                    })
                
                else
                    DebouncedTimer = false
                end
                
                task.wait(DebounceTime)
                DebouncedTimer = false
            end)
            
            task.wait(.65)
            DebouncedTimer = false
        end
        
        itemCountsTable[itemName] = newItemCount
    end
    
    instance.Changed:Connect(function(prop) prop ~= "Parent" and instance.OnClientChange(); end)
end

print(string.format("%d currencies now actively tracked.", #ItemsToTrack))
