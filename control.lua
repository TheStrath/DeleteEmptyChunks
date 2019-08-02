require("mod-gui")

function doit()
	local target_surface = settings.global["DeleteEmptyChunks_surface"].value
	local radius = settings.global["DeleteEmptyChunks_radius"].value
	local paving = settings.global["DeleteEmptyChunks_paving"].value
	local printAll = printAll
	local getKeepList = getKeepList
	local deleteChunks = deleteChunks
	local vanilla_paving_list = {"concrete", "hazard-concrete-left", "hazard-concrete-right", "refined-concrete",
	                             "refined-hazard-concrete-left", "refined-hazard-concrete-right", "stone-path" }
	-- ignoring these vanilla tiles: {"landfill", "water-mud", "water-shallow" 
	local paving_list = {}
	local surface_list = {}
	local mod_surface_skipped = 0
	
	if paving then
		paving_list = getPavingTiles()
		--log(table_to_csv(paving_list))
	end
	if #paving_list > 0 then
		if radius > 0 then
			printAll({'DeleteEmptyChunks_text_notifier_pr', radius})
		else
			printAll({'DeleteEmptyChunks_text_notifier_p'})
		end
		printAll({'DeleteEmptyChunks_text_notifier_paving', #paving_list, #vanilla_paving_list, #paving_list - #vanilla_paving_list})
	else
		if radius > 0 then
			printAll({'DeleteEmptyChunks_text_notifier_r', radius})
		else
			printAll({'DeleteEmptyChunks_text_notifier'})
		end
	end
	
	-- all player forces
	local playerForceNames = {}
	local playerPositions = {}
	for _, player in pairs(game.players) do
		table.insert( playerForceNames, player.force.name )
		table.insert( playerPositions, {x = math.floor(player.position.x / 32), y = math.floor(player.position.y / 32)})
	end
	if #playerForceNames > 1 then printAll({'DeleteEmptyChunks_text_force', table_to_csv(playerForceNames)}) end
	local found = false
	-- Iterate Surfaces
	for _, surface in pairs (game.surfaces) do
		table.insert( surface_list, surface.name )
		if surface.name == target_surface then
			-- First Pass
			local list = getKeepList(surface, playerForceNames, radius == 0 and 1 or 0, paving_list)
			-- Save players from the void
			for _, position in pairs(playerPositions) do
				if list.coordinates[position.x] == nil then
					list.coordinates[position.x]={}
				end
				list.coordinates[position.x][position.y]=1
			end
			-- Second Pass
			local result = deleteChunks(surface, list.coordinates, radius)
			-- Done
			printAll({'DeleteEmptyChunks_text_starting', list.total, surface.name, list.total - list.uncharted})
			if result.kept > 0 then
				if list.occupied > 0 then
					if list.paved > 0 then
						if result.adjacent > 0 then
							printAll({'DeleteEmptyChunks_text_keep_epa', result.kept, list.occupied, list.paved, result.adjacent})
						else
							printAll({'DeleteEmptyChunks_text_keep_ep', result.kept, list.occupied, list.paved})
						end
					else
						if result.adjacent > 0 then
							printAll({'DeleteEmptyChunks_text_keep_ea', result.kept, list.occupied, result.adjacent})
						else
							printAll({'DeleteEmptyChunks_text_keep_e', result.kept, list.occupied})
						end
					end
				elseif list.paved > 0 then
					if result.adjacent > 0 then
						printAll({'DeleteEmptyChunks_text_keep_pa', result.kept, list.paved, result.adjacent})
					else
						printAll({'DeleteEmptyChunks_text_keep_p', result.kept, list.paved})
					end
				end
			end
			printAll({'DeleteEmptyChunks_text_delete', result.deleted})
			found = true
			if game.active_mods["rso-mod"] then
				remote.call("RSO", "disableStartingArea")
				remote.call("RSO", "resetGeneration", surface)
			end
		end
	end
	if not found and #surface_list > 0 then
		printAll({'DeleteEmptyChunks_text_mod_nosurface', target_surface, table_to_csv(surface_list)})
	end
	if mod_surface_skipped > 0 then
		printAll({'DeleteEmptyChunks_text_mod_surfaces', mod_surface_skipped})
	end
end
commands.add_command("DeleteEmptyChunks", {"DeleteEmptyChunks_command"}, doit)

remote.add_interface('DeleteEmptyChunks',
{
	DeleteEmptyChunks = doit
})


function printAll(text)
	log(text)
	game.print(text)
end

function table_to_csv(list)
	local str = ""
	for _, item in pairs (list) do
		if string.len(str) > 0 then
			str = str .. "\", \"" .. item
		else
			str = "\"" .. item
		end
	end
	if string.len(str) > 0 then
		str = str .. "\""
	end
	return str
end

function getPavingTiles()
	local paving_list = {}
	local non_paving = {"deepwater", "deepwater-green", "dirt-1", "dirt-2", "dirt-3", "dirt-4", "dirt-5",
	                    "dirt-6", "dirt-7", "dry-dirt", "grass-1", "grass-2", "grass-3", "grass-4", "lab-dark-1",
	                    "lab-dark-2", "lab-white", "out-of-map", "red-desert-0", "red-desert-1", "red-desert-2",
	                    "red-desert-3", "sand-1", "sand-2", "sand-3", "tutorial-grid", "water", "water-green",
	                    "landfill", "water-mud", "water-shallow"}
	
	local Factorissimo2_tiles = {"factory-entrance-1", "factory-entrance-2", "factory-entrance-3", "factory-floor-1",
	                             "factory-floor-2", "factory-floor-3", "factory-pattern-1", "factory-pattern-2",
	                             "factory-pattern-3", "factory-wall-1", "factory-wall-2", "factory-wall-3", "out-of-factory"}
	if game.active_mods["Factorissimo2"] then
		for _, v in ipairs(Factorissimo2_tiles) do 
			table.insert(non_paving, v)
		end
	end
	
	local Surfaces_remake_tiles = {"sky-void", "underground-dirt", "underground-wall", "wooden-floor"}
	if game.active_mods["Surfaces_remake"] then
		for _, v in ipairs(Surfaces_remake_tiles) do 
			table.insert(non_paving, v)
		end
	end
	
	for _, t in pairs(game.tile_prototypes) do
		local found = false
		for _, s in pairs(non_paving) do
			if t.name == s then
				found = true
				break
			end
		end
		if not found then
			table.insert(paving_list, t.name)
		end
	end
	return paving_list
end

function getKeepList(surface, playerForceNames, overlap, pavers)
	local count_entities = surface.count_entities_filtered
	local count_tiles = surface.count_tiles_filtered
	local count_total_chunks = 0
	local count_uncharted = 0
	local count_with_entities = 0
	local count_with_paving = 0
	local keepcords = {}
	local chunks = surface.get_chunks()
	for chunk in (chunks) do
		local chunk_occupied = false
		local chunk_charted = false
		local chunk_paved = false
		local chunkArea = {{chunk.x*32-overlap, chunk.y*32-overlap}, {chunk.x*32+32+overlap, chunk.y*32+32+overlap}}
		for _, forceName in pairs (playerForceNames) do
			if game.forces[forceName].is_chunk_charted( surface, chunk ) then
				chunk_charted = true
				break
			end
		end
		if chunk_charted then
			for _, forceName in pairs (playerForceNames) do
				if count_entities{area=chunkArea, force=forceName, limit=1} ~= 0 then
					chunk_occupied = true
					break
				end
			end
			if not chunk_occupied and #pavers > 0 then
				local pavedArea = {{chunk.x*32, chunk.y*32}, {chunk.x*32+32, chunk.y*32+32}}
				if count_tiles{area=pavedArea, name=pavers, limit=1} ~= 0 then
					chunk_paved = true
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
		else
			count_uncharted = count_uncharted + 1
		end
		count_total_chunks = count_total_chunks + 1
	end
	return {total=count_total_chunks, occupied=count_with_entities, paved=count_with_paving, coordinates=keepcords, uncharted = count_uncharted}
end

function deleteChunks(surface, coordinates, radius)
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

function show_gui(player)
	local gui = mod_gui.get_button_flow(player)
	if not gui.DeleteEmptyChunks then
		gui.add{
			type = "sprite-button",
			name = "DeleteEmptyChunks",
			sprite = "DeleteEmptyChunks_button",
			style = mod_gui.button_style,
			tooltip = {'DeleteEmptyChunks_buttontext'}
		}
	end
end

do---- Init ----
script.on_init(function()
	for _, player in pairs(game.players) do
		if player and player.valid then show_gui(player) end
	end
end)

script.on_configuration_changed(function(data)
	for _, player in pairs(game.players) do
		if player and player.valid then
			if player.gui.left.DeleteEmptyChunks_button then	player.gui.left.DeleteEmptyChunks_button.destroy()	end
			show_gui(player)
		end
	end
end)

script.on_event({defines.events.on_player_created, defines.events.on_player_joined_game, defines.events.on_player_respawned}, function(event)
  local player = game.players[event.player_index]
  if player and player.valid then show_gui(player) end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local gui = event.element
  local player = game.players[event.player_index]
  if not (player and player.valid and gui and gui.valid) then return end
  if gui.name == "DeleteEmptyChunks" then doit() end
end)
end
