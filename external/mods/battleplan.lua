-- BATTLEPLAN: Renders MK-like arcade ladders.
-- Author: Wreq!

battleplan = {}
battleplan.dataLoaded = false

function battleplan.f_initBattleplanData()
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
	-- Title
	main.txt_battleplan = main.f_createTextImg(motif.battleplan, 'title')
end

function battleplan.f_drawBattleplan()
	if not dataLoaded then
		f_initBattleplanData()
		dataLoaded = true
	end
	main.f_fadeReset('fadein', motif.battleplan)
	main.f_playBGM(false, motif.music.battleplan_bgm, motif.music.battleplan_bgm_loop, motif.music.battleplan_bgm_volume, motif.music.battleplan_bgm_loopstart, motif.music.battleplan_bgm_loopend)
	while true do
		--draw layerno = 0 backgrounds
		bgDraw(motif.battleplanbgdef.bg, false)
		--draw title
		main.txt_battleplan:draw()
		if esc() then
			main.f_fadeReset('fadeout', motif.battleplan)
		end
		-- hook
		hook.run("f_drawBattleplan")
		--draw layerno = 1 backgrounds
		bgDraw(motif.battleplanbgdef.bg, true)
		--draw fadein / fadeout
		main.f_fadeAnim(motif.battleplan)
		--frame transition
		if not main.f_frameChange() then
			break --skip last frame rendering
		end
		main.f_refresh()
	end
end