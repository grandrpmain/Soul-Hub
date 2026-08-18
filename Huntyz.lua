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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable")

---------------------------------------------------------
-- 1. DOOR & ZOMBIE AUTOFARM
---------------------------------------------------------
local isFarming = false
local farmThread = nil

local AutoFarmToggle = Tabs.Main:AddToggle("Door&Zombie", { Title = "Doors&Zombies", Default = false })

AutoFarmToggle:OnChanged(function(Value)
	isFarming = Value

	-- Cancel any previously running farm thread immediately
	if farmThread then
		task.cancel(farmThread)
		farmThread = nil
	end

	if not isFarming then 
		print("[-] AutoFarm Disabled")
		return 
	end

	print("[+] AutoFarm Started")

	farmThread = task.spawn(function()
		local doorsFolder = workspace:FindFirstChild("School") and workspace.School:FindFirstChild("Doors")

		-- STEP 1: CYCLE THROUGH ALL DOORS
		if doorsFolder then
			for i, door in ipairs(doorsFolder:GetChildren()) do
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

				task.wait(1.5)
			end
		end

		-- STEP 2: FARM ZOMBIES CONTINUOUSLY
		while isFarming do
			local character = player.Character or player.CharacterAdded:Wait()
			local playerPos = character:GetPivot().Position

			local closestPart = nil
			local shortestDistance = math.huge

			-- Find nearest Zombie
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

			-- Teleport to Zombie
			if closestPart then
				local targetCFrame = closestPart.CFrame * CFrame.new(0, -3, 3)
				character:PivotTo(targetCFrame)
				print("Teleported to Zombie:", closestPart:GetAttribute("EntityVariant") or "Basic")
			end

			task.wait(1)
		end
	end)
end)


---------------------------------------------------------
-- 2. AUTOMATIC SKILL SPAMMER
---------------------------------------------------------
local VirtualInputManager = game:GetService("VirtualInputManager")

local isSkillEnabled = false
local skillThread = nil

-- CHANGE THIS to your game's skill key (e.g., Enum.KeyCode.Q, Enum.KeyCode.One, etc.)
local SKILL_KEY = Enum.KeyCode.Z 

local SkillToggle = Tabs.Main:AddToggle("Skill", { Title = "Skill Spammer", Default = false })

SkillToggle:OnChanged(function(Value)
	isSkillEnabled = Value

	-- Cancel existing thread if running
	if skillThread then
		task.cancel(skillThread)
		skillThread = nil
	end

	if not isSkillEnabled then 
		print("[-] Skill Spammer Disabled")
		return 
	end

	print("[+] Skill Spammer Started")

	skillThread = task.spawn(function()
		while isSkillEnabled do
			-- Simulate keypress
			VirtualInputManager:SendKeyEvent(true, SKILL_KEY, false, game)
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(false, SKILL_KEY, false, game)

			task.wait(0.3) -- Cooldown between presses (adjust as needed)
		end
	end)
end)


Window:SelectTab(1)
