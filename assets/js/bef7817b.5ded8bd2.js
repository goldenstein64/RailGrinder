"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[215],{9503:function(e){e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Creates a new RailGrinder instance, which lets one \\"vessel\\" grind one rail.","params":[],"returns":[],"function_type":"static","source":{"line":46,"path":"src/init.lua"}},{"name":"Enable","desc":"Sets all properties required to start grinding the rail and starts updating\\nthem and firing events using a connection to [RunService.Heartbeat].\\n\\nThe `vessel` argument is only used to calculate the speed and alpha relative \\nto `currentPart`, so it is optional.","params":[{"name":"currentPart","desc":"The instance the `vessel` is grinding on.","lua_type":"BasePart"},{"name":"vessel","desc":"The instance grinding the rail.","lua_type":"BasePart?"}],"returns":[],"function_type":"method","source":{"line":195,"path":"src/init.lua"}},{"name":"Disable","desc":"Stops updating variables and firing events.","params":[],"returns":[],"function_type":"method","source":{"line":213,"path":"src/init.lua"}},{"name":"Update","desc":"A function that runs every `RunService.Heartbeat`, this fires the\\n`PositionChanged` event when finished and calls `GetNextPart` as needed.","params":[{"name":"deltaTime","desc":"The amount of time that passed since last update.","lua_type":"number"}],"returns":[],"function_type":"method","source":{"line":240,"path":"src/init.lua"}},{"name":"SetSpeed","desc":"Sets how fast the position should change","params":[{"name":"newSpeed","desc":"The new speed the RailGrinder should update at","lua_type":"number"}],"returns":[],"function_type":"method","source":{"line":281,"path":"src/init.lua"}},{"name":"GetNextPart","desc":"The callback used to get the next part once the vessel has grinded to\\nthe end of the current part.","params":[{"name":"direction","desc":"Which direction off the current part the character grinded off to","lua_type":"number"}],"returns":[{"desc":"The next part to grind on. Returning `nil` disables the RailGrinder instance.","lua_type":"Instance?"}],"function_type":"static","source":{"line":299,"path":"src/init.lua"}}],"properties":[{"name":"Enabled","desc":"Describes whether this RailGrinder is currently enabled.\\n\\nPlease use [RailGrinder:Enable] and [RailGrinder:Disable] to update this\\nvalue.\\n\\t","lua_type":"boolean","readonly":true,"source":{"line":74,"path":"src/init.lua"}},{"name":"CurrentPart","desc":"The part currently being grinded on.\\n\\t","lua_type":"RailPart","readonly":true,"source":{"line":83,"path":"src/init.lua"}},{"name":"Speed","desc":"Describes how fast the position changes every update. If you want to change this, \\nplease use [RailGrinder:SetSpeed].\\n\\t","lua_type":"number","readonly":true,"source":{"line":93,"path":"src/init.lua"}},{"name":"Position","desc":"The current position as calculated by [RailGrinder.Update].\\n\\t","lua_type":"Vector3","readonly":true,"source":{"line":102,"path":"src/init.lua"}},{"name":"Velocity","desc":"Describes how fast the position changes every update, represented as a \\nVector3 with a magnitude and direction. This exists for the end-user, and\\nonly updates when [RailGrinder.CurrentPart] or [RailGrinder.Speed] changes.\\n\\t","lua_type":"Vector3","readonly":true,"source":{"line":113,"path":"src/init.lua"}},{"name":"Alpha","desc":"Describes where [RailGrinder.Position] is between [RailGrinder.CurrentPart].Prev\\nand [RailGrinder.CurrentPart].Next.\\n\\t","lua_type":"number","private":true,"source":{"line":123,"path":"src/init.lua"}},{"name":"CurrentPartLength","desc":"The distance between [RailGrinder.CurrentPart].Prev and \\n[RailGrinder.CurrentPart].Next.\\n\\t","lua_type":"number","private":true,"source":{"line":133,"path":"src/init.lua"}},{"name":"Connection","desc":"The [RunService.Heartbeat] connection used to update the [RailGrinder]\\ninstance. If you want to disconnect this, use [RailGrinder:Disable].\\n\\t","lua_type":"RBXScriptConnection?","private":true,"source":{"line":143,"path":"src/init.lua"}},{"name":"Completed","desc":"Fires when this `RailGrinder` has finished or is disabled.\\n\\t","lua_type":"RBXScriptSignal<>","source":{"line":151,"path":"src/init.lua"}},{"name":"PositionChanged","desc":"Fires when [RailGrinder.Position] is updated.\\n\\t","lua_type":"RBXScriptSignal<Vector3>","source":{"line":159,"path":"src/init.lua"}},{"name":"PartChanged","desc":"Fires when [RailGrinder.CurrentPart] is updated\\n\\t","lua_type":"RBXScriptSignal<RailPart>","source":{"line":167,"path":"src/init.lua"}},{"name":"UpdateCallback","desc":"This function is called when [RunService.Heartbeat] fires. This is bound\\nautomatically by [RailGrinder:Enable].\\n\\t","lua_type":"(number) -> ()","source":{"line":176,"path":"src/init.lua"}}],"types":[{"name":"RailPart","desc":"A part with two child attachments `Prev` and `Next`. Typically, the `Next`\\nattachment of one part has the same position as the `Prev` attachment of another part.","lua_type":"BasePart & { Prev: Attachment, Next: Attachment }","source":{"line":44,"path":"src/init.lua"}}],"name":"RailGrinder","desc":"A helper class for calculating position and velocity of an object traveling \\nacross a collection of attachment pairs.","source":{"line":34,"path":"src/init.lua"}}')}}]);