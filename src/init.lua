local RunService = game:GetService("RunService")

local function getLength(part)
	return (part.Next.Position - part.Prev.Position).Magnitude
end

local function getDelta(part)
	return part.Next.WorldPosition - part.Prev.WorldPosition
end

local function getPosition(self)
	return self.CurrentPart.Prev.WorldPosition:Lerp(self.CurrentPart.Next.WorldPosition, self.Alpha)
end

local function getAlpha(self, vessel)
	local delta = getDelta(self.CurrentPart)
	local distanceFromPrev = vessel.Position - self.CurrentPart.Prev.WorldPosition
	return delta.Unit:Dot(distanceFromPrev) / delta.Magnitude
end

local function getSpeedRelativeTo(self, vessel)
	local delta = getDelta(self.CurrentPart)
	return delta.Unit:Dot(vessel.Velocity)
end

local events = setmetatable({}, { __mode = "k" })

local RailGrinder = {}
RailGrinder.__index = RailGrinder

function RailGrinder.new()
	local self = {
		Enabled = false,

		CurrentPart = nil,

		Speed = 0,
		Position = Vector3.new(),
		Velocity = Vector3.new(),

		Alpha = 0,
		CurrentPartLength = 0,
	}

	local completedEvent = Instance.new("BindableEvent")
	completedEvent.Name = "Completed"

	local positionChangedEvent = Instance.new("BindableEvent")
	positionChangedEvent.Name = "PositionChanged"

	local partChangedEvent = Instance.new("BindableEvent")
	partChangedEvent.Name = "PartChanged"

	events[self] = {
		Completed = completedEvent,
		PositionChanged = positionChangedEvent,
		PartChanged = partChangedEvent,
	}

	self.Completed = completedEvent.Event
	self.PositionChanged = positionChangedEvent.Event
	self.PartChanged = partChangedEvent.Event

	setmetatable(self, RailGrinder)

	return self
end

function RailGrinder:Enable(vessel)
	self.Enabled = true
	local speed = getSpeedRelativeTo(self, vessel)
	self:SetSpeed(speed)

	self.Alpha = getAlpha(self, vessel)
	self.CurrentPartLength = getLength(self.CurrentPart)
	self.Position = getPosition(self)

	self.Connection = RunService.Heartbeat:Connect(function(dt)
		self:Update(dt)
	end)
end

function RailGrinder:Disable()
	if not self.Enabled then
		return
	end

	self.Enabled = false
	self.CurrentPart = nil
	self.Speed = 0

	if self.Connection then
		self.Connection:Disconnect()
	end

	events[self].Completed:Fire()
end

function RailGrinder:SetSpeed(newSpeed)
	local delta = getDelta(self.CurrentPart)
	self.Speed = newSpeed
	self.Velocity = delta.Unit * newSpeed
end

function RailGrinder:Update(dt)
	local newAlpha = self.Alpha + dt * self.Speed / self.CurrentPartLength

	local nodeDistance = math.floor(self.Alpha)
	local incr = math.sign(self.Alpha)
	for _ = 1, math.abs(nodeDistance) do
		local newPart = self.GetNextPart(incr)
		if not newPart then
			self:Disable()
			return
		end

		local newPartLength = getLength(newPart)
		newAlpha -= incr
		newAlpha *= self.CurrentPartLength / newPartLength
		self.CurrentPartLength = newPartLength
		self.CurrentPart = newPart
	end

	if nodeDistance ~= 0 then
		local delta = getDelta(self.CurrentPart)
		self.Velocity = delta.Unit * self.Speed
	end

	self.Alpha = newAlpha
	self.Position = getPosition(self)
	events[self].PositionChanged:Fire(self.Position)
end

-- selene: allow(unused_variable)
function RailGrinder.GetNextPart(direction)
	return nil
end

return RailGrinder
