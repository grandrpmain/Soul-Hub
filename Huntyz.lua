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
-- 3. CODE REDEEMER BUTTON (EXACT PATH FIXED)
---------------------------------------------------------
local VirtualInputManager = game:GetService("VirtualInputManager")

local codesList = {
	"Anniversary!",
	"ScytheEvolution!",
	"Dubstep!",
	"HappyBirthday!",
	"PartyBreaker!",
	"SorryForBadCode",
	"VeryHotHotfixes"
}

-- Function to force-click the Accept button using all executor methods
local function clickAcceptButton(button)
	if not button then return end

	-- Method 1: firesignal (Delta, Wave, Solara, etc.)
	if typeof(firesignal) == "function" then
		pcall(function() firesignal(button.MouseButton1Click) end)
		pcall(function() firesignal(button.MouseButton1Down) end)
		pcall(function() firesignal(button.Activated) end)
	end

	-- Method 2: getconnections
	if typeof(getconnections) == "function" then
		pcall(function()
			for _, conn in ipairs(getconnections(button.MouseButton1Click)) do conn:Fire() end
			for _, conn in ipairs(getconnections(button.Activated)) do conn:Fire() end
		end)
	end

	-- Method 3: Virtual Mouse Click directly on button coordinates
	pcall(function()
		local pos = button.AbsolutePosition
		local size = button.AbsoluteSize
		if pos and size then
			local centerX = pos.X + (size.X / 2)
			local centerY = pos.Y + (size.Y / 2) + 58 -- TopBar offset

			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
			task.wait(0.03)
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
		end
	end)
end

Tabs.Lobby:AddButton({
	Title = "Redeem All Codes",
	Description = "Automatically redeems all active promo codes",
	Callback = function()
		task.spawn(function()
			print("[+] Starting code redemption process...")

			local playerGui = player:WaitForChild("PlayerGui")

			for i, code in ipairs(codesList) do
				local guiFolder = playerGui:FindFirstChild("GUI")
				local codesFrame = guiFolder and guiFolder:FindFirstChild("Codes")
				local content = codesFrame and codesFrame:FindFirstChild("Content")
				
				-- TextBox: GUI > Codes > Content > SearchBar > TextBox
				local searchBar = content and content:FindFirstChild("SearchBar")
				local textBox = searchBar and searchBar:FindFirstChild("TextBox")

				-- Confirm Button: GUI > Codes > Content > Buttone > Accept
				local buttoneFrame = content and content:FindFirstChild("Buttone")
				local acceptButton = buttoneFrame and buttoneFrame:FindFirstChild("Accept")

				if textBox and textBox:IsA("TextBox") then
					-- Step 1: Input the Code
					textBox.Text = code
					task.wait(0.2)

					-- Step 2: Click the 'Accept' button
					if acceptButton then
						clickAcceptButton(acceptButton)
						print(string.format("[%d/%d] Redeemed & Clicked Accept: %s", i, #codesList, code))
					else
						-- Fallback if button isn't found
						textBox:CaptureFocus()
						task.wait(0.05)
						textBox:ReleaseFocus(true)
						warn("[-] 'Accept' button not found inside Content.Buttone")
					end
				else
					warn("[-] Codes UI not found! Please open the Codes menu in the Lobby first.")
				end

				task.wait(1.5) -- Delay between code submissions
			end

			print("[+] Finished redeeming all codes!")
		end)
	end
})

---------------------------------------------------------
-- FLY / ZOMBIE SAFE HOVER TOGGLE
---------------------------------------------------------
local isFlying = false
local flyThread = nil

local FlyToggle = Tabs.Main:AddToggle("Fly", { Title = "Fly (Safe Hover)", Default = false })

FlyToggle:OnChanged(function(Value)
	isFlying = Value

	-- Cancel existing hover loop immediately
	if flyThread then
		task.cancel(flyThread)
		flyThread = nil
	end

	if not isFlying then 
		print("[-] Fly Hover Disabled")
		return 
	end

	print("[+] Fly Hover Started")

	flyThread = task.spawn(function()
		while isFlying do
			local character = player.Character or player.CharacterAdded:Wait()
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if hrp then
				local playerPos = hrp.Position
				local closestPart = nil
				local shortestDistance = math.huge

				-- Find the nearest Zombie NPC
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("BasePart") and obj:GetAttribute("EntityTeam") == "Zombie" then
						local distance = (playerPos - obj.Position).Magnitude
						if distance < shortestDistance then
							shortestDistance = distance
							closestPart = obj
						end
					end
				end

				-- Teleport & lock position safely above the Zombie
				if closestPart then
					-- Cancel gravity velocity so you don't fall between ticks
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero

					-- Positions you 8 studs DIRECTLY ABOVE the zombie
					local safeHoverPos = closestPart.CFrame * CFrame.new(0, 8, 0)
					character:PivotTo(safeHoverPos)
				end
			end

			task.wait(0.1) -- Fast refresh so you follow moving zombies smoothly
		end
	end)
end)
Window:SelectTab(1)
