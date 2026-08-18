local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Hunty Zombie Hub",
    SubTitle = "v1.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark"
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "rbxassetid://10723407068" }),
    Combat = Window:AddTab({ Title = "Combat / Aura", Icon = "rbxassetid://10723345802" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local isFarming = false -- Tracks toggle state

local AutoFarmToggle = Tabs.Main:AddToggle("Door&Zombie", { Title = "Doors&Zombies", Default = false })

AutoFarmToggle:OnChanged(function(Value)
	isFarming = Value -- Update state

	-- 1. IF TOGGLE IS OFF, STOP EVERYTHING IMMEDIATELY
	if not isFarming then 
		print("[-] AutoFarm Disabled")
		return 
	end

	print("[+] AutoFarm Started")

	-- 2. RUN IN A SEPARATE THREAD SO UI DOESN'T FREEZE
	task.spawn(function()
		local doorsFolder = workspace:FindFirstChild("School") and workspace.School:FindFirstChild("Doors")

		---------------------------------------------------------
		-- STEP 1: CYCLE THROUGH ALL DOORS
		---------------------------------------------------------
		if doorsFolder then
			for i, door in ipairs(doorsFolder:GetChildren()) do
				-- Stop mid-loop if player turns toggle OFF
				if not isFarming then break end

				local character = player.Character or player.CharacterAdded:Wait()
				local hrp = character:WaitForChild("HumanoidRootPart")

				local targetCFrame
				if door:IsA("Model") then
					targetCFrame = door:GetPivot()
				elseif door:IsA("BasePart") then
					targetCFrame = door.CFrame
				end

				if targetCFrame then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero

					-- Offset height by 5 studs
					local safePosition = targetCFrame * CFrame.new(0, 5, 3)
					character:PivotTo(safePosition)
					print(string.format("[%d/%d] TP'd to door: %s", i, #doorsFolder:GetChildren(), door.Name))
				end

				task.wait(1.5) -- Time at each door
			end
		end

		---------------------------------------------------------
		-- STEP 2: FARM ZOMBIES CONTINUOUSLY WHILE TOGGLE IS ON
		---------------------------------------------------------
		while isFarming do
			local character = player.Character or player.CharacterAdded:Wait()
			local playerPos = character:GetPivot().Position

			local closestPart = nil
			local shortestDistance = math.huge

			-- Search for the nearest Zombie
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					local entityTeam = obj:GetAttribute("EntityTeam")
					if entityTeam == "Zombie" then
						local distance = (playerPos - obj.Position).Magnitude
						if distance < shortestDistance then
							shortestDistance = distance
							closestPart = obj
						end
					end
				end
			end

			-- Teleport to closest Zombie
			if closestPart and isFarming then
				local targetCFrame = closestPart.CFrame * CFrame.new(0, -3, 3)
				character:PivotTo(targetCFrame)
				print("Teleported to Zombie:", closestPart:GetAttribute("EntityVariant") or "Basic")
			end

			task.wait(1) -- Delay between zombie scans
		end
	end)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable")

local isSkillEnabled = false

-- Function to construct and send the ByteNet skill packet
local function useSkill()
	local rawBytes = { 18, 1, 215, 49, 56, 253, 57, 161, 218, 65 }
	local b = buffer.create(#rawBytes)
	
	for i, byte in ipairs(rawBytes) do
		buffer.writeu8(b, i - 1, byte)
	end
	
	ByteNetReliable:FireServer(b, nil)
end

-- Toggle Setup
local SkillToggle = Tabs.Main:AddToggle("Skill", { Title = "Skill", Default = false })

SkillToggle:OnChanged(function(Value)
	isSkillEnabled = Value

	-- Stop immediately if toggled off
	if not isSkillEnabled then 
		return 
	end

	-- Run in a thread so UI doesn't freeze
	task.spawn(function()
		while isSkillEnabled do
			useSkill()
			task.wait(0.2) -- Delay between skill uses (adjust if skill has a cooldown)
		end
	end)
end)


Window:SelectTab(1)
