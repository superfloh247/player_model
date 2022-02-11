-- with a lot of inspiration from https://github.com/bhull2010/minetest-mod-models

player_model = {}
player_model.list = {}

player_model.register_model = function(name, modeldef)
    print("[player_model]: register_model("..name..")")
	player_model.list[name] = modeldef
end

for regentityname, ent in pairs(minetest.registered_entities) do
    if string.find(regentityname, '^petz:')
      or string.find(regentityname, '^animalworld:') 
      or string.find(regentityname, '^mobs_animal:') 
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

player_model.update_player_model = function(player, modelname)
    print("[player_model]: update_player_model("..player:get_player_name()..","..modelname..")" .. dump(player_model.list[modelname]))
    player:set_texture_mod("player_model")
	player:set_properties({
		visual = "mesh",
		mesh = player_model.list[modelname].mesh,
		textures = player_model.list[modelname].textures,
		visual_size = player_model.list[modelname].visual_size,
		collisionbox = player_model.list[modelname].collisionbox,
        damage_texture_modifier = ""
	})
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

minetest.register_chatcommand("list_player_models", {
	func = function(playername, param)
        local list = "player models: "
        for name in pairs(player_model.list) do
            list = list .. name .. " "
        end
        minetest.chat_send_player(playername, list)
	end
})

print("[player_model]: initialized")