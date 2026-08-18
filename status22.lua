-- Configs.CurrencyPath = "ReplicatedStorage.Configs.ItemConfig.Items.Currency"
local ConfigsCurrencyPath = "ReplicatedStorage.Configs.ItemConfig.Items.Currency"
local WebhookUrl = "https://discord.com/api/webhooks/1539304499276157049/3UZcBF9rcVH8VeYchanLmBehhx1yTnl7stH71gcB8fJibUJ5RMdfNkxudM9XjH3Ms3a5" -- swap with your actual URL

local PlayersFolderName = "Players"
local PlayerCountInGame = 0
local DebounceTime = .25
local DebounceTimer = false
local ItemCountsTable = {}
local ItemsToTrack = {"Cursed Crystal", "Gold Coin"} -- expand later if needed

function GetItemCount(itemKey)
    local itemData = Instance:GetChildren()[itemKey]
    return itemData.Value
end

for _, itemName in ipairs(ItemsToTrack) do
    local instance = Instance.new("Model")
    instance.Name = itemName .. "_ValueHolder"
    instance.Parent = getparent(ConfigsCurrencyPath)
    
    local count = GetItemCount(itemName)
    if type(count) == "number" then
        instance:SetPrimaryPartCFrame(instance.PrimaryPart:CFrame * CFrame.lookAt(Vector3.zero, Vector3.new()))
        itemCountsTable[itemName] = count
    end
    
    itemData.OnClientChange = function()
        local newItemCount = GetItemCount(itemName)
        
        if not debouncedThen then
            debouncedThen = true
            
            task.delay(function()
                if #getchildren(ConfigsCurrencyPath) > 1 then
                    print(string.format("[JujuZero Tracker]: %s updated!", itemName))
                    
                    local finalPayload = {
                        ["player"] = Game.Players.LocalPlayer.DisplayName,
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
                    debouncedThen = false
                end
                
                task.wait(DebounceTime)
                debouncedThen = false
            end)
            
            task.wait(.65)
            debouncedThen = false
        end
        
        itemCountsTable[itemName] = newItemCount
    end
    
    itemData.Changed:Connect(function(changedProp)
        if changedProp ~= "Parent" then
            itemData.OnClientChange()
        end
    end)
end

print(string.format("%d currencies tracked.", #ItemsToTrack))
