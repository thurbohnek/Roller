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
-- Lydspor (CC0, se lyd/musikk/KILDER.txt) på kanal 2. Hvert område har en
-- spilleliste som går i ring; hulene veksler mellom to spor.
--     lyd.musikk( "meny" | "eng" | "hule" | "arena" )
local MUSIKK_KANAL = 2
local LISTER = {
	meny = { "meny" },
	eng = { "eng" },
	hule = { "hule1", "hule2" },
	arena = { "arena" },
}
local lastetMusikk = {}
local omraade, spor, nr = nil, nil, 1

local function spillNeste()
	if not ( innstillinger.lydPaa() and innstillinger.musikkPaa() ) or not omraade then return end
	local liste = LISTER[omraade]
	nr = ( nr % #liste ) + 1
	local navn = liste[nr]
	if lastetMusikk[navn] == nil then
		local ok, snd = pcall( audio.loadStream, "lyd/musikk/" .. navn .. ".mp3" )
		lastetMusikk[navn] = ok and snd or false
	end
	local snd = lastetMusikk[navn]
	if not snd then return end
	audio.setVolume( 0.45, { channel = MUSIKK_KANAL } )
	pcall( audio.play, snd, { channel = MUSIKK_KANAL, fadein = 800, onComplete = function( e )
		-- neste spor når dette er ferdig (ikke når det ble stoppet)
		if e.completed and spor == navn then spillNeste() end
	end } )
	spor = navn
end

function M.musikk( navn )
	if navn == omraade and spor and audio.isChannelActive( MUSIKK_KANAL ) then return end
	omraade = navn or omraade
	spor = nil
	audio.stop( MUSIKK_KANAL )
	nr = 0
	if not ( innstillinger.lydPaa() and innstillinger.musikkPaa() ) then return end
	spillNeste()
end

-- Kalles når lyd, musikk eller naturlyder slås av eller på.
function M.oppdaterBakgrunn()
	M.spiller = nil
	M.bakgrunn()
	spor = nil
	M.musikk()
end

return M
