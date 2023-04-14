local s = core.get_mod_storage()
local F = core.formspec_escape
local delay = {}
local selected = {}
local reportlist = {}

core.register_privilege("reportbox_staff",{give_to_singleplayer=false})

purge_reportbox = function()
	local s_table = s and s:to_table() and s:to_table().fields
	local list = {}
	for title,content in pairs(s_table) do
		if type(title) == "string" then
			s:set_string(title,"")
		end
	end
end

local staff_fs = function(name, text)
	local s_table = s and s:to_table() and s:to_table().fields
	local list = {}
	for title,content in pairs(s_table) do
		if title and title ~= "" then
			table.insert(list,title)
		end
	end
	table.sort(list)
	reportlist[name] = list
	local fs = "size[16,10]" ..
		"label[0.2,0.1;List of reports & suggestions]" ..
		"box[5.5,0.2;10,9.6;#000]" ..
		"textlist[0.2,0.5;5.2,8.5;reports;"..table.concat(list,",").."]" ..
		"textarea[5.8,0.2;10.2,11.2;;"..(list[selected[name]] or "")..";"..(text or "").."]" ..
		"button[0.2,9;1.5,1;open;Open]" ..
		"button[1.7,9;1.5,1;delete;Delete]" ..
		"button[4.1,9;1.5,1;sendnew;Send new]"
	core.show_formspec(name,"reportbox_staff",fs)
end

local player_fs = function(name)
	local fs = "size[10,10]" ..
		"field[0.6,0.6;9.5,1;title;Title;]" ..
		"field_close_on_enter[title;false]" ..
		"textarea[0.6,1.4;9.5,9;text;Text;]" ..
		"button[0.3,9.1;9.5,1;send;Send]"
	core.show_formspec(name,"reportbox",fs)
end

local on_rclick = function(pos, node, player, itemstack, pointed_thing)
	local name = player and player:get_player_name()
	if not name then return end
	local is_staff = core.check_player_privs(name,{reportbox_staff=true})
	if is_staff then
		staff_fs(name)
	else
		player_fs(name)
	end
end

core.register_on_player_receive_fields(function(player, formname, fields)
	local name = player and player:get_player_name()
	if not name then return end
	if formname == "reportbox" then
		if fields.send then
			if delay[name] then
				core.chat_send_player(name,"You have to wait 1 hour before sending another report/suggestion")
				return
			end
			if not fields.title or fields.title == "" then
				core.chat_send_player(name,"Please fill title")
				return
			end
			if not fields.text or not fields.text:match("%S+") then
				core.chat_send_player(name,"Please type text of the report/suggestion")
				return
			end
			local date = os.date()
			s:set_string(date.." "..name.." - '"..F(fields.title).."'",F(fields.text))
			if not core.check_player_privs(name,{reportbox_staff=true}) then
				delay[name] = true
				core.after(3600, function()
					delay[name] = nil
				end)
			end
			core.close_formspec(name,"reportbox")
			core.chat_send_player(name,"'"..fields.title.."' sent successfully")
		end
	end
	if formname == "reportbox_staff" then
		local list = reportlist[name]
		local text = selected[name] and list[selected[name]] and s:get_string(list[selected[name]]) or ""
		if fields.reports then
			local evnt = core.explode_textlist_event(fields.reports)
			selected[name] = evnt.index
			text = list[evnt.index] and s:get_string(list[evnt.index]) or ""
			if evnt.type == "DCL" then
				staff_fs(name,text)
			end
		end
		if fields.open then
			staff_fs(name,text)
		end
		if fields.delete and list[selected[name]] then
			s:set_string(list[selected[name]],"")
			staff_fs(name)
		end
		if fields.sendnew then
			player_fs(name)
		end
	end
end)

core.register_node("reportbox:reportbox",{
  description = "ReportBox",
  tiles = {"reportbox.png","reportbox.png","reportbox.png","reportbox.png","reportbox.png","reportbox_front.png"},
  paramtype2 = "facedir",
  groups = {unbreakable=1},
  light_source = 14,
  on_rightclick = on_rclick,
})
