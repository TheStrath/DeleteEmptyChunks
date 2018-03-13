script.on_event({defines.events.on_player_created, defines.events.on_player_joined_game, defines.events.on_player_respawned}, function(event)
	local player = game.players[event.player_index]
	DeleteEmptyChunks_ShowButton(player)
end)

script.on_event(defines.events.on_tick, function (event)
	if (game.tick % 120 == 0) then
		for player_index, player in pairs(game.players) do
			if not player.gui.left.DeleteEmptyChunks_button then 
				DeleteEmptyChunks_ShowButton(player)
			end
		end
	end
end)

function DeleteEmptyChunks_ShowButton(player)
  if player ~= nil and player.valid then
    local gui = player.gui.left
    if not gui.DeleteEmptyChunks_button then
      local button = gui.add({type="button", name="DeleteEmptyChunks_button", caption = "Delete Empty Chunks"})
    end
  end
end

script.on_event(defines.events.on_gui_click, function(event)
	if event.element.name == "DeleteEmptyChunks_button" then 
		DeleteEmptyChunks_doit() 
	end
end)

function DeleteEmptyChunks_doit()
	local radius =  settings.global["DeleteEmptyChunks_radius"].value
	local paving =  settings.global["DeleteEmptyChunks_paving"].value
	local paving_list = {"concrete", "stone-path", "hazard-concrete-left", "hazard-concrete-right"}

	local count_with_entities = 0
	local count_with_paving = 0
	local count_adjacent = 0
	local count_total_chunks = 0
	local count_keep = 0
	local count_deleted = 0
	
	-- all player forces
	local i_players = 0
	local playerForceNames = {}
	for player_index, player in pairs(game.players) do
		i_players = i_players + 1
		playerForceNames[i_players] = player.force.name
	end
	local forcesString = ""
	for n1, forceName in pairs (playerForceNames) do
		if forcesString == "" then
			forcesString = forceName
		else
			forcesString = forcesString .. ", " .. forceName
		end
	end
	printAll("Forces: " .. forcesString)

	-- Iterate Surfaces
	for n2, surface in pairs (game.surfaces) do
		local chunks = surface.get_chunks()
		local keepcords = {}

		-- First Pass
		for chunk in (chunks) do
			local count = 0
			local hasPaving = false
			local overlap = 1
			local chunkArea = {{chunk.x*32-overlap, chunk.y*32-overlap}, {chunk.x*32+32+overlap, chunk.y*32+32+overlap}}
			for n3, forceName in pairs (playerForceNames) do
				count = surface.count_entities_filtered{area=chunkArea, force=forceName, limit=1}
			end
			if count == 0 and paving then
				local pavedArea = {{chunk.x*32, chunk.y*32}, {chunk.x*32+32, chunk.y*32+32}}
				for i, tileName in pairs (paving_list) do
					if surface.count_tiles_filtered{area=pavedArea, name=tileName, limit=1} ~= 0 then
						hasPaving = true
						break
					end
				end
			end
			if count > 0 then 
				if keepcords[chunk.x] == nil then
					keepcords[chunk.x]={}
				end
				keepcords[chunk.x][chunk.y]=1
				count_with_entities = count_with_entities + 1
			elseif hasPaving then 
				if keepcords[chunk.x] == nil then
					keepcords[chunk.x]={}
				end
				keepcords[chunk.x][chunk.y]=1
				count_with_paving = count_with_paving + 1
			end
			count_total_chunks = count_total_chunks + 1
		end

		printAll("Starting with " .. count_total_chunks .." chunks")
		printAll("Chunks with player entities: " .. count_with_entities)
		if paving and count_with_paving > 0 then
			printAll("Empty chunks with paving: " .. count_with_paving)
		end

		-- Second Pass
		chunks = surface.get_chunks()
		for chunk in (chunks) do
			local mustClean = true
			if keepcords[chunk.x] ~= nil and keepcords[chunk.x][chunk.y] ~= nil then
				mustClean = false
			elseif radius > 0 then
				for i, x in pairs(keepcords) do
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
		-- Done
		if radius > 0 then
			printAll("Chunks adjacent: " .. count_adjacent)
		end
		printAll("Keeping " .. count_keep .. " chunks")
		printAll("Deleted " .. count_deleted .. " chunks")
	end
end

function printAll(text)
	log (text)
	for player_index, player in pairs (game.players) do
		game.players[player_index].print (text)
	end
end