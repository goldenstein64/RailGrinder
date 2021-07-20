local RunService = game:GetService("RunService")

local function getLength(part)
	return (part.Next.WorldPosition - part.Prev.WorldPosition).Magnitude
end

local function getNewPosition(part, a)
	return part.Prev.WorldPosition:Lerp(part.Next.WorldPosition, a)
end

local events = setmetatable({}, {__mode = "k"})

local RailGrinder = {}
RailGrinder.__index = RailGrinder

function RailGrinder.new(alignPosition)
	local self = {
		Enabled = false,
		AlignPosition = alignPosition,

		Speed = 0,
	}

	local completedEvent = Instance.new("BindableEvent")
	completedEvent.Name = "Completed"

	events[self] = {
		Completed = completedEvent
	}

	self.Completed = completedEvent.Event

	setmetatable(self, RailGrinder)

	return self
end

function RailGrinder:Disable()
	if not self.Enabled then return end

	self.Enabled = false
	self.AlignPosition.Enabled = false

	if self.Connection then
		self.Connection:Disconnect()
	end

	events[self].Completed:Fire()
end

function RailGrinder:Grind(RailParts, CurrentPart)
	self.Enabled = true

	local CurrentPosition = self.AlignPosition.Attachment0.WorldPosition

  self.AlignPosition.Attachment1.Position = CurrentPosition

	local i = table.find(RailParts, CurrentPart)

	local distance1 = CurrentPosition - CurrentPart.Prev.WorldPosition
	local direction = CurrentPart.Next.WorldPosition - CurrentPart.Prev.WorldPosition

	--alpha between Node0 and Node1
	local a = direction.Unit:Dot(distance1) / direction.Magnitude

	self.Speed = direction.Unit:Dot(self.AlignPosition.Attachment0.Parent.Velocity)

	--All variables should be found by now!
	self.AlignPosition.Enabled = true

	local CurrentRatio = getLength(CurrentPart)

	self.Connection = RunService.RenderStepped:Connect(function(dt)
		a += dt * self.Speed / CurrentRatio

		local moveNodes = math.floor(a)
		local incr = math.sign(a)
		for _ = 1, math.abs(moveNodes) do
			i += incr

			CurrentPart = RailParts[i]
			if not CurrentPart then
				self:Disable()
				return
			end

			local NewRatio = getLength(CurrentPart)
			a -= incr
			a *= NewRatio / CurrentRatio
			CurrentRatio = NewRatio
		end

		local newPosition = getNewPosition(CurrentPart, a)
		newPosition = self:EditPosition(newPosition)
		self.AlignPosition.Attachment1.Position = newPosition
	end)
end

function RailGrinder:EditPosition(position)
	return position
end

return RailGrinder