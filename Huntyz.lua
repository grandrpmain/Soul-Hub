local VirtualInputManager = game:GetService("VirtualInputManager")
local ContextActionService = game:GetService("ContextActionService")

local isSkillEnabled = false
local skillThread = nil

-- Skill keys to press in order
local SKILL_KEYS = {
	Enum.KeyCode.Z,
	Enum.KeyCode.X,
	Enum.KeyCode.C,
	Enum.KeyCode.V,
	Enum.KeyCode.G
}

-- Common action names used in combat framework scripts for M1
local M1_ACTIONS = { "Attack", "M1", "LightAttack", "Punch", "Swing" }

-- Server-side M1 trigger (no screen click)
local function triggerM1()
	for _, actionName in ipairs(M1_ACTIONS) do
		ContextActionService:CallFunction(actionName, Enum.UserInputState.Begin, nil)
		task.wait(0.02)
		ContextActionService:CallFunction(actionName, Enum.UserInputState.End, nil)
	end
end

-- Key simulator for skills
local function pressKey(keyCode)
	VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local SkillToggle = Tabs.Main:AddToggle("Skill", { Title = "Multi-Skill & M1", Default = false })

SkillToggle:OnChanged(function(Value)
	isSkillEnabled = Value

	-- Cancel existing thread immediately
	if skillThread then
		task.cancel(skillThread)
		skillThread = nil
	end

	if not isSkillEnabled then 
		print("[-] Skill & M1 Spammer Disabled")
		return 
	end

	print("[+] Skill & M1 Spammer Started")

	skillThread = task.spawn(function()
		task.wait(0.2) -- Delay to let UI toggle finish safely

		while isSkillEnabled do
			-- 1. Trigger Server-side M1
			triggerM1()
			task.wait(0.05)

			-- 2. Cycle Z, X, C, V, G
			for _, key in ipairs(SKILL_KEYS) do
				if not isSkillEnabled then break end
				pressKey(key)
				task.wait(0.05)
			end

			task.wait(0.2)
		end
	end)
end)
