-- with a lot of inspiration from https://github.com/bhull2010/minetest-mod-models

player_model = {}
player_model.list = {}
player_model.players = {}

local armormod = nil
if armor ~= nil then
    armormod = armor
elseif mcl_armor ~= nil then
    armormod = mcl_armor
end

player_model.register_model = function(name, modeldef)
    print("[player_model]: register_model("..name..")")
	player_model.list[name] = modeldef
end

for regentityname, ent in pairs(minetest.registered_entities) do
    if string.find(regentityname, '^petz:')
      or string.find(regentityname, '^animalworld:')
      or string.find(regentityname, '^mobs_animal:')
      or string.find(regentityname, '^extra_mobs:')
      or string.find(regentityname, '^mobs:')
      or string.find(regentityname, '^mobs_mc:') then
        if minetest.registered_entities[regentityname]['mesh'] ~= nil
          and (minetest.registered_entities[regentityname]['textures'] ~= nil or minetest.registered_entities[regentityname]['texture_list'] ~= nil)
          and minetest.registered_entities[regentityname]['collisionbox'] ~= nil 
          and minetest.registered_entities[regentityname]['visual'] == "mesh" then
            local modeldef = {}
            modeldef.mesh = minetest.registered_entities[regentityname]['mesh']
            modeldef.visual_size = minetest.registered_entities[regentityname]['visual_size'] or {x = 1, y = 1}
            modeldef.collisionbox = minetest.registered_entities[regentityname]['collisionbox']
            if type(minetest.registered_entities[regentityname]['textures']) == "table" then 
                modeldef.textures = minetest.registered_entities[regentityname]['textures'][1]
            elseif type(minetest.registered_entities[regentityname]['texture_list']) == "table" then
                modeldef.textures = minetest.registered_entities[regentityname]['texture_list'][1]
            elseif minetest.registered_entities[regentityname]['textures'] ~= nil then
                modeldef.textures = minetest.registered_entities[regentityname]['textures']
            end
            if modeldef.textures then 
                player_model.register_model(regentityname, modeldef)
            end
           end
    end
end

-- wrap 3d_armor to disable it temporarily
if armormod ~= nil then
    armormod.disabled = {}
    local armormod_update_player_visuals = function() end
    if armor ~= nil then
        armormod_update_player_visuals = armormod.update_player_visuals
    elseif mcl_armor ~= nil then
        armormod_update_player_visuals = armormod.update
    end
    armormod.update_player_visuals = function(self, player)
        if armormod.disabled[player:get_player_name()] == "true" then
            -- do nothing
        else
            armormod_update_player_visuals(self, player)
        end
    end
end

player_model.update_player_model = function(player, modelname)
    print("[player_model]: update_player_model("..player:get_player_name()..","..modelname..")")
    if armormod ~= nil then
        armormod.disabled[player:get_player_name()] = "true"
    end
    if player_model.players[player:get_player_name()] == nil then
        -- first shapeshift, store original model for reset
        player_model.players[player:get_player_name()] = {}
        player_model.players[player:get_player_name()]['original'] = { 
            visual = player:get_properties()['visual'], 
            mesh = player:get_properties()['mesh'], 
            textures = player:get_properties()['textures'],
            visual_size = player:get_properties()['visual_size'],
            collisionbox = player:get_properties()['collisionbox'],
            damage_texture_modifier = player:get_properties()['damage_texture_modifier']
        }
    end
    player:set_properties({
		visual = "mesh",
		mesh = player_model.list[modelname].mesh,
		textures = player_model.list[modelname].textures,
		visual_size = player_model.list[modelname].visual_size,
		collisionbox = player_model.list[modelname].collisionbox,
        damage_texture_modifier = ""
	})
    player:get_meta():set_string("player_model", modelname)
end

minetest.register_chatcommand("set_player_model", {
	params = "<modelname>",
	func = function(playername, param)
		if param == nil or param == "" then
			minetest.chat_send_player(playername, "no model name given")
			return
		end
        if player_model.list[param] ~= nil then
    		player_model.update_player_model(minetest.get_player_by_name(playername), param)
            minetest.chat_send_player(playername, "model "..param.." set")
        else
            minetest.chat_send_player(playername, "model "..param.." not found")
        end
	end
})

player_model.reset_player_model = function(playername)
    if player_model.players[playername] ~= nil and player_model.players[playername]['original'] then
        minetest.get_player_by_name(playername):set_properties({
            visual = player_model.players[playername]['original']['visual'],
            mesh = player_model.players[playername]['original']['mesh'],
            textures = player_model.players[playername]['original']['textures'],
            visual_size = player_model.players[playername]['original']['visual_size'],
            collisionbox = player_model.players[playername]['original']['collisionbox'],
            damage_texture_modifier = player_model.players[playername]['original']['damage_texture_modifier']
        })
        minetest.chat_send_player(playername, "model reset")
        if armormod ~= nil then
            armormod.disabled[playername] = "false"
            armormod.update_player_visuals(minetest.get_player_by_name(playername))
        end
    end
end

minetest.register_chatcommand("reset_player_model", {
	func = function(playername, param)
		if player_model.players[playername] ~= nil and player_model.players[playername]['original'] then
            minetest.get_player_by_name(playername):set_properties({
                visual = player_model.players[playername]['original']['visual'],
                mesh = player_model.players[playername]['original']['mesh'],
                textures = player_model.players[playername]['original']['textures'],
                visual_size = player_model.players[playername]['original']['visual_size'],
                collisionbox = player_model.players[playername]['original']['collisionbox'],
                damage_texture_modifier = player_model.players[playername]['original']['damage_texture_modifier']
            })
            minetest.chat_send_player(playername, "model reset")
            if armormod ~= nil then
                armormod.disabled[playername] = "false"
            end
        end
    end
})

minetest.register_chatcommand("list_player_models", {
	func = function(playername, param)
        local list = "player models: "
        for name in pairs(player_model.list) do
            list = list .. name .. " "
        end
        minetest.chat_send_player(playername, list)
	end
})

minetest.register_chatcommand("player_models", {
	func = function(playername, param)
        local formspec = "size[4,3]".."label[0,0;Select Model]"
        local models = {}
        for k,v in pairs(player_model.list) do
            table.insert(models, k)
        end
        table.sort(models, function(a, b) return a < b end)
        formspec = formspec.."dropdown[0,1;4;dropdownModel;"..table.concat(models, ",")..";0;false]"
        formspec = formspec.."button_exit[0,2;2,1;btSet;Set Model]"
        formspec = formspec.."button_exit[2,2;2,1;btReset;Reset Model]"
        minetest.show_formspec(playername, 'player_models_show_ui', formspec)
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == 'player_models_show_ui' then
        if fields ~= nil and fields['btSet'] ~= nil and fields['dropdownModel'] ~= nil then
            player_model.update_player_model(player, fields['dropdownModel'])
        elseif fields ~= nil and fields['btReset'] ~= nil then
            local playername = player:get_player_name()
            if player_model.players[playername] ~= nil and player_model.players[playername]['original'] then
                minetest.get_player_by_name(playername):set_properties({
                    visual = player_model.players[playername]['original']['visual'],
                    mesh = player_model.players[playername]['original']['mesh'],
                    textures = player_model.players[playername]['original']['textures'],
                    visual_size = player_model.players[playername]['original']['visual_size'],
                    collisionbox = player_model.players[playername]['original']['collisionbox'],
                    damage_texture_modifier = player_model.players[playername]['original']['damage_texture_modifier']
                })
                minetest.chat_send_player(playername, "model reset")
                if armormod ~= nil then
                    armormod.disabled[playername] = "false"
                end
            end
        end
    end
end)

print("[player_model]: initialized")