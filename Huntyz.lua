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

-- Timeout prevents the script from hanging indefinitely if ByteNet is missing (e.g. in Lobby)
local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable", 2)

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
		local school = workspace:FindFirstChild("School")
		local doorsFolder = school and school:FindFirstChild("Doors")

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
		task.wait(0.2)

		while isSkillEnabled do
			-- Cycle through Z, X, C, V, G
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
-- 3. CODE REDEEMER BUTTON (FIXED)
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
			print("[+] Starting code redemption process...")

			local playerGui = player:WaitForChild("PlayerGui")

			for i, code in ipairs(codesList) do
				-- Navigate to UI elements
				local guiFolder = playerGui:FindFirstChild("GUI")
				local codesFrame = guiFolder and guiFolder:FindFirstChild("Codes")
				local content = codesFrame and codesFrame:FindFirstChild("Content")
				local searchBar = content and content:FindFirstChild("SearchBar")
				local textBox = searchBar and searchBar:FindFirstChild("TextBox")

				if textBox and textBox:IsA("TextBox") then
					-- Step 1: Focus and set text
					textBox:CaptureFocus()
					task.wait(0.05)
					textBox.Text = code
					task.wait(0.05)

					-- Step 2: Trigger FocusLost signal if executor supports firesignal
					if typeof(firesignal) == "function" then
						pcall(function()
							firesignal(textBox.FocusLost, true)
						end)
					end

					-- Step 3: Simulate pressing the Physical 'Enter' Key
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
					task.wait(0.03)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

					-- Step 4: Search for any Redeem button in SearchBar/Content and click it
					local redeemBtn = searchBar:FindFirstChildOfClass("TextButton") 
						or searchBar:FindFirstChildOfClass("ImageButton")
						or (content and content:FindFirstChildOfClass("TextButton"))

					if redeemBtn then
						if typeof(firesignal) == "function" then
							pcall(function()
								firesignal(redeemBtn.MouseButton1Click)
								firesignal(redeemBtn.Activated)
							end)
						end
					end

					print(string.format("[%d/%d] Attempted: %s", i, #codesList, code))
				else
					warn("[-] Codes UI not found! Open the Codes UI window in the Lobby first.")
				end

				task.wait(1.5) -- Wait between codes
			end

			print("[+] Finished code redemption cycle!")
		end)
	end
})


Window:SelectTab(1)
