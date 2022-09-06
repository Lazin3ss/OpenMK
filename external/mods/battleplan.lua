-- BATTLEPLAN: Renders MK-like arcade ladders.
-- By OpenMK team.

main.battleplan = false

battleplan = {}
battleplan.ladderData = {}
battleplan.ladderSelected = false
battleplan.cameraFinished = false
battleplan.portraitMoved = false
battleplan.rivalDisplayed = false
battleplan.fadeoutActive = false
battleplan.finished = false
battleplan.waitTime = {}

battleplan.cursor = {data = {}, done_data, pos = {0, 0}}
battleplan.ladder = -1
battleplan.timerSelect = -1
battleplan.wins = 0
local max_z = 1000

-- --------------------------------
-- GENERAL FUNCTIONS
-- --------------------------------

function battleplan.f_setCursorPos(x, y)
	battleplan.cursor.pos[1] = x
	battleplan.cursor.pos[2] = y
	animSetPos(battleplan.cursor.data, battleplan.cursor.pos[1], battleplan.cursor.pos[2])
	animSetPos(battleplan.cursor.done_data, battleplan.cursor.pos[1], battleplan.cursor.pos[2])
end

-- Function: Creates scale multiplier from given z.
local function zScaleMul(z)
	return 1 - z / max_z
end

function battleplan.f_updateLadderPos(l)
	local x = battleplan.ladderData[l].pos[1]
	local y = battleplan.ladderData[l].pos[2]
	local z = battleplan.ladderData[l].pos[3]
	z = zScaleMul(z) -- Convert z to scale mul
	-- Update ladder base pos
	animSetScale(battleplan.ladderData[l].base_data, z, z)
	animSetPos(battleplan.ladderData[l].base_data, x, y)
	-- Update ladder brackets pos
	for i, a in ipairs(battleplan.ladderData[l].bracket_data) do
		animSetScale(a, z, z)
		animSetPos(a, x, y - battleplan.ladderData[l].base_px[2] * z - battleplan.ladderData[l].bracket_px[2] * z * (i - 1))
	end
	-- Update ladder char cells pos
	for i, c in ipairs(battleplan.ladderData[l].chars) do
		if c.cell_data ~= 0 then
			animSetScale(c.cell_data, battleplan.ladderData[l].cell_scale[1] * z, battleplan.ladderData[l].cell_scale[2] * z)
			animSetPos(c.cell_data, x + (battleplan.ladderData[l].cell_offset[1] * z), y - battleplan.ladderData[l].base_px[2] * z - battleplan.ladderData[l].bracket_px[2] * z * (i - 1) + (battleplan.ladderData[l].cell_offset[2] * z))
		end
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

function battleplan.f_setLadderChar(l, pos, char_ref)
	if char_ref >= 0 and char_ref <= #main.t_selChars - 1 and pos >= 1 and pos <= battleplan.ladderData[l].size then
		-- Clean table data
		if battleplan.ladderData[l].chars[pos] ~= nil and battleplan.ladderData[l].chars[pos].cell_data ~= 0 then
			battleplan.ladderData[l].chars[pos].cell_data = 0 -- Remove memory allocation
		end
		-- Set new data to table
		battleplan.ladderData[l].chars[pos] = {
			name = main.t_selChars[char_ref + 1].name,
			def = main.t_selChars[char_ref + 1].def,
			cell_data = 0,
			cell_offset = {0, 0},
			cell_scale = {1.0, 1.0},
			ref = char_ref
		}
		return true
	end
	return false
end

function battleplan.f_getLadderChar(l, pos)
	if pos >= 1 and pos <= battleplan.ladderData[l].size then
		return battleplan.ladderData[l].chars[pos]
	end
	return nil
end

function battleplan.f_getLadderCharDef(l, pos)
	return battleplan.f_getLadderChar(l, pos).def or nil
end

function battleplan.f_getLadderCharCell(l, pos)
	return battleplan.f_getLadderChar(l, pos).cell_data or 0
end

function battleplan.f_createLadderRoster(l)
	-- This function should set ladders chars via various algorhitms. Steps:
	-- * Set chars declared on select.def
	-- * On missing spots, fill with random chars
	if l == nil then
		-- Do for all ladders
		for l, d in ipairs(battleplan.ladderData) do
			for i = 1, d.size do
				battleplan.f_setLadderChar(l, i, 3)
			end
		end
	else
		-- Just for ladder l
	end
end

function battleplan.f_setLaddersRosterCellData(del)
	for k, v in ipairs(battleplan.ladderData) do
		for k2, v2 in ipairs(v.chars) do
			if del == nil or del == false then
				v2.cell_data = animGetPreloadedData('char', v2.ref, motif.select_info.portrait_spr[1], motif.select_info.portrait_spr[2])
			else
				v2.cell_data = 0
			end
		end
		battleplan.f_updateLadderPos(k)
	end
	if main.debugLog then main.f_printTable(battleplan.ladderData, "debug/t_ladderdata.txt") end
end

-- --------------------------------
-- BATTLEPLAN BEHAVIOR
-- --------------------------------

-- Function: Manages general battleplan behavior.
function battleplan.f_selectBattleplan()
	-- Init battleplan instance
	if not battleplan.ladderSelected then
		battleplan.wins = 0
		battleplan.ladder = motif.battleplan.startladder
		battleplan.timerSelect = motif.battleplan.timer_count
		battleplan.cameraFinished = false
		battleplan.waitTime = {motif.battleplan.cursor_done_wait, motif.battleplan.camera_center_wait, motif.battleplan.camera_zoom_wait, motif.battleplan.rival_wait}
		battleplan.f_createLadderRoster()
		battleplan.f_resetLaddersPos()
	end
	battleplan.f_setLaddersRosterCellData(false)
	battleplan.portraitMoved = false
	battleplan.rivalDisplayed = false
	battleplan.fadeoutActive = false
	battleplan.finished = false
	main.f_fadeReset('fadein', motif.battleplan)
	main.f_playBGM(false, motif.music.battleplan_bgm, motif.music.battleplan_bgm_loop, motif.music.battleplan_bgm_volume, motif.music.battleplan_bgm_loopstart, motif.music.battleplan_bgm_loopend)
	-- Loop behavior
	while not battleplan.finished do
		-- ladder select behavior 
		if not battleplan.ladderSelected then
			battleplan.f_selectLadder()
		-- ladder camera behavior after selecting ladder
		elseif battleplan.waitTime[1] > 0 then
			battleplan.waitTime[1] =  battleplan.waitTime[1] - 1
		elseif not battleplan.cameraFinished then
			battleplan.f_updateCameraAnim()
		-- showcase next rival
		elseif not battleplan.rivalDisplayed then
			battleplan.f_rivalDisplay()
		elseif not battleplan.fadeoutActive then
			main.f_fadeReset('fadeout', motif.battleplan)
			battleplan.fadeoutActive = true
		end
		-- Draw battleplan items
		battleplan.f_drawBattleplan()
	end
	battleplan.f_setLaddersRosterCellData(true)
end

function battleplan.f_selectLadder()
	if #battleplan.ladderData == 1 or battleplan.timerSelect == -1 or main.f_input(main.t_players, {'pal', 's'}) then
		if #battleplan.ladderData > 1 then
			sndPlay(motif.files.snd_data, motif.battleplan.cursor_done_snd[1], motif.battleplan.cursor_done_snd[2])
		end
		battleplan.ladderSelected = true
	elseif main.f_input(main.t_players, {'$B'}) then
		sndPlay(motif.files.snd_data, motif.battleplan.cursor_move_snd[1], motif.battleplan.cursor_move_snd[2])
		battleplan.ladder = battleplan.ladder - 1
		if battleplan.ladder < 1 then battleplan.ladder = #battleplan.ladderData end
	elseif main.f_input(main.t_players, {'$F'}) then
		sndPlay(motif.files.snd_data, motif.battleplan.cursor_move_snd[1], motif.battleplan.cursor_move_snd[2])
		battleplan.ladder = battleplan.ladder + 1
		if battleplan.ladder > #battleplan.ladderData then battleplan.ladder = 1 end
	end
	battleplan.f_setCursorPos(battleplan.ladderData[battleplan.ladder].pos[1], battleplan.ladderData[battleplan.ladder].pos[2])
end

function battleplan.f_updateCameraAnim()
	-- Get current frame pos values for selected ladder
	local x = battleplan.ladderData[battleplan.ladder].pos[1]
	local y = battleplan.ladderData[battleplan.ladder].pos[2]
	local z = battleplan.ladderData[battleplan.ladder].pos[3]
	-- FIRST PHASE: Center selected ladder on the screen
	if x ~= motif.info.localcoord[1] / 2 then
		for k, v in ipairs(battleplan.ladderData) do
			if math.abs(motif.info.localcoord[1] / 2 - x) < motif.battleplan.camera_center_vel then
				v.pos[1] = v.pos[1] + motif.info.localcoord[1] / 2 - x
			elseif x > motif.info.localcoord[1] / 2 then
				v.pos[1] = v.pos[1] - motif.battleplan.camera_center_vel
			elseif x < motif.info.localcoord[1] / 2 then
				v.pos[1] = v.pos[1] + motif.battleplan.camera_center_vel
			end
			battleplan.f_updateLadderPos(k)
		end
	elseif battleplan.waitTime[2] > 0 then
		 battleplan.waitTime[2] =  battleplan.waitTime[2] - 1
	-- SECOND PHASE: Zoom selected ladder
	elseif z > 0 then
		for k, v in ipairs(battleplan.ladderData) do
			v.pos[3] = math.max(v.pos[3] - motif.battleplan.camera_zoom_vel, 0)
			local angle_y = battleplan.ladderData[battleplan.ladder].ladder_px[2] + motif.battleplan.camera_zoom_offsety
			v.pos[2] = ((v.default_pos[2] - angle_y) / v.default_pos[3]) * v.pos[3] + angle_y
			-- Move other ladders out of the way
			if k ~= battleplan.ladder then
				-- NOTE: Hacky way to calculate new pos x from zoom. I don't really understand projection perspective yet, so this will be changed in the future.
				-- local add_x = (math.abs(battleplan.ladderData[battleplan.ladder].default_pos[1] - v.default_pos[1]) * 1.25) / (5 / (motif.battleplan.camera_zoom_vel / 50))
				local add_x = (1.25 * math.abs(battleplan.ladderData[battleplan.ladder].default_pos[1] - v.default_pos[1]) * motif.battleplan.camera_zoom_vel) / 250
				if v.pos[1] < x then
					v.pos[1] = v.pos[1] - add_x
				elseif v.pos[1] > x then
					v.pos[1] = v.pos[1] + add_x
				end
			end
			battleplan.f_updateLadderPos(k)
		end
	elseif battleplan.waitTime[3] > 0 then
		battleplan.waitTime[3] =  battleplan.waitTime[3] - 1
	-- THIRD PHASE: Scroll selected ladder
	elseif not main.f_input(main.t_players, {'pal'}) and y > motif.info.localcoord[2] then
		for k, v in ipairs(battleplan.ladderData) do
			v.pos[2] = math.max(v.pos[2] - motif.battleplan.camera_scroll_vel, motif.info.localcoord[2])
			battleplan.f_updateLadderPos(k)
		end
	-- Camera movement finished
	else
		battleplan.cameraFinished = true
	end
end

function battleplan.f_rivalDisplay()
	-- Scroll p1 portrait
	if not battleplan.portraitMoved then
		-- Play fight sound
		if motif.battleplan.rival_snd ~= nil then
			main.f_playBGM(true) -- Stop battleplan BGM
			sndPlay(motif.files.snd_data, motif.battleplan.rival_snd[1], motif.battleplan.rival_snd[2])
		end
		battleplan.portraitMoved = true
	-- Finish rival display
	elseif battleplan.waitTime[4] > 0 then
		battleplan.waitTime[4] =  battleplan.waitTime[4] - 1
	else
		battleplan.rivalDisplayed = true
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
		--animDraw(battleplan.ladderData[battleplan.ladder].bg_data)
		--animUpdate(battleplan.ladderData[battleplan.ladder].bg_data)
		-- draw cursor
		animDraw(battleplan.cursor.data)
		animUpdate(battleplan.cursor.data)
		-- draw ladder name
		battleplan.ladderData[battleplan.ladder]['font_data']:draw()
	elseif battleplan.waitTime[1] > 0 then
		animDraw(battleplan.cursor.done_data)
		animUpdate(battleplan.cursor.done_data)
	end
	-- draw title
	main.txt_battleplan:draw()
	-- hook
	hook.run("battleplan.f_drawBattleplan")
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
	for k, l in ipairs(battleplan.ladderData) do
		-- Draw ladder base
		animDraw(l.base_data)
		animUpdate(l.base_data)
		-- Draw ladder brackets
		for n, a in ipairs(l.bracket_data) do
			-- Draw bracket
			animDraw(a)
			animUpdate(a)
			-- Draw bracket cell
			local cell_data = battleplan.f_getLadderCharCell(k, n)
			if cell_data ~= 0 then
				animDraw(cell_data)
				animUpdate(cell_data)
			end
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
		timer_count = 240,
		cursor_spr = {},
		cursor_anim = -1,
		cursor_facing = 1,
		cursor_scale = {1.0, 1.0},
		cursor_offset = {0, 0},
		cursor_move_snd = {100,0},
		cursor_done_snd = {100,0},
		cursor_done_spr = {},
		cursor_done_anim = -1,
		cursor_done_facing = 1,
		cursor_done_scale = {1.0, 1.0},
		cursor_done_offset = {0, 0},
		camera_center_vel = 1.5,
		camera_center_wait = 60,
		camera_zoom_vel = 0.1,
		camera_zoom_wait = 30,
		camera_zoom_curve = 0.1,
		camera_zoom_offsety = 0,
		camera_scroll_vel = 3,
		camera_scroll_offsety = 0
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
	-- Cursor
	battleplan.cursor.data = f_createSprData(motif.battleplan, {s = 'cursor_'})
	battleplan.cursor.done_data = f_createSprData(motif.battleplan, {s = 'cursor_done_'})
	-- Camera Wait Time
	battleplan.waitTime = {motif.battleplan.cursor_done_wait, motif.battleplan.camera_center_wait, motif.battleplan.camera_zoom_wait, motif.battleplan.rival_wait}
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
		base_anim = -1,
		base_spr = {},
		base_offset = {0, 0},
		base_facing = 1,
		base_scale = {1.0, 1.0},
		bracket_anim = -1,
		bracket_spr = {},
		bracket_offset = {0, 0},
		bracket_facing = 1,
		bracket_scale = {1.0, 1.0},
		portrait_scale = {1.0, 1.0},
		portrait_offset = {20, 20}
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
			chars = {},
			base_px = {},
			bracket_px = {},
			ladder_px = {},
			base_data = f_createSprData(motif.battleplan, {s = l .. '_' .. 'base_'}),
			bracket_data = {},
			font_data = main.f_createTextImg(motif.battleplan, l .. '_' .. 'name'),
			cell_offset = motif.battleplan[l .. '_' .. 'portrait_offset'],
			cell_scale = motif.battleplan[l .. '_' .. 'portrait_scale']
		})
		-- Add brackets data to ladderData table
		for j = 1, battleplan.ladderData[i].size do
			table.insert(battleplan.ladderData[i].bracket_data, f_createSprData(motif.battleplan, {s = l .. '_' .. 'bracket_'}))
		end
		-- Init various spr-related data
		local baseInfo = animGetSpriteInfo(battleplan.ladderData[i].base_data)
		local bracketInfo = animGetSpriteInfo(battleplan.ladderData[i].bracket_data[1])
		battleplan.ladderData[i].base_px = {baseInfo.Size[1], baseInfo.Size[2]}
		battleplan.ladderData[i].bracket_px = {bracketInfo.Size[1], bracketInfo.Size[2]}
		battleplan.ladderData[i].ladder_px = {math.max(baseInfo.Size[1], bracketInfo.Size[1]), baseInfo.Size[2] + (bracketInfo.Size[2] * battleplan.ladderData[i].size)}
	end
	-- Update start ladder
	if motif.battleplan.startladder < 1 then 
		motif.battleplan.startladder = 1 
	elseif motif.battleplan.startladder > #battleplan.ladderData then
		motif.battleplan.startladder = #battleplan.ladderData
	end
	-- Debug printing
	if main.debugLog then main.f_printTable(battleplan.ladderData, "debug/t_ladderdata.txt") end
end

local function f_resetBattleplan()
	battleplan.ladderSelected = false
end

battleplan.f_setBaseBattleplanInfo()
battleplan.f_initMotifData()

hook.add("start.f_selectScreen", "resetBattleplan", f_resetBattleplan)

