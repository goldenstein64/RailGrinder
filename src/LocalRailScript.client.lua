local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local root = Workspace.RailProject
local RailModel = root:WaitForChild("RailModel")
local protoAlignPosition = root:WaitForChild("AlignPosition")

local dummyPart = Instance.new("Part")
do
	dummyPart.Transparency = 1
	dummyPart.Anchored = true
	dummyPart.Position = Vector3.new(0, 0, 0)
end

local usedRailParts = RailModel:GetChildren()
table.sort(usedRailParts, function(a, b)
	return a.Name < b.Name
end)

local function GetDistance(prevNode, nextNode)
	return (nextNode.WorldPosition - prevNode.WorldPosition).Magnitude
end

local function GetNewPosition(prevNode, nextNode, a)
	return prevNode.WorldPosition:Lerp(nextNode.WorldPosition, a)
end

local Grinding = false
local function GrindRail(AlignPosition, RailParts, CurrentPart)

	AlignPosition.Attachment1.Position = AlignPosition.Attachment0.WorldPosition

	local i = table.find(RailParts, CurrentPart)

	local CurrentPosition = AlignPosition.Attachment0.WorldPosition

	local dist1 = CurrentPosition - CurrentPart.Prev.WorldPosition
	local direction = CurrentPart.Next.WorldPosition - CurrentPart.Prev.WorldPosition

	--alpha between Node0 and Node1
	local a = direction.Unit:Dot(dist1) / direction.Magnitude

	local speed = direction.Unit:Dot(AlignPosition.Attachment0.Parent.Velocity)

	--All variables should be found by now!
	AlignPosition.Enabled = true

	local CurrentRatio = GetDistance(CurrentPart.Prev, CurrentPart.Next)

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		a += dt * speed / CurrentRatio

		while a > 1 do
			i += 1

			CurrentPart = RailParts[i]
			if CurrentPart then
				local NewRatio = GetDistance(CurrentPart.Prev, CurrentPart.Next)
				a = (a - 1) * NewRatio / CurrentRatio
				CurrentRatio = NewRatio

			else
				connection:Disconnect()
				break

			end
		end

		while a < 0 do
			i -= 1

			CurrentPart = RailParts[i]
			if CurrentPart then
				local NewRatio = GetDistance(CurrentPart.Prev, CurrentPart.Next)
				a = (a + 1) * NewRatio / CurrentRatio
				CurrentRatio = NewRatio

			else
				connection:Disconnect()
				break

			end
		end

		if CurrentPart and Grinding then
			AlignPosition.Attachment1.Position = GetNewPosition(CurrentPart.Prev, CurrentPart.Next, a)
				+ Vector3.new(0, 3, 0)
		else
			AlignPosition.Enabled = false
			wait(2)
			Grinding = false
		end

	end)
end

local function loadCharacter(chr)
	local humanoid = chr:WaitForChild("Humanoid")
	local rootPart = chr:WaitForChild("HumanoidRootPart")
	local alignPosition = protoAlignPosition:Clone()
	local usedDummyPart = dummyPart:Clone()

	alignPosition.Parent = chr
	local attach0 = Instance.new("Attachment")
	do
		attach0.Parent = usedDummyPart
	end
	local attach1 = Instance.new("Attachment")
	do
		attach1.Parent = rootPart
	end

	local conn2 = humanoid.Touched:Connect(function(hit)
		if not Grinding and hit.Parent == RailModel then

			Grinding = true
			humanoid.PlatformStand = true
			GrindRail(alignPosition, usedRailParts, hit)

			local conn1
			conn1 = alignPosition:GetPropertyChangedSignal("Enabled"):Connect(function()
				if not alignPosition.Enabled then
					conn1:Disconnect()
					humanoid.PlatformStand = false
				end
			end)
		end
	end)

	humanoid.Died:Connect(function()
		conn2:Disconnect()
		Grinding = false
	end)
end

player.CharacterAdded:Connect(loadCharacter)
if player.Character then
	loadCharacter(player.Character)
end
