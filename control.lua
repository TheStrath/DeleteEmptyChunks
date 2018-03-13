DeleteEmptyChunks = {}

script.on_event({defines.events.on_player_created, defines.events.on_player_joined_game, defines.events.on_player_respawned}, function(event)
	local player = game.players[event.player_index]
	DeleteEmptyChunks_ShowButton(player)
end)

script.on_event(defines.events.on_tick, function (event)
	if (game.tick % 120 == 0) then
		for _, player in pairs(game.players) do
			if not player.gui.left.DeleteEmptyChunks_button then 
				DeleteEmptyChunks.ShowButton(player)
			end
		end
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
	if event.element.name == "DeleteEmptyChunks_button" then 
		DeleteEmptyChunks.doit() 
	end
end)

function DeleteEmptyChunks.ShowButton(player)
	if player ~= nil and player.valid then
		local gui = player.gui.left
		if not gui.DeleteEmptyChunks_button then
			local button = gui.add({type="button", name="DeleteEmptyChunks_button", caption = {'DeleteEmptyChunks_buttontext'}})
		end
	end
end

function DeleteEmptyChunks.doit()
	local radius = settings.global["DeleteEmptyChunks_radius"].value
	local paving = settings.global["DeleteEmptyChunks_paving"].value
	local printAll = DeleteEmptyChunks.printAll
	local getKeepList = DeleteEmptyChunks.getKeepList
	local deleteChunks = DeleteEmptyChunks.deleteChunks
	local paving_list = {}

	local surface_Factorissimo2_name = "Factory floor "
	local surface_Factorissimo2_skiped = 0
	
	if paving then
		printAll({'DeleteEmptyChunks_text_notifier_with', radius})
		paving_list = {"concrete", "stone-path", "hazard-concrete-left", "hazard-concrete-right"}
		if game.active_mods["AsphaltRoads"] then
			local AsphaltRoads_list = DeleteEmptyChunks.getAsphaltRoads()
			for _,v in ipairs(AsphaltRoads_list) do 
				table.insert(paving_list, v)
			end
			printAll({'DeleteEmptyChunks_text_AsphaltRoads', #AsphaltRoads_list})
		end
	else
		printAll({'DeleteEmptyChunks_text_notifier_without', radius})
	end
	
	-- all player forces
	local playerForceNames = {}
	for _, player in pairs(game.players) do
		table.insert( playerForceNames, player.force.name )
	end
	printAll({'DeleteEmptyChunks_text_force',DeleteEmptyChunks.table_to_csv(playerForceNames)})

	-- Iterate Surfaces
	for _, surface in pairs (game.surfaces) do
		if string.sub(surface.name,1,string.len(surface_Factorissimo2_name)) == surface_Factorissimo2_name then
			surface_Factorissimo2_skiped = surface_Factorissimo2_skiped + 1
		else
			-- First Pass
			local list = getKeepList(surface, playerForceNames, radius == 0 and 1 or 0, paving_list)
			printAll({'DeleteEmptyChunks_text_starting', list.total, surface.name})
			printAll({'DeleteEmptyChunks_text_entities', list.occupied})
			if paving and list.paved > 0 then
				printAll({'DeleteEmptyChunks_text_paving', list.paved})
			end
			-- Second Pass
			local result = deleteChunks(surface, list.coordinates, radius)
			-- Done
			if radius > 0 then
				printAll({'DeleteEmptyChunks_text_adjacent', result.adjacent})
			end
			printAll({'DeleteEmptyChunks_text_keep', result.kept})
			printAll({'DeleteEmptyChunks_text_delete', result.deleted})
		end
	end
	if surface_Factorissimo2_skiped > 0 then
		printAll({'DeleteEmptyChunks_text_Factorissimo2', surface_Factorissimo2_skiped})
	end
end

function DeleteEmptyChunks.printAll(text)
	log (text)
	for player_index, player in pairs (game.players) do
		game.players[player_index].print (text)
	end
end

function DeleteEmptyChunks.table_to_csv(list)
	local str = ""
	for _, item in pairs (list) do
		if str ~= "" then
			str = str .. ", " .. item
		else
			str = item
		end
	end
	return str
end

function DeleteEmptyChunks.getKeepList(surface, playerForceNames, overlap, pavers)
	local count_entities = surface.count_entities_filtered
	local count_tiles = surface.count_tiles_filtered
	local count_total_chunks = 0
	local count_with_entities = 0
	local count_with_paving = 0
	local keepcords = {}
	local chunks = surface.get_chunks()
	for chunk in (chunks) do
		local chunk_occupied = false
		local chunk_paved = false
		local chunkArea = {{chunk.x*32-overlap, chunk.y*32-overlap}, {chunk.x*32+32+overlap, chunk.y*32+32+overlap}}
		for _, forceName in pairs (playerForceNames) do
			if count_entities{area=chunkArea, force=forceName, limit=1} ~= 0 then
				chunk_occupied = true
				break
			end
		end
		if not chunk_occupied and #pavers then
			local pavedArea = {{chunk.x*32, chunk.y*32}, {chunk.x*32+32, chunk.y*32+32}}
			for _, tileName in pairs (pavers) do
				if count_tiles{area=pavedArea, name=tileName, limit=1} ~= 0 then
					chunk_paved = true
					break
				end
			end
		end
		if chunk_occupied or chunk_paved then 
			if keepcords[chunk.x] == nil then
				keepcords[chunk.x]={}
			end
			keepcords[chunk.x][chunk.y]=1
			if chunk_occupied then 
				count_with_entities = count_with_entities + 1
			elseif chunk_paved then 
				count_with_paving = count_with_paving + 1
			end
		end
		count_total_chunks = count_total_chunks + 1
	end
	return {total=count_total_chunks, occupied=count_with_entities, paved=count_with_paving, coordinates=keepcords}
end

function DeleteEmptyChunks.deleteChunks(surface, coordinates, radius)
	local count_adjacent = 0
	local count_keep = 0
	local count_deleted = 0
	local chunks = surface.get_chunks()
	for chunk in (chunks) do
		local mustClean = true
		if coordinates[chunk.x] ~= nil and coordinates[chunk.x][chunk.y] ~= nil then
			mustClean = false
		elseif radius > 0 then
			for i, x in pairs(coordinates) do
				if chunk.x <= i + radius and chunk.x >= i - radius then
					for j, y in pairs(x) do
						if chunk.y <= j + radius and chunk.y >= j - radius then
							mustClean = false
							count_adjacent = count_adjacent + 1
							break
						end
					end
					if not mustClean then
						break
					end
				end
			end
		end
		if mustClean then
			surface.delete_chunk({chunk.x, chunk.y})
			count_deleted = count_deleted + 1
		else
			count_keep = count_keep + 1
		end
	end
	return {adjacent=count_adjacent, deleted=count_deleted, kept=count_keep}
end

function DeleteEmptyChunks.getAsphaltRoads()
	local list = {"Arci-asphalt"}
	
	local prefix = "Arci-"
	
	local type1_tilesets = {"asphalt-zebra-crossing"}
	local type2_tilesets = {"asphalt-triangle-white"}
	local type3_tilesets = {"asphalt-hazard-white", "asphalt-hazard-yellow", "asphalt-hazard-red", "asphalt-hazard-blue", "asphalt-hazard-green"}
	local type4_tilesets = {"marking-white", "marking-white-dl"}
	local type5_tilesets = {"marking-yellow", "marking-yellow-dl"}

	local type1_directions = {"-horizontal","-vertical"}
	local type2_directions = {"-up","-right","-down","-left"}
	local type3_directions = {"-right","-left"}
	local type4_directions = {"-straight-horizontal","-straight-vertical",
	                          "-diagonal-left","-diagonal-right",
	                          "-right-turn-up","-right-turn-right","-right-turn-down","-right-turn-left",
	                          "-left-turn-up","-left-turn-right","-left-turn-down","-left-turn-left"}
	local type5_directions = {"-straight-horizontal","-straight-vertical",
	                          "-diagonal-left","-diagonal-right",
	                          "-right-turn-up","-right-turn-right","-right-turn-down","-right-turn-left",
	                          "-left-turn-up","-left-turn-right","-left-turn-down","-left-turn-left"}

	for i=1, #type1_tilesets do
		for j=1, #type1_directions do
			table.insert(list, prefix .. type1_tilesets[i] .. type1_directions[j])
		end
	end
	for i=1, #type2_tilesets do
		for j=1, #type2_directions do
			table.insert(list, prefix .. type2_tilesets[i] .. type2_directions[j])
		end
	end
	for i=1, #type3_tilesets do
		for j=1, #type3_directions do
			table.insert(list, prefix .. type3_tilesets[i] .. type3_directions[j])
		end
	end
	for i=1, #type4_tilesets do
		for j=1, #type4_directions do
			table.insert(list, prefix .. type4_tilesets[i] .. type4_directions[j])
		end
	end
	for i=1, #type5_tilesets do
		for j=1, #type5_directions do
			table.insert(list, prefix .. type5_tilesets[i] .. type5_directions[j])
		end
	end
	return list
end
