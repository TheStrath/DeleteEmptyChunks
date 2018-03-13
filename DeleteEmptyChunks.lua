script.on_event(defines.events.on_player_created, function(event)
	game.players[event.player_index].print ("on_player_created")
	makeGUI (event.player_index)
end)

script.on_event(defines.events.on_player_respawned, function(event)
	game.players[event.player_index].print ("on_player_respawned")
	makeGUI (event.player_index)
end)

script.on_event(defines.events.on_tick, function (event)
	if not (global) then  global = {} end
	if not (global.timer) then  global.timer = 600 end
	global.timer = global.timer + 1
	if (game.tick % 120 == 0) then handler_on_tick() end --  GUI 
end)


function handler_on_tick()
	if not global then global = {} end
	if not global.GUI then global.GUI = {} end
	for player_index, player in pairs (game.players) do
		if not (global.GUI[player_index]) then
			makeGUI (player_index)
		end
	end
end

function makeGUI (player_index)
	-- local player
	local player = game.players[player_index]
	-- make GUI frame
	if player.gui.left.frameDEC == nil then
		local frame = player.gui.left.add{type = "frame", name = "frameDEC", direction = "horizontal"}
		frame.add{type = "button", name = "DeleteEmptyChunks", caption = "Delete Empty Chunks"}
		global.GUI[player_index] = true
	end
end

script.on_event(defines.events.on_gui_click, function(event)
	if event.element.name == "DeleteEmptyChunks" then 
		if global.timer < 600 then return end
		global.timer = 0
		main() 
	end
end)

function main()
	local playerForceNames = {}
	local i_players = 0
	
	-- all player forces
	for player_index, player in pairs(game.players) do
		i_players = i_players + 1
		playerForceNames[i_players] = player.force.name
		game.players[player_index].print ("Force:" .. player.force.name)
	end
	local countOK = 0
	local countDel = 0

	-- iterate surfaces
	for n1, surface in pairs (game.surfaces) do
		local chunks = surface.get_chunks()
		local i_chunk = 0
		
		-- iterate chunks
		for chunk in (chunks) do
		i_chunk = i_chunk + 1
			local mustClean = true
			local chunkArea = {{chunk.x*32, chunk.y*32}, {chunk.x*32+32, chunk.y*32+32}}
			for n3, forceName in pairs (playerForceNames) do
				--local entities = surface.find_entities_filtered{area=chunkArea, force=forceName, limit=1}
				local hasConcrete = false
				local count = surface.count_entities_filtered{area=chunkArea, force=forceName, limit=1} or 0
				--local count = 0
				--for n4, enitity in pairs(entities) do 
				--	count = count + 1 
				--end
				if count == 0 then
					for x=chunk.x*32,chunk.x*32+32 do
						for y=chunk.y*32,chunk.y*32+32 do
							local t = surface.get_tile(x,y)
							if t.valid and t.name == "concrete" then
								hasConcrete = true
								break
							end
						end
						if hasConcrete then
							break
						end
					end
				end
				
				if count>0 or hasConcrete then 
					mustClean = false 
					countOK = countOK + 1
					else
					countDel = countDel +1
				end
			end
			
			if mustClean then
				surface.delete_chunk({chunk.x, chunk.y})
			end
			
		end 
	end
	
	game.players[1].print ("countOK:" .. countOK)
	game.players[1].print ("countDel:" .. countDel)

end
