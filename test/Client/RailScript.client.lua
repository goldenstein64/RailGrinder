local Workspace = game:GetService("Workspace")
local ReplStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TagService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local RailGrinder = require(ReplStorage.RailGrinder)

local chr = script.Parent
local humanoid: Humanoid = chr:WaitForChild("Humanoid")
local rootPart = chr:WaitForChild("HumanoidRootPart")

local bodyPosition = Instance.new("BodyPosition")
do
	bodyPosition.MaxForce = Vector3.new(1, 1, 1) * 20_000
	bodyPosition.P = 100_000
end

local railGrinder = RailGrinder.new()

local function compareByGrindOrder(a, b)
	return a:GetAttribute("GrindOrder") < b:GetAttribute("GrindOrder")
end

local function stopGrinding(_, state)
	if state == Enum.UserInputState.Begin then
		railGrinder:Disable()
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

local lastDisabled = -math.huge

railGrinder.PositionChanged:Connect(function(newPosition)
	bodyPosition.Position = newPosition + Vector3.new(0, 3, 0)
end)

local completedConn
humanoid.Touched:Connect(function(hit)
	local railModel = hit.Parent
	if railGrinder.Enabled or not TagService:HasTag(railModel, "RailModel") or os.clock() - lastDisabled < 0.3 then
		return
	end

	local railParts = railModel:GetChildren()
	table.sort(railParts, compareByGrindOrder)

	local i = table.find(railParts, hit)
	function railGrinder.GetNextPart(direction)
		i += direction
		return railParts[i]
	end

	humanoid.Sit = true
	bodyPosition.Parent = rootPart
	railGrinder.CurrentPart = hit
	railGrinder:Enable(rootPart)

	local speedMultiplier = railModel:GetAttribute("SpeedMultiplier")
	if speedMultiplier then
		railGrinder:SetSpeed(railGrinder.Speed * speedMultiplier)
	end

	local gravityConn
	if railModel:GetAttribute("UsesGravity") then
		gravityConn = RunService.Heartbeat:Connect(function(dt)
			local currentPart = railGrinder.CurrentPart
			local delta = currentPart.Next.WorldPosition - currentPart.Prev.WorldPosition
			railGrinder:SetSpeed(railGrinder.Speed - dt * Workspace.Gravity * delta.Unit.Y)
		end)
	end

	ContextActionService:BindAction("StopGrinding", stopGrinding, false, Enum.PlayerActions.CharacterJump)

	if completedConn then
		completedConn:Disconnect()
	end
	completedConn = railGrinder.Completed:Connect(function()
		completedConn:Disconnect()
		if gravityConn then
			gravityConn:Disconnect()
		end
		humanoid.Sit = false
		bodyPosition.Parent = nil
		ContextActionService:UnbindAction("StopGrinding")

		lastDisabled = os.clock()
	end)
end)

humanoid.Died:Connect(function()
	railGrinder:Disable()
	ContextActionService:UnbindAction("StopGrinding")
end)
