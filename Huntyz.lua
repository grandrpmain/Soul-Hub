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
    Main = Window:AddTab({ Title = "Main", Icon = "rbxassetid://10723407068" }),
    Combat = Window:AddTab({ Title = "Testing", Icon = "rbxassetid://10723345802" }),
    Lobby = Window:AddTab({ Title = "Lobby", Icon = "rbxassetid://10723345802" }),
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

-- List of skill keys to press in sequence
local SKILL_KEYS = {
	Enum.KeyCode.Z,
	Enum.KeyCode.X,
	Enum.KeyCode.C,
	Enum.KeyCode.V,
	Enum.KeyCode.G
}

-- Helper function to simulate keypresses
local function pressKey(keyCode)
	VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local SkillToggle = Tabs.Main:AddToggle("Skill", { Title = "Multi-Skill Spammer", Default = false })

SkillToggle:OnChanged(function(Value)
	isSkillEnabled = Value

	-- Stop existing thread immediately if toggle state changes
	if skillThread then
		task.cancel(skillThread)
		skillThread = nil
	end

	if not isSkillEnabled then 
		print("[-] Multi-Skill Spammer Disabled")
		return 
	end

	print("[+] Multi-Skill Spammer Started")

	skillThread = task.spawn(function()
		task.wait(0.2) -- Small initial delay so clicking the UI toggle finishes cleanly

		while isSkillEnabled do
			-- Cycle through Z, X, C, V, G
			for _, key in ipairs(SKILL_KEYS) do
				if not isSkillEnabled then break end
				pressKey(key)
				task.wait(0.05) -- Delay between each keypress
			end

			task.wait(0.2) -- Delay before repeating the rotation
		end
	end)
end)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- List of active codes
local codesList = {
	"Anniversary!",
	"ScytheEvolution!",
	"Dubstep!",
	"HappyBirthday!",
	"PartyBreaker!",
	"SorryForBadCode",
	"VeryHotHotfixes"
}

-- Add button to your UI Tab
Tabs.Lobby:AddButton({
	Title = "Redeem All Codes",
	Description = "Automatically redeems all active promo codes",
	Callback = function()
		-- Run in a thread so it doesn't freeze the UI
		task.spawn(function()
			print("[+] Starting code redemption process...")

			local playerGui = player:WaitForChild("PlayerGui")

			for i, code in ipairs(codesList) do
				-- Safely find the TextBox path without breaking if the UI is hidden
				local guiFolder = playerGui:FindFirstChild("GUI")
				local codesFrame = guiFolder and guiFolder:FindFirstChild("Codes")
				local content = codesFrame and codesFrame:FindFirstChild("Content")
				local searchBar = content and content:FindFirstChild("SearchBar")
				local textBox = searchBar and searchBar:FindFirstChild("TextBox")

				if textBox and textBox:IsA("TextBox") then
					-- Step 1: Set the text to the code
					textBox.Text = code
					task.wait(0.1)

					-- Step 2: Focus and Release Focus with 'true' (Simulates pressing Enter to submit)
					textBox:CaptureFocus()
					task.wait(0.05)
					textBox:ReleaseFocus(true)

					print(string.format("[%d/%d] Redeemed: %s", i, #codesList, code))
				else
					warn("[-] Codes UI not found! Please open the Codes menu in-game first.")
				end

				-- Step 3: Wait 1.5 seconds before processing the next code
				task.wait(1.5)
			end

			print("[+] Finished redeeming all codes!")
		end)
	end
})


Window:SelectTab(1)
