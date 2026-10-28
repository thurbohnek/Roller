-- Teststart for bane 5-9 (2026-09-28).
--
-- Marken må alltid stå i del1 = (0, 0) (flyttes den, blir fysikken NaN,
-- se KODEBASE.md). For å teste slutten av en bane uten å spille gjennom
-- hele, flyttes derfor BANEN i stedet: står det
--     teststart = { x = ..., y = ... },
-- i lib/baneoppsettN.lua, trekkes det fra alle posisjonene, så marken
-- starter der. Skrives av "python3 Util/baner/hule.py N --teststart PX"
-- og fjernes igjen med "--oppsett". Uten teststart er alt uendret.
--
-- Lager en ny tabell, så require-cachen for oppsettet ikke flyttes to
-- ganger når banen startes på nytt.

-- Sjekkpunkt (2026-10-28): kalles med banenummeret, og er et sjekkpunkt
-- nådd (lib/sjekkpunkt.lua), flyttes banen dit på samme måte i stedet.
return function( o, bane )
	local s = o.teststart
	if bane then
		local sj = require( "lib.sjekkpunkt" ).forskyvning( bane )
		if sj.x ~= 0 or sj.y ~= 0 then s = sj end
	end
	if not s then
		return o
	end
	print( "TESTSTART/SJEKKPUNKT: banen er flyttet " .. s.x .. ", " .. s.y )
	local n = { bakgrunn = o.bakgrunn, fliser = {} }
	for i, f in ipairs( o.fliser ) do
		n.fliser[i] = { x = f.x - s.x, y = f.y - s.y }
	end
	n.dod = { x = o.dod.x - s.x, y = o.dod.y - s.y, rotasjon = o.dod.rotasjon }
	n.mal2 = { x = o.mal2.x - s.x, y = o.mal2.y - s.y }
	n.kamera = { x_maks = o.kamera.x_maks - s.x, y_maks = o.kamera.y_maks - s.y }
	return n
end
