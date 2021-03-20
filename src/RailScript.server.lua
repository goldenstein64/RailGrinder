local root = script.Parent
local RailModel = root.RailModel

local RailParts = RailModel:GetChildren()
table.sort(RailParts, function(a, b)
	return a.Name < b.Name
end)

local lastPart
for _, part in ipairs(RailParts) do
	if lastPart then
		part.Position += lastPart.Node1.WorldPosition - part.Node0.WorldPosition
	end

	lastPart = part
end
