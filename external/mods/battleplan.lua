-- BATTLEPLAN: Renders MK-like arcade ladders.
-- Author: Wreq!

battleplan = {}
battleplan.ladder = -1
battleplan.ladderData = {}
battleplan.ladderSelected = false
battleplan.timerSelect = -1
battleplan.dataLoaded = false
battleplan.fadeout = false
battleplan.finished = false
local max_z = 1000

-- --------------------------------
-- GENERAL FUNCTIONS
-- --------------------------------

-- --------------------------------
-- BATTLEPLAN BEHAVIOR
-- --------------------------------

-- Function: Creates scale multiplier from given z.
local function zScaleMul(z)
	return 1 - z / max_z
end

-- Function: Manages general battleplan behavior.
function battleplan.f_selectBattleplan()
	-- Init motif data in case it wasn't loaded
	if not battleplan.dataLoaded then
		battleplan.f_setBaseBattleplanInfo()
		battleplan.f_initMotifData()
		battleplan.dataLoaded = true
	end
	-- Init battleplan instance
	if not battleplan.ladderSelected then 
		battleplan.f_resetLaddersPos()
	end
	battleplan.fadeout = false
	battleplan.finished = false
	main.f_fadeReset('fadein', motif.battleplan)
	main.f_playBGM(false, motif.music.battleplan_bgm, motif.music.battleplan_bgm_loop, motif.music.battleplan_bgm_volume, motif.music.battleplan_bgm_loopstart, motif.music.battleplan_bgm_loopend)
	-- Loop behavior
	while not battleplan.finished do
		-- ladder select behavior 
		if not battleplan.ladderSelected then
			battleplan.f_selectLadder()
		else
			-- Get current frame pos values for selected ladder
			local x = battleplan.ladderData[battleplan.ladder].pos[1]
			local y = battleplan.ladderData[battleplan.ladder].pos[2]
			local z = battleplan.ladderData[battleplan.ladder].pos[3]
			-- FIRST PHASE: Center selected ladder on the screen
			if x ~= motif.info.localcoord[1] / 2 then
				for k, v in ipairs(battleplan.ladderData) do
					if math.abs(motif.info.localcoord[1] / 2 - x) < motif.battleplan.battleplan_center_vel then
						v.pos[1] = v.pos[1] + motif.info.localcoord[1] / 2 - x
					elseif x > motif.info.localcoord[1] / 2 then
						v.pos[1] = v.pos[1] - motif.battleplan.battleplan_center_vel
					elseif x < motif.info.localcoord[1] / 2 then
						v.pos[1] = v.pos[1] + motif.battleplan.battleplan_center_vel
					end
					battleplan.f_updateLadderPos(k)
				end
			-- SECOND PHASE: Zoom selected ladder
			elseif z > 0 then
				for k, v in ipairs(battleplan.ladderData) do
					-- Zoom selected ladder
					if k == battleplan.ladder then
						v.pos[3] = v.pos[3] - motif.battleplan.battleplan_zoom_vel
						local angle_y = v.ladder_px[2] + motif.battleplan.battleplan_zoom_offsety
						v.pos[2] = ((v.default_pos[2] - angle_y) / v.default_pos[3]) * v.pos[3] + angle_y
					else
						-- Move other ladders out of the way
						if v.pos[1] < x then
							v.pos[1] = v.pos[1] - motif.battleplan.battleplan_center_vel
						elseif v.pos[1] > x then
							v.pos[1] = v.pos[1] + motif.battleplan.battleplan_center_vel
						end
					end
					battleplan.f_updateLadderPos(k)
				end
			-- THIRD PHASE: Scroll selected ladder
			else
				battleplan.ladderData[battleplan.ladder].pos[3] = 0
				if y > motif.info.localcoord[2] then
					battleplan.ladderData[battleplan.ladder].pos[2] = battleplan.ladderData[battleplan.ladder].pos[2] - motif.battleplan.battleplan_scroll_vel 
				else
					battleplan.ladderData[battleplan.ladder].pos[2] = motif.info.localcoord[2]
					if battleplan.fadeout == false then
						main.f_fadeReset('fadeout', motif.battleplan)
						battleplan.fadeout = true
					end
				end
				battleplan.f_updateLadderPos(battleplan.ladder)
			end
		end
		-- Draw battleplan items
		battleplan.f_drawBattleplan()
	end
end

function battleplan.f_selectLadder()
	if battleplan.timerSelect == -1 or main.f_input(main.t_players, {'pal', 's'}) then
		battleplan.ladderSelected = true
		return
	elseif main.f_input(main.t_players, {'$B'}) then
		sndPlay(motif.files.snd_data, motif.battleplan.battleplan_move_snd[1], motif.battleplan.battleplan_move_snd[2])
		battleplan.ladder = battleplan.ladder - 1
		if battleplan.ladder < 1 then battleplan.ladder = #battleplan.ladderData end
	elseif main.f_input(main.t_players, {'$F'}) then
		sndPlay(motif.files.snd_data, motif.battleplan.battleplan_move_snd[1], motif.battleplan.battleplan_move_snd[2])
		battleplan.ladder = battleplan.ladder + 1
		if battleplan.ladder > #battleplan.ladderData then battleplan.ladder = 1 end
	end
end

function battleplan.f_updateLadderPos(l)
	local x = battleplan.ladderData[l].pos[1]
	local y = battleplan.ladderData[l].pos[2]
	local z = battleplan.ladderData[l].pos[3]
	-- Set anims' scale and pos 
	z = zScaleMul(z) -- Convert z to scale mul
	animSetScale(battleplan.ladderData[l].base_data, z, z)
	animSetPos(battleplan.ladderData[l].base_data, x, y)
	for i, a in ipairs(battleplan.ladderData[l].bracket_data) do
		animSetScale(a, z, z)
		animSetPos(a, x, y - battleplan.ladderData[l].base_px[2] * z - battleplan.ladderData[l].bracket_px[2] * z * (i - 1))
	end
end

function battleplan.f_resetLaddersPos()
	for k, v in ipairs(battleplan.ladderData) do
		v.pos[1] = v.default_pos[1]
		v.pos[2] = v.default_pos[2]
		v.pos[3] = v.default_pos[3]
		battleplan.f_updateLadderPos(k)
	end
end

-- --------------------------------
-- BATTLEPLAN DRAWING
-- --------------------------------

function battleplan.f_drawBattleplan()
	--draw clearcolor
	clearColor(motif.battleplanbgdef.bgclearcolor[1], motif.battleplanbgdef.bgclearcolor[2], motif.battleplanbgdef.bgclearcolor[3])
	-- draw layerno = 0 backgrounds
	bgDraw(motif.battleplanbgdef.bg, false)
	-- draw ladders
	battleplan.f_drawLadders()
	if not battleplan.ladderSelected then
		-- draw ladder bg
		animDraw(battleplan.ladderData[battleplan.ladder].bg_data)
		animUpdate(battleplan.ladderData[battleplan.ladder].bg_data)
		-- draw ladder name
		battleplan.ladderData[battleplan.ladder]['font_data']:draw()
	end
	-- draw title
	main.txt_battleplan:draw()
	-- hook
	hook.run("f_drawBattleplan")
	-- draw layerno = 1 backgrounds
	bgDraw(motif.battleplanbgdef.bg, true)
	-- draw fadein / fadeout
	main.f_fadeAnim(motif.battleplan)
	-- frame transition
	if not main.f_frameChange() then
		battleplan.finished = true
		return --skip last frame rendering
	end
	main.f_refresh()
end

function battleplan.f_drawLadders()
	for _, v in ipairs(battleplan.ladderData) do
		-- Draw ladder base
		animDraw(v.base_data)
		animUpdate(v.base_data)
		-- Draw ladder brackets
		for _, a in ipairs(v.bracket_data) do
			animDraw(a)
			animUpdate(a)
		end
	end
end

-- --------------------------------
-- INITIALIZE CODE
-- --------------------------------

-- Function: Creates spr data. Based on motif.f_loadSprData()
local anim = ''
local facing = ''
local function f_createSprData(t, v)
	local sprData = {}
	local animParam = v.s .. 'anim'
	local sprParam = v.s .. 'spr'
	local data = v.s .. 'data'
	-- optional prefix argument only changes parameter name for anim/spr numbers assignment
	if v.prefix ~= nil then
		animParam = v.s .. v.prefix .. 'anim'
		sprParam = v.s .. v.prefix .. 'spr'
		data = v.s .. v.prefix .. 'data'
	end
	if t[v.s .. 'offset'] == nil then t[v.s .. 'offset'] = {0, 0} end
	if t[v.s .. 'scale'] == nil then t[v.s .. 'scale'] = {1.0, 1.0} end
	if t[animParam] ~= nil and t[animParam] ~= -1 and motif.anim[t[animParam]] ~= nil then --create animation data
		if t[v.s .. 'facing'] == nil then t[v.s .. 'facing'] = 1 end
		sprData = main.f_animFromTable(
			motif.anim[t[animParam]],
			motif.files.spr_data,
			t[v.s .. 'offset'][1] + (v.x or 0),
			t[v.s .. 'offset'][2] + (v.y or 0),
			t[v.s .. 'scale'][1],
			t[v.s .. 'scale'][2],
			motif.f_animFacing(t[v.s .. 'facing'])
		)
	elseif t[sprParam] ~= nil and #t[sprParam] > 0 then --create sprite data
		if #t[sprParam] == 1 then --fix values
			if type(t[sprParam][1]) == 'string' then
				t[sprParam] = {tonumber(t[sprParam][1]:match('^([0-9]+)')), 0}
			else
				t[sprParam] = {t[sprParam][1], 0}
			end
		end
		if t[v.s .. 'facing'] == -1 then facing = ', H' else facing = '' end
		sprData = animNew(motif.files.spr_data, t[sprParam][1] .. ', ' .. t[sprParam][2] .. ', ' .. t[v.s .. 'offset'][1] + (v.x or 0) .. ', ' .. t[v.s .. 'offset'][2] + (v.y or 0) .. ', -1' .. facing)
		animSetScale(sprData, t[v.s .. 'scale'][1], t[v.s .. 'scale'][2])
		animUpdate(sprData)
	else --create dummy data
		sprData = animNew(motif.files.spr_data, '-1,0, 0,0, -1')
		animUpdate(sprData)
	end
	animSetWindow(sprData, 0, 0, motif.info.localcoord[1], motif.info.localcoord[2])
	return sprData
end

-- TODO: Rewrite this function after 0.99 releases
function battleplan.f_setBaseBattleplanInfo()
	-- Default value tables
	local t_bgmDefaultParams = {
		battleplan_bgm = "",
		battleplan_bgm_volume = 100,
		battleplan_bgm_loop = 1,
		battleplan_bgm_loopstart = 0,
		battleplan_bgm_loopend = 0
	}
	local t_battleplanDefaultParams = {
		fadein_time = 10,
		fadein_col = {0, 0, 0},
		fadein_anim = -1,
		fadeout_time = 10,
		fadeout_col = {0, 0, 0},
		fadeout_anim = -1,
		title_text = "Choose Your Destiny",
		title_font = {0, 0, 0, 0, 0, 0, 0},
		title_offset = {0, 0},
		title_scale = {1.0, 1.0},
		ladders = 1,
		startladder = 1,
		battleplan_timer = 240,
		battleplan_move_snd = {100,0},
		battleplan_center_vel = 1.5,
		battleplan_zoom_vel = 0.1,
		battleplan_scroll_vel = 3
	}
	
	-- Set default values in motif table
	for k, v in pairs(t_bgmDefaultParams) do
		if motif.music[k] == nil then
			motif.music[k] = v
		elseif k ~= 'battleplan_bgm' then
			motif.music[k] = tonumber(motif.music[k])
		end
	end
	for k, v in pairs(t_battleplanDefaultParams) do
		if motif.battleplan[k] == nil then motif.battleplan[k] = v end
	end
	-- Debug printing
	--if main.debugLog then main.f_printTable(motif, "debug/t_motif.txt") end
end

function battleplan.f_initMotifData()
	-- bgclearcolor
	if motif.battleplanbgdef.bgclearcolor == nil then motif.battleplanbgdef.bgclearcolor = {0, 0, 0} end
	-- Music
	if motif.music.battleplan_bgm ~= "" then
		motif.music.battleplan_bgm = searchFile(motif.music.battleplan_bgm, {motif.fileDir, '', 'data/', 'sound/'})
	end
	-- Fade
	motif.f_loadSprData(motif.battleplan, {s = 'fadein_'})
	motif.f_loadSprData(motif.battleplan, {s = 'fadeout_'})
	-- Title
	main.txt_battleplan = main.f_createTextImg(motif.battleplan, 'title')
	-- Ladders
	battleplan.f_initLadderData()
end

function battleplan.f_initLadderData()
	-- Table with ladder default params
	local t_ladderDefaultParams = {
		size = 5,
		pos = {0, 0, 1.0},
		name_text = "",
		name_font = {0, 0, 0, 0, 0, 0, 0},
		name_offset = {0, 0},
		name_scale = {1.0, 1.0},
		bg_anim = -1,
		bg_spr = {},
		bg_offset = {0, 0},
		bg_facing = 1,
		bg_scale = {1.0, 1.0},
		base_anim = -1,
		base_spr = {},
		base_offset = {0, 0},
		base_facing = 1,
		base_scale = {1.0, 1.0},
		bracket_anim = -1,
		bracket_spr = {},
		bracket_offset = {0, 0},
		bracket_facing = 1,
		bracket_scale = {1.0, 1.0}
	}
	
	for i = 1, motif.battleplan.ladders do
		local l = 'ladder' .. i
		-- Create temp ladder
		for k, v in pairs(t_ladderDefaultParams) do
			if motif.battleplan[l .. '_' .. k] ~= nil then
				if type(v) == "table" and type(motif.battleplan[l .. '_' .. k]) == "table" then
					for k2, v2 in ipairs(motif.battleplan[l .. '_' .. k]) do
						if v2 == nil then
							motif.battleplan[l .. '_' .. k][k2] = v[k2]
						end
					end
				end
			else
				motif.battleplan[l .. '_' .. k] = v
			end
		end
		-- Add ladder info to ladderData table
		table.insert(battleplan.ladderData, {
			name = motif.battleplan[l .. '_' .. 'name_text'],
			size = motif.battleplan[l .. '_' .. 'size'],
			pos = main.f_tableCopy(motif.battleplan[l .. '_' .. 'pos']),
			default_pos = main.f_tableCopy(motif.battleplan[l .. '_' .. 'pos']),
			base_px = {},
			bracket_px = {},
			ladder_px = {},
			base_data = f_createSprData(motif.battleplan, {s = l .. '_' .. 'base_'}),
			bracket_data = {},
			font_data = main.f_createTextImg(motif.battleplan, l .. '_' .. 'name'),
			bg_data = f_createSprData(motif.battleplan, {s = l .. '_' .. 'bg_'})
		})
		-- Add brackets data to ladderData table
		for j = 1, battleplan.ladderData[i].size do
			table.insert(battleplan.ladderData[i].bracket_data, f_createSprData(motif.battleplan, {s = l .. '_' .. 'bracket_'}))
		end
		-- Init various data
		local baseInfo = animGetSpriteInfo(battleplan.ladderData[i].base_data)
		local bracketInfo = animGetSpriteInfo(battleplan.ladderData[i].bracket_data[1])
		battleplan.ladderData[i].base_px = {baseInfo.Size[1], baseInfo.Size[2]}
		battleplan.ladderData[i].bracket_px = {bracketInfo.Size[1], bracketInfo.Size[2]}
		battleplan.ladderData[i].ladder_px = {math.max(baseInfo.Size[1], bracketInfo.Size[1]), baseInfo.Size[2] + (bracketInfo.Size[2] * battleplan.ladderData[i].size)}
		battleplan.f_updateLadderPos(i)
	end
	-- Debug printing
	if main.debugLog then main.f_printTable(battleplan.ladderData, "debug/t_ladderdata.txt") end
end

local function f_resetBattleplan()
	battleplan.ladder = -1
	battleplan.ladder = motif.battleplan.startladder
	battleplan.timerSelect = motif.battleplan.battleplan_timer
	battleplan.ladderSelected = false
end

hook.add("start.f_selectScreen", "resetBattleplan", f_resetBattleplan)

