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
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- Use timeouts on WaitForChild so the script NEVER freezes if a remote/folder is missing in Lobby
local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable", 2)

---------------------------------------------------------
-- TAB 1: MAIN (AutoFarm)
---------------------------------------------------------
local isFarming = false
local farmThread = nil

local AutoFarmToggle = Tabs.Main:AddToggle("Door&Zombie", { Title = "Doors&Zombies", Default = false })

AutoFarmToggle:OnChanged(function(Value)
	isFarming = Value

	if farmThread then
		task.cancel(farmThread)
		farmThread = nil
	end

	if not isFarming then return end

	farmThread = task.spawn(function()
		-- Safe check: Only searches for doors when the toggle is ON
		local school = workspace:FindFirstChild("School")
		local doorsFolder = school and school:FindFirstChild("Doors")

		if doorsFolder then
			for i, door in ipairs(doorsFolder:GetChildren()) do
				local character = player.Character or player.CharacterAdded:Wait()
				local hrp = character:FindFirstChild("HumanoidRootPart")

				if hrp then
					local targetCFrame = door:IsA("Model") and door:GetPivot() or door.CFrame
					if targetCFrame then
						hrp.AssemblyLinearVelocity = Vector3.zero
						character:PivotTo(targetCFrame * CFrame.new(0, 5, 3))
					end
				end
				task.wait(1.5)
			end
		else
			warn("[-] School/Doors folder not found (You are likely in the Lobby!)")
		end

		-- Zombie Loop
		while isFarming do
			local character = player.Character or player.CharacterAdded:Wait()
			local playerPos = character:GetPivot().Position
			local closestPart = nil
			local shortestDistance = math.huge

			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") and obj:GetAttribute("EntityTeam") == "Zombie" then
					local distance = (playerPos - obj.Position).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestPart = obj
					end
				end
			end

			if closestPart then
				character:PivotTo(closestPart.CFrame * CFrame.new(0, -3, 3))
			end

			task.wait(1)
		end
	end)
end)

---------------------------------------------------------
-- TAB 2: TESTING (Skill Spammer)
---------------------------------------------------------
local isSkillEnabled = false
local skillThread = nil
local SKILL_KEYS = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.G }

local function pressKey(keyCode)
	VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local SkillToggle = Tabs.Testing:AddToggle("Skill", { Title = "Multi-Skill Spammer", Default = false })

SkillToggle:OnChanged(function(Value)
	isSkillEnabled = Value

	if skillThread then
		task.cancel(skillThread)
		skillThread = nil
	end

	if not isSkillEnabled then return end

	skillThread = task.spawn(function()
		task.wait(0.2)
		while isSkillEnabled do
			for _, key in ipairs(SKILL_KEYS) do
				if not isSkillEnabled then break end
				pressKey(key)
				task.wait(0.05)
			end
			task.wait(0.2)
		end
	end)
end)

---------------------------------------------------------
-- TAB 3: LOBBY (Code Redeemer)
---------------------------------------------------------
local codesList = {
	"Anniversary!",
	"ScytheEvolution!",
	"Dubstep!",
	"HappyBirthday!",
	"PartyBreaker!",
	"SorryForBadCode",
	"VeryHotHotfixes"
}

Tabs.Lobby:AddButton({
	Title = "Redeem All Codes",
	Description = "Automatically redeems all active promo codes",
	Callback = function()
		task.spawn(function()
			local playerGui = player:WaitForChild("PlayerGui")

			for i, code in ipairs(codesList) do
				local guiFolder = playerGui:FindFirstChild("GUI")
				local codesFrame = guiFolder and guiFolder:FindFirstChild("Codes")
				local content = codesFrame and codesFrame:FindFirstChild("Content")
				local searchBar = content and content:FindFirstChild("SearchBar")
				local textBox = searchBar and searchBar:FindFirstChild("TextBox")

				if textBox and textBox:IsA("TextBox") then
					textBox.Text = code
					task.wait(0.1)
					textBox:CaptureFocus()
					task.wait(0.05)
					textBox:ReleaseFocus(true)
					print(string.format("[%d/%d] Redeemed: %s", i, #codesList, code))
				else
					warn("[-] Codes UI not found! Open the Codes window in the Lobby first.")
				end

				task.wait(1.5)
			end
		end)
	end
})


Window:SelectTab(1)
