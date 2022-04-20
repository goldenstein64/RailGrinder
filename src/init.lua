local RunService = game:GetService("RunService")

--[=[
	@within RailGrinder
	@private
	
	Returns the length of a RailPart
]=]
local function getLength(part: BasePart): number
	return (part.Next.Position - part.Prev.Position).Magnitude
end

--[=[
	@within RailGrinder
	@private

	Returns the direction of the [RailPart] in world space, with a magnitude equal to the length of the part
]=]
local function getDelta(part: BasePart): Vector3
	return part.Next.WorldPosition - part.Prev.WorldPosition
end

--[=[
	@within RailGrinder
	@private

	Returns a position on the [RailPart] with the given alpha.

	* 0 = CurrentPart.Prev
	* 1 = CurrentPart.Next
]=]
local function getPosition(currentPart: BasePart, alpha: number): Vector3
	return currentPart.Prev.WorldPosition:Lerp(currentPart.Next.WorldPosition, alpha)
end

--[=[
	@within RailGrinder
	@private

	Returns a number between 0-1 indicating the point on the `currentPart` 
	closest to the given `position` when using [RailGrinder.getPosition].
]=]
local function getInitialAlpha(currentPart: BasePart, position: Vector3): number
	local delta = getDelta(currentPart)
	local distanceFromPrev = position - currentPart.Prev.WorldPosition
	return delta.Unit:Dot(distanceFromPrev) / delta.Magnitude
end

--[=[
	@within RailGrinder
	@private

	Returns a number describing what speed something with the given 
	`worldVelocity` is going on `currentPart`.
]=]
local function getInitialSpeed(currentPart: BasePart, worldVelocity: Vector3): number
	local delta = getDelta(currentPart)
	return delta.Unit:Dot(worldVelocity)
end

local private = setmetatable({}, { __mode = "k" })

--[=[
	@class RailGrinder

	A helper class for calculating position and velocity of an object traveling 
	across a collection of attachment pairs.
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
	private[self] = {}

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

		Describes how fast the position changes every update. Please use 
		[RailGrinder:SetSpeed] to change this value.
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

		Describes how fast the position changes every update, represented as a 
		Vector3 with a magnitude and direction. This exists for the end-user, and
		only updates when [RailGrinder.CurrentPart] or [RailGrinder.Speed] changes.
	]=]
	self.Velocity = Vector3.new()

	--[=[
		@prop Alpha number
		@within RailGrinder
		@private
		
		Describes where [RailGrinder.Position] is between [RailGrinder.CurrentPart].Prev
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

	--[=[
		@prop CompletedBindable BindableEvent
		@within RailGrinder
		@private

		Holds the [RailGrinder.Completed] event.
	]=]
	private[self].CompletedBindable = completedEvent

	--[=[
		@prop Completed RBXScriptSignal<>
		@within RailGrinder
		@tag Events

		Fires when this `RailGrinder` has finished or is disabled.
	]=]
	self.Completed = completedEvent.Event

	local positionChangedEvent = Instance.new("BindableEvent")
	positionChangedEvent.Name = "PositionChanged"

	--[=[
		@prop PositionChangedBindable BindableEvent
		@within RailGrinder
		@private

		Holds the [RailGrinder.PositionChanged] event.
	]=]
	private[self].PositionChangedBindable = positionChangedEvent

	--[=[
		@prop PositionChanged RBXScriptSignal<Vector3>
		@within RailGrinder
		@tag Events

		Fires when [RailGrinder.Position] is updated.
	]=]
	self.PositionChanged = positionChangedEvent.Event

	local partChangedEvent = Instance.new("BindableEvent")
	partChangedEvent.Name = "PartChanged"

	--[=[
		@prop PartChangedBindable BindableEvent
		@within RailGrinder
		@private

		Holds the [RailGrinder.PartChanged] event.
	]=]
	private[self].PartChangedBindable = partChangedEvent

	--[=[
		@prop PartChanged RBXScriptSignal<RailPart>
		@within RailGrinder
		@tag Events

		Fires when [RailGrinder.CurrentPart] is updated.
	]=]
	self.PartChanged = partChangedEvent.Event

	--[=[
		@prop UpdateCallback (number) -> ()
		@within RailGrinder
		@readonly

		This function is called when [RunService.Heartbeat] fires. This is bound
		automatically by [RailGrinder:Enable].
	]=]
	private[self].UpdateCallback = function(deltaTime)
		self:Update(deltaTime)
	end

	setmetatable(self, RailGrinder)

	return self
end

--[=[
	@param currentPart BasePart -- The instance the `vessel` is grinding on.
	@param vessel BasePart? -- The instance grinding the rail.

	Sets all properties required to start grinding the rail and starts updating
	them and firing events using a connection to [RunService.Heartbeat].

	The `vessel` argument is only used to calculate the speed and position relative 
	to `currentPart`, so it is optional.
]=]
function RailGrinder:Enable(currentPart: BasePart, vessel: BasePart?): ()
	self.Enabled = true
	self.CurrentPart = currentPart
	self.CurrentPartLength = getLength(currentPart)

	if vessel then
		local speed = getInitialSpeed(currentPart, vessel.AssemblyLinearVelocity)
		self:SetSpeed(speed)

		self.Alpha = getInitialAlpha(currentPart, vessel.Position)
	end

	self.Position = getPosition(currentPart, self.Alpha)

	self.Connection = RunService.Heartbeat:Connect(private[self].UpdateCallback)
end

--- Stops updating variables and firing events.
function RailGrinder:Disable(): ()
	if not self.Enabled then
		return
	end

	self.Enabled = false
	self:SetSpeed(0)

	self.Alpha = 0
	self.CurrentPart = nil
	self.CurrentPartLength = 0

	self.Position = Vector3.new()

	if self.Connection then
		self.Connection:Disconnect()
	end

	private[self].CompletedBindable:Fire()
end

--[=[
	@param deltaTime number -- The amount of time that passed since last update.

	A function that runs every [RunService.Heartbeat], this fires the
	`PositionChanged` event once updated, fires [RailGrinder.Completed] once and calls [RailGrinder.GetNextPart] as needed.
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
		private[self].PartChangedBindable:Fire(self.CurrentPart)
	end

	self.Alpha = newAlpha
	self.Position = getPosition(self.CurrentPart, self.Alpha)
	private[self].PositionChangedBindable:Fire(self.Position)
end

--[=[
	@param newSpeed number -- The new speed the RailGrinder should update at

	Sets how fast the position should change
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
	@param direction -1 | 1 -- Which direction the next part should come from.
	@return RailPart? -- The next part to grind on.
	
	This callback is used to get the next part when the new position is beyond 
	the extents of the current part.

	* Back end means `direction = -1`. 
	* Front end means `direction = 1`.

	Returning `nil` disables the instance.
]=]
function RailGrinder.GetNextPart(direction: number): Instance?
	return nil
end

return RailGrinder
