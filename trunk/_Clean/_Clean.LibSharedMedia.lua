--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.LibSharedMedia.lua - Adds resources to the LibSharedMedia addon.    *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, _Clean );
_Clean.LibSharedMedia = me;




--[[****************************************************************************
  * Function: _Clean.LibSharedMedia:OnEvent                                    *
  * Description: Adds new media to LibSharedMedia when it's loaded.            *
  ****************************************************************************]]
function me:OnEvent ()
	local LibSharedMedia = LibStub( "LibSharedMedia-3.0", true );
	if ( LibSharedMedia ) then
		me:UnregisterEvent( "ADDON_LOADED" );
		me:SetScript( "OnEvent", nil );
		me.OnEvent = nil;

		LibSharedMedia:Register( LibSharedMedia.MediaType.FONT, "DejaVu Sans Mono", "Interface\\AddOns\\_Clean\\Skin\\DejaVuSansMono.ttf" );
		LibSharedMedia:Register( LibSharedMedia.MediaType.STATUSBAR, "_Clean", "Interface\\AddOns\\_Clean\\Skin\\Glaze" );

		local Sound = LibSharedMedia.MediaType.SOUND;
		LibSharedMedia:Register( Sound, "Mac Ping", "Interface\\AddOns\\_Clean\\Skin\\ErrorSound.mp3" );
		-- Alert sounds
		LibSharedMedia:Register( Sound, "Blizzard: Space Impact", "sound\\effects\\deathimpacts\\spacedeathuni.wav" );
		LibSharedMedia:Register( Sound, "Blizzard: Whisp", "sound\\event sounds\\wisp\\wispready1.wav" );
		LibSharedMedia:Register( Sound, "Blizzard: Alarm Clock", "sound\\interface\\alarmclockwarning2.wav" );
		LibSharedMedia:Register( Sound, "Blizzard: Glyph Creation", "sound\\interface\\glyph_majorcreate.wav" );
		LibSharedMedia:Register( Sound, "Blizzard: Fanfare", "sound\\interface\\readycheck.wav" );
		LibSharedMedia:Register( Sound, "Blizzard: Boss Emote", "sound\\interface\\raidbosswarning.wav" );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
end
