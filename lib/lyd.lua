-- Lydeffekter (lagt til 2026-10-28). Lydene ligger i lyd/ og lages av
-- Util/grafikk/lag_lyd.py.
--
--     require( "lib.lyd" ).spill( "klikk" )
--
-- Navn: klikk, draape, unge, mal, dod, kjop, gave.
-- "draape" (et blad) stiger i tone når flere tas like etter hverandre.
-- Lyden av/på styres av lib/innstillinger.lua (audio.setVolume), men
-- sjekkes også her så ingenting lastes når lyden er av.

local innstillinger = require( "lib.innstillinger" )

local M = {}

local lastet = {}
local sisteDraape, rekke = 0, 0

local function hent( fil )
	if lastet[fil] == nil then
		local ok, snd = pcall( audio.loadSound, "lyd/" .. fil .. ".wav" )
		lastet[fil] = ok and snd or false
	end
	return lastet[fil]
end

function M.spill( navn )
	if not innstillinger.lydPaa() then return end
	local fil = navn
	if navn == "draape" then
		local naa = system.getTimer()
		if naa - sisteDraape < 900 then rekke = math.min( rekke + 1, 5 ) else rekke = 1 end
		sisteDraape = naa
		fil = "draape" .. rekke
	end
	local snd = hent( fil )
	if snd then pcall( audio.play, snd ) end
end

-- Naturlyder i bakgrunnen (ikke musikk): "eng" (vind og fugler) og "hule"
-- (dyp tone og drypp), filene lyd/stemning_*.wav som går i ring. Spilles på
-- kanal 1, lavere enn effektene. Kan slås av for seg (innstillinger.
-- naturPaa), og følger også den vanlige lydknappen.
--     lyd.bakgrunn( "eng" )   -- hjemmet, banevalget, bane 1-2
--     lyd.bakgrunn( "hule" )  -- bane 3-9 og Worm athletics
local KANAL = 1
local lastetStemning = {}
local naa
audio.reserveChannels( 2 )   -- 1 naturlyder, 2 musikk

function M.bakgrunn( navn )
	if navn then naa = navn end
	if not naa then return end
	if not ( innstillinger.lydPaa() and innstillinger.naturPaa() ) then
		audio.stop( KANAL )
		return
	end
	if M.spiller == naa and audio.isChannelActive( KANAL ) then return end
	if lastetStemning[naa] == nil then
		local ok, snd = pcall( audio.loadStream, "lyd/stemning_" .. naa .. ".wav" )
		lastetStemning[naa] = ok and snd or false
	end
	local snd = lastetStemning[naa]
	if not snd then return end
	audio.stop( KANAL )
	-- svakt, så det ligger under musikken
	audio.setVolume( 0.25, { channel = KANAL } )
	pcall( audio.play, snd, { channel = KANAL, loops = -1, fadein = 1200 } )
	M.spiller = naa
end

-- ---------------------------------------------------------- musikk
-- Lydspor på kanal 2 (kilder og lisenser i lyd/musikk/KILDER.txt).
-- Spilleren velger spor i Settings; det valgte sporet går overalt og
-- fortsetter når skjermen byttes. "mix" spiller alle etter hverandre.
local MUSIKK_KANAL = 2
M.SPOR = {
	{ id = "critters", navn = "Curious Critters", av = "Matthew Pablo" },
	{ id = "creek", navn = "Pleasant Creek", av = "Matthew Pablo" },
	{ id = "river", navn = "Down the River", av = "Komiku" },
	{ id = "chill", navn = "Chill Out", av = "Komiku" },
	{ id = "cider", navn = "Apple Cider", av = "Zane Little" },
}
local lastetMusikk = {}
local spiller          -- id på sporet som spilles nå

local function hentMusikk( id )
	if lastetMusikk[id] == nil then
		local ok, snd = pcall( audio.loadStream, "lyd/musikk/" .. id .. ".mp3" )
		lastetMusikk[id] = ok and snd or false
	end
	return lastetMusikk[id]
end

local function spill( id )
	local snd = hentMusikk( id )
	if not snd then return end
	local mix = innstillinger.musikkValg() == "mix"
	audio.stop( MUSIKK_KANAL )
	audio.setVolume( 0.45, { channel = MUSIKK_KANAL } )
	spiller = id
	pcall( audio.play, snd, { channel = MUSIKK_KANAL, fadein = 800, loops = mix and 0 or -1,
		onComplete = function( e )
			-- i mix: neste spor når dette er ferdig (ikke når det ble stoppet)
			if e.completed and spiller == id and innstillinger.musikkValg() == "mix" then
				local nr = 1
				for i, sp in ipairs( M.SPOR ) do if sp.id == id then nr = i end end
				spill( M.SPOR[nr % #M.SPOR + 1].id )
			end
		end } )
end

-- Sørger for at riktig musikk spilles. Kalles fra skjermene (navnet på
-- området brukes ikke lenger, men står igjen så kallene er lesbare).
function M.musikk()
	local valg = innstillinger.musikkValg()
	if not innstillinger.lydPaa() or valg == "av" then
		audio.stop( MUSIKK_KANAL )
		spiller = nil
		return
	end
	if spiller and audio.isChannelActive( MUSIKK_KANAL ) and ( valg == "mix" or valg == spiller ) then
		return
	end
	spill( valg == "mix" and M.SPOR[1].id or valg )
end

-- Kalles når lyd, musikk eller naturlyder slås av eller på.
function M.oppdaterBakgrunn()
	M.spiller = nil
	M.bakgrunn()
	spiller = nil
	M.musikk()
end

return M
