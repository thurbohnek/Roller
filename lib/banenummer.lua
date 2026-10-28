-- Viser hvilken bane man spiller (lagt til 2026-09-28, ny stil
-- 2026-10-28). Banefilene kaller denne rett etter mørket; selve
-- tegningen ligger nå i lib/hud.lua (banepille øverst til venstre og en
-- stor introtekst som glir bort).
--     require( "lib.banenummer" ).vis( 7 )

local M = {}

function M.vis( bane )
	require( "lib.hud" ).bane( bane )
end

return M
