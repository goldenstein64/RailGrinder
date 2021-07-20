local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local root = Workspace:WaitForChild("RailProject")
local RailModel = root:WaitForChild("RailModel")

local protoAlignPosition = script.Parent:WaitForChild("AlignPosition")

local attach1
local dummyPart = Instance.new("Part") do
	dummyPart.Transparency = 1
	dummyPart.Anchored = true
	dummyPart.Position = Vector3.new(0, 0, 0)

	attach1 = Instance.new("Attachment") do
		attach1.Name = "Attachment1"
		attach1.Parent = dummyPart
	end

	dummyPart.Parent = Workspace
end

local usedRailParts = RailModel:GetChildren()
table.sort(usedRailParts, function(a, b)
	return a.Name < b.Name
end)

local RailGrinder = require(ReplStorage.RailGrinder)

-- selene: allow(unused_variable)
local function editPosition(self, newPosition)
	return newPosition + Vector3.new(0, 3, 0)
end

local function loadCharacter(chr)
	local humanoid: Humanoid = chr:WaitForChild("Humanoid")
	local rootPart = chr:WaitForChild("HumanoidRootPart")
	local alignPosition = protoAlignPosition:Clone()

	local railGrinder = RailGrinder.new(alignPosition)
	railGrinder.EditPosition = editPosition
	
	local function stopGrinding(_, state)
		if state == Enum.UserInputState.Begin then
			railGrinder:Disable()
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end

	local attach0 = Instance.new("Attachment") do
		attach0.Parent = rootPart
	end
	alignPosition.Attachment0 = attach0
	alignPosition.Attachment1 = attach1
	alignPosition.Parent = chr

	local debounce = false

	local conn1
	local conn2 = humanoid.Touched:Connect(function(hit)
		if not railGrinder.Enabled and hit.Parent == RailModel and not debounce then

			railGrinder:Grind(usedRailParts, hit)
			railGrinder.Speed *= 3
			ContextActionService:BindAction("StopGrinding", stopGrinding, false, Enum.KeyCode.Space)

			if conn1 then
				conn1:Disconnect()
			end
			conn1 = railGrinder.Completed:Connect(function()
				conn1:Disconnect()
				ContextActionService:UnbindAction("StopGrinding")
				
				debounce = true
				wait(1)
				debounce = false
			end)
		end
	end)

	humanoid.Died:Connect(function()
		conn1:Disconnect()
		conn2:Disconnect()
		railGrinder:Disable()
		ContextActionService:UnbindAction("StopGrinding")
	end)
end

player.CharacterAdded:Connect(loadCharacter)
if player.Character then
	loadCharacter(player.Character)
end
