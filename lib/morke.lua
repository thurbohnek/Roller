-- Mørket i hulen (lagt til 2026-09-28, se SPILLIDE.md).
--
-- Jo lenger ned marken kommer, jo mørkere blir det. Et stort mørkt lag
-- dekker banen, med et mykt lyst felt rundt marken så man ser nærmeste
-- bakke, men ikke langt frem. Bane 1 er utendørs og har ikke mørke.
--
-- Laget ligger nederst i kameraets lag 2, som er skjermfast
-- (parallaxRatio = 0) og ligger foran alle de andre lagene. Da dekker
-- mørket hele banen, mens pauseknappen (også i lag 2) og livtelleren (rett
-- i scenegruppa) ligger over og fortsatt synes.
--
-- Bruk i banefila, etter camera:layer(2):toFront():
--     require( "lib.morke" ).lag( 7, punkt )

local M = {}

-- Hvor tett mørket er i hver bane, 0 = ingen mørke, 1 = helt svart
-- utenfor lyset.
-- Bane 1-2 er på enga (ingen mørke). Grafikken blir selv mørkere nedover
-- (2026-10-28), så mørket er svakere enn før.
M.STYRKE = { 0, 0, 0.08, 0.14, 0.20, 0.26, 0.32, 0.38, 0.44 }

-- morke.png er 1024 bildepunkter og vises 4000 skjermenheter bred, så
-- mørket dekker skjermen (960 x 540) uansett hvor marken er. Lyset er
-- helt klart ut til 170 enheter fra marken og glir over i fullt mørke
-- ved 430 (tegnet inn i bildet).
local STORRELSE = 4000

function M.lag( bane, fokus )
	local styrke = M.STYRKE[bane] or 0
	if styrke <= 0 or not fokus then
		return
	end
	local lag = camera:layer( 2 )
	local morke = display.newImageRect( "morke.png", 1024, 1024 )
	lag:insert( 1, morke )
	morke.alpha = styrke

	local oppdater
	oppdater = function()
		-- Banen er revet ned (morke eller marken fjernet): slutt å oppdatere.
		if not morke.parent or not fokus.parent or not lag.contentToLocal then
			Runtime:removeEventListener( "enterFrame", oppdater )
			return
		end
		local cx, cy = fokus:localToContent( 0, 0 )
		local lx, ly = lag:contentToLocal( cx, cy )
		local ex = lag:contentToLocal( cx + 1000, cy )
		local skala = ( ex - lx ) / 1000
		morke.x, morke.y = lx, ly
		morke.width = STORRELSE * skala
		morke.height = STORRELSE * skala
	end
	Runtime:addEventListener( "enterFrame", oppdater )
	oppdater()
end

return M
