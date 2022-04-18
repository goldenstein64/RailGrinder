local RunService = game:GetService("RunService")

local function getLength(part: BasePart): number
	return (part.Next.Position - part.Prev.Position).Magnitude
end

local function getDelta(part: BasePart): Vector3
	return part.Next.WorldPosition - part.Prev.WorldPosition
end

local function getPosition(currentPart: BasePart, alpha: number): Vector3
	return currentPart.Prev.WorldPosition:Lerp(currentPart.Next.WorldPosition, alpha)
end

local function getInitialAlpha(currentPart: BasePart, vessel: BasePart): number
	local delta = getDelta(currentPart)
	local distanceFromPrev = vessel.Position - currentPart.Prev.WorldPosition
	return delta.Unit:Dot(distanceFromPrev) / delta.Magnitude
end

local function getSpeedRelativeTo(currentPart: BasePart, vessel: BasePart): number
	local delta = getDelta(currentPart)
	return delta.Unit:Dot(vessel.AssemblyLinearVelocity)
end

local events = setmetatable({}, { __mode = "k" })

--[=[
	@class RailGrinder

	A helper class for calculating speed and position when grinding on a
	set of linear points in 3D space.
]=]
local RailGrinder = {}
RailGrinder.__index = RailGrinder

--[=[
	@type RailPart BasePart & { Prev: Attachment, Next: Attachment }
	@within RailGrinder

	A part with two child attachments `Prev` and `Next`. Typically, the `Next`
	attachment of one part has the same position as the `Prev` attachment of another part.
]=]

--- Creates a new RailGrinder instance, which lets one "vessel" grind one rail.
function RailGrinder.new()
	local self = {}

	--[=[
		@prop Enabled boolean
		@within RailGrinder
		@readonly

		Describes whether this RailGrinder is currently enabled.

		Please use [RailGrinder:Enable] and [RailGrinder:Disable] to update this
		value.
	]=]
	self.Enabled = false

	--[=[
		@prop CurrentPart RailPart
		@within RailGrinder
		@readonly

		The part currently being grinded on.
	]=]
	self.CurrentPart = nil

	--[=[
		@prop Speed number
		@within RailGrinder
		@readonly

		How fast the position changes every update. If you want to change this, 
		please use [RailGrinder:SetSpeed].
	]=]
	self.Speed = 0

	--[=[
		@prop Position Vector3
		@within RailGrinder
		@readonly

		The current position as calculated by [RailGrinder.Update].
	]=]
	self.Position = Vector3.new()

	--[=[
		@prop Velocity Vector3
		@within RailGrinder
		@readonly

		How fast the position changes every heartbeat with a direction. This
		exists for the end-user, and only updates when [RailGrinder.CurrentPart] or
		[RailGrinder.Speed] changes.
	]=]
	self.Velocity = Vector3.new()

	--[=[
		@prop Alpha number
		@within RailGrinder
		@private
		
		Describes where `RailGrinder.Position` is between [RailGrinder.CurrentPart].Prev
		and [RailGrinder.CurrentPart].Next.
	]=]
	self.Alpha = 0

	--[=[
		@prop CurrentPartLength number
		@within RailGrinder
		@private

		The distance between [RailGrinder.CurrentPart].Prev and 
		[RailGrinder.CurrentPart].Next.
	]=]
	self.CurrentPartLength = 0

	--[=[
		@prop Connection RBXScriptConnection?
		@within RailGrinder
		@private

		The [RunService.Heartbeat] connection used to update the [RailGrinder]
		instance. If you want to disconnect this, use [RailGrinder:Disable].
	]=]
	self.Connection = nil

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

	--[=[
		@prop Completed RBXScriptSignal
		@within RailGrinder

		Fires when this `RailGrinder` is disabled.
	]=]
	self.Completed = completedEvent.Event

	--[=[
		@prop PositionChanged RBXScriptSignal<Vector3>
		@within RailGrinder

		Fires when this `RailGrinder`'s `Position` is updated.
	]=]
	self.PositionChanged = positionChangedEvent.Event

	--[=[
		@prop PartChanged RBXScriptSignal<RailPart>
		@within RailGrinder

		Fires when this `RailGrinder`'s `CurrentPart` is updated
	]=]
	self.PartChanged = partChangedEvent.Event

	--[=[
		@prop UpdateCallback (number) -> ()
		@within RailGrinder
		The callback used when [RunService.Heartbeat] fires. This is bound
		automatically by [RailGrinder:Enable].
	]=]
	self.UpdateCallback = function(deltaTime)
		self:Update(deltaTime)
	end

	setmetatable(self, RailGrinder)

	return self
end

--[=[
	Sets all properties required to start grinding the rail and starts updating
	them using a connection to [RunService.Heartbeat].

	The properties updated are:
	* [RailGrinder.Enabled]
	* [RailGrinder.CurrentPart]
	* [RailGrinder.CurrentPartLength]
	* [RailGrinder.Speed]
	* [RailGrinder.Velocity]
	* [RailGrinder.Alpha]
	* [RailGrinder.Position]
	* [RailGrinder.Connection]

	The `vessel` argument is only used to calculate the speed and alpha relative to `currentPart`, so it is optional.

	@param currentPart BasePart -- The instance the `vessel` is grinding on.
	@param vessel BasePart? -- The instance grinding the rail.
]=]
function RailGrinder:Enable(currentPart: BasePart, vessel: BasePart?): ()
	self.Enabled = true
	self.CurrentPart = currentPart
	self.CurrentPartLength = getLength(currentPart)

	if vessel then
		local speed = getSpeedRelativeTo(currentPart, vessel)
		self:SetSpeed(speed)

		self.Alpha = getInitialAlpha(currentPart, vessel)
	end

	self.Position = getPosition(currentPart, self.Alpha)

	self.Connection = RunService.Heartbeat:Connect(self.UpdateCallback)
end

--- Stops updating variables and firing events.
function RailGrinder:Disable(): ()
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

--[=[
	A function that runs every `RunService.Heartbeat`, this fires the
	`PositionChanged` event when finished and calls `GetNextPart` as needed.

	@param deltaTime number -- The amount of time that passed since last update.
]=]
function RailGrinder:Update(deltaTime: number): ()
	local newAlpha = self.Alpha + deltaTime * self.Speed / self.CurrentPartLength

	local nodeDistance = math.floor(newAlpha)
	local incr = math.sign(newAlpha)
	for _ = 1, math.abs(nodeDistance) do
		local newPart = self.GetNextPart(incr)
		if not newPart then
			self:Disable()
			return
		end

		local newPartLength = getLength(newPart)
		if incr == 1 then
			newAlpha -= incr
			newAlpha *= self.CurrentPartLength / newPartLength
		elseif incr == -1 then
			newAlpha *= self.CurrentPartLength / newPartLength
			newAlpha -= incr
		end

		self.CurrentPartLength = newPartLength
		self.CurrentPart = newPart
	end

	if nodeDistance ~= 0 then
		local delta = getDelta(self.CurrentPart)
		self.Velocity = delta.Unit * self.Speed
		events[self].PartChanged:Fire(self.CurrentPart)
	end

	self.Alpha = newAlpha
	self.Position = getPosition(self.CurrentPart, self.Alpha)
	events[self].PositionChanged:Fire(self.Position)
end

--[=[
	Sets how fast the position should change

	@param newSpeed number -- The new speed the RailGrinder should update at
]=]
function RailGrinder:SetSpeed(newSpeed: number): ()
	if self.Speed == newSpeed then
		return
	end

	local delta = getDelta(self.CurrentPart)
	self.Speed = newSpeed
	self.Velocity = delta.Unit * newSpeed
end

-- selene: allow(unused_variable)
--[=[
	The callback used to get the next part once the vessel has grinded to
	the end of the current part.

	@param direction number -- Which direction off the current part the character grinded off to
	@return Instance? -- The next part to grind on. Returning `nil` disables the RailGrinder instance.
]=]
function RailGrinder.GetNextPart(direction: number): Instance?
	return nil
end

return RailGrinder
