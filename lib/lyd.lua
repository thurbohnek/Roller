-- Lydeffekter (lagt til 2026-10-28). Lydene ligger i lyd/ og lages av
-- Util/grafikk/lag_lyd.py.
--
--     require( "lib.lyd" ).spill( "klikk" )
--
-- Navn: klikk, draape, unge, mal, dod, kjop, gave.
-- "draape" stiger i tone når flere dråper tas like etter hverandre.
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

-- Bakgrunnsmusikken (lyd/musikk.wav, 40 s som går i ring) på kanal 1,
-- lavere enn effektene. Startes fra main.lua, og når lyden slås på.
local MUSIKK_KANAL = 1
local musikk
audio.reserveChannels( 1 )

function M.musikk()
	if not innstillinger.lydPaa() then return end
	if musikk and audio.isChannelActive( MUSIKK_KANAL ) then return end
	if not musikk then
		local ok, snd = pcall( audio.loadStream, "lyd/musikk.wav" )
		if not ok or not snd then return end
		musikk = snd
	end
	audio.setVolume( 0.35, { channel = MUSIKK_KANAL } )
	pcall( audio.play, musikk, { channel = MUSIKK_KANAL, loops = -1 } )
end

return M
