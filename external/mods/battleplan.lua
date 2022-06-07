-- BATTLEPLAN: Renders MK-like arcade ladders.
-- Author: Wreq!

battleplan = {}
battleplan.ladder = -1
battleplan.ladderData = {}
battleplan.ladderSelected = false
battleplan.timerSelect = -1
battleplan.dataLoaded = false

-- --------------------------------
-- GENERAL FUNCTIONS
-- --------------------------------

function battleplan.f_selectBattleplan()
	-- Init motif data in case it wasn't loaded
	if not battleplan.dataLoaded then
		battleplan.f_setBaseBattleplanInfo()
		battleplan.f_loadLadderData()
		battleplan.dataLoaded = true
	end
	-- Init battleplan instance
	if battleplan.ladder == -1 then battleplan.ladder = motif.battleplan.ladders_startladder end
	if battleplan.timerSelect == -1 then battleplan.timerSelect = motif.battleplan.ladders_timer end
	battleplan.ladderSelected = false
	main.f_fadeReset('fadein', motif.battleplan)
	main.f_playBGM(false, motif.music.battleplan_bgm, motif.music.battleplan_bgm_loop, motif.music.battleplan_bgm_volume, motif.music.battleplan_bgm_loopstart, motif.music.battleplan_bgm_loopend)
	
	-- Loop behavior
	while true do
		--draw clearcolor
		clearColor(motif.battleplanbgdef.bgclearcolor[1], motif.battleplanbgdef.bgclearcolor[2], motif.battleplanbgdef.bgclearcolor[3])
		-- draw layerno = 0 backgrounds
		bgDraw(motif.battleplanbgdef.bg, false)
		-- draw ladders
		battleplan.f_drawLadders()
		-- draw ladder bg
		animDraw(motif.battleplan['ladder' .. battleplan.ladder .. '_bg_data'])
		animUpdate(motif.battleplan['ladder' .. battleplan.ladder .. '_bg_data'])
		-- draw ladder name
		battleplan.ladderData[battleplan.ladder]['font_data']:draw()
		-- draw title
		main.txt_battleplan:draw()
		-- ladder select behavior 
		if not battleplan.ladderSelected then
			battleplan.f_selectLadder()
		end
		-- hook
		hook.run("f_drawBattleplan")
		-- draw layerno = 1 backgrounds
		bgDraw(motif.battleplanbgdef.bg, true)
		-- draw fadein / fadeout
		main.f_fadeAnim(motif.battleplan)
		-- frame transition
		if not main.f_frameChange() then
			break --skip last frame rendering
		end
		main.f_refresh()
	end
end

function battleplan.f_selectLadder()
	if battleplan.timerSelect == -1 or main.f_input(main.t_players, {'pal', 's'}) then
		battleplan.ladderSelected = true
		-- TODO: This fade reset should be moved elsewhere
		main.f_fadeReset('fadeout', motif.battleplan)
		return
	elseif main.f_input(main.t_players, {'$B'}) then
		sndPlay(motif.files.snd_data, motif.battleplan.ladders_move_snd[1], motif.battleplan.ladders_move_snd[2])
		battleplan.ladder = battleplan.ladder - 1
		if battleplan.ladder < 1 then battleplan.ladder = #battleplan.ladderData end
	elseif main.f_input(main.t_players, {'$F'}) then
		sndPlay(motif.files.snd_data, motif.battleplan.ladders_move_snd[1], motif.battleplan.ladders_move_snd[2])
		battleplan.ladder = battleplan.ladder + 1
		if battleplan.ladder > #battleplan.ladderData then battleplan.ladder = 1 end
	end
end

function battleplan.f_setLadderPos(l, x, y, z)
	-- Update ladder data pos values
	battleplan.ladderData[l].pos[1] = x
	battleplan.ladderData[l].pos[2] = y
	battleplan.ladderData[l].scale = z
	-- Set anims' scale and pos
	animSetScale(battleplan.ladderData[l].base_data, z, z)
	animSetPos(battleplan.ladderData[l].base_data, x, y)
	for i, a in ipairs(battleplan.ladderData[l].bracket_data) do
		animSetScale(a, z, z)
		animSetPos(a, x, y - battleplan.ladderData[l].base_px[2] * z - battleplan.ladderData[l].bracket_px[2] * z * (i - 1))
	end
	
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
local function f_createSprAnim(group, index, offset, facing)
	return animNew(motif.files.spr_data, group .. ', ' .. index .. ', ' .. offset[1] .. ', ' .. offset[2] .. ', -1' .. facing)
end

-- TODO: Rewrite this function after 0.99 releases
function battleplan.f_setBaseBattleplanInfo()
	-- bgclearcolor
	if motif.battleplanbgdef.bgclearcolor == nil then motif.battleplanbgdef.bgclearcolor = {0, 0, 0} end
	-- Music
	if motif.music.battleplan_bgm ~= nil then
		motif.music.battleplan_bgm = searchFile(motif.music.battleplan_bgm, {motif.fileDir, '', 'data/', 'sound/'})
	else
		motif.music.battleplan_bgm = ""
	end
	if motif.music.battleplan_bgm_loopstart == nil or motif.music.battleplan_bgm_loopstart == "" then motif.music.battleplan_bgm_loopstart = 0 end
	if motif.music.battleplan_bgm_loopend == nil or motif.music.battleplan_bgm_loopend == "" then motif.music.battleplan_bgm_loopend = 0 end
	-- Fade
	motif.f_loadSprData(motif.battleplan, {s = 'fadein_'})
	motif.f_loadSprData(motif.battleplan, {s = 'fadeout_'})
	-- Texts
	for k in pairs(motif.battleplan) do
		if k:find("text") ~= nil then
			s = k:gsub("text", "")
			if motif.battleplan[s .. 'font'] == nil then motif.battleplan[s .. 'font'] = {0, 0, 0, 0, 0, 0, 0} end
			if motif.battleplan[s .. 'offset'] == nil then motif.battleplan[s .. 'offset'] = {0, 0} end
			if motif.battleplan[s .. 'scale'] == nil then motif.battleplan[s .. 'scale'] = {1.0, 1.0} end
		end
	end
	-- Title
	main.txt_battleplan = main.f_createTextImg(motif.battleplan, 'title')
	-- Ladders
	if motif.battleplan.ladders == nil then motif.battleplan.ladders = 3 end
	if motif.battleplan.ladders_timer == nil then motif.battleplan.timer = 240 end
	if motif.battleplan.ladders_startladder == nil then motif.battleplan.startladder = 1 end
	if motif.battleplan.ladders_move_snd == nil then motif.battleplan.ladders_move_snd = {0, 0} end	
	for i = 1, motif.battleplan.ladders do
		local l = 'ladder' .. i
		if motif.battleplan[l .. '_size'] == nil then motif.battleplan[l .. '_size'] = 5 end
		if motif.battleplan[l .. '_pos'] == nil then motif.battleplan[l .. '_pos'] = {0, 0} end
		if motif.battleplan[l .. '_scale'] == nil then motif.battleplan[l .. '_scale'] = {0, 0} end
		motif.f_loadSprData(motif.battleplan, {s = l .. '_bg_'})
		motif.f_loadSprData(motif.battleplan, {s = l .. '_base_'})
		motif.f_loadSprData(motif.battleplan, {s = l .. '_bracket_'})
	end
	-- Debug printing
	--if main.debugLog then main.f_printTable(motif, "debug/t_motif.txt") end
end

function battleplan.f_loadLadderData()
	for i = 1, motif.battleplan.ladders do
		local l = 'ladder' .. i
		local baseInfo = animGetSpriteInfo(motif.battleplan[l .. '_base_data'])
		local bracketInfo = animGetSpriteInfo(motif.battleplan[l .. '_bracket_data'])
		table.insert(battleplan.ladderData, {
			name = motif.battleplan[l .. '_name_text'],
			size = motif.battleplan[l .. '_size'],
			pos = {0, 0},
			scale = 1.0,
			base_px = {baseInfo.Size[1], baseInfo.Size[2]},
			bracket_px = {bracketInfo.Size[1], bracketInfo.Size[2]},
			base_data = motif.battleplan[l .. '_base_data'],
			bracket_data = {},
			font_data = main.f_createTextImg(motif.battleplan, l .. '_name')
		})
		for j = 1, battleplan.ladderData[i].size do
			table.insert(battleplan.ladderData[i].bracket_data, f_createSprAnim(motif.battleplan[l .. '_bracket_spr'][1], motif.battleplan[l .. '_bracket_spr'][2], {0, 0}, 1))
		end
		battleplan.f_setLadderPos(i, motif.battleplan[l .. '_pos'][1], motif.battleplan[l .. '_pos'][2], motif.battleplan[l .. '_scale'][1])
	end
	-- Debug printing
	if main.debugLog then main.f_printTable(battleplan.ladderData, "debug/t_ladderdata.txt") end
end

