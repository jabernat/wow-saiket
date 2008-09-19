--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.LibSharedMedia.lua - Adds resources to the LibSharedMedia addon.    *
  ****************************************************************************]]


local L;
local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, _Clean );
_Clean.LibSharedMedia = me;




--[[****************************************************************************
  * Function: _Clean.LibSharedMedia:OnEvent                                    *
  * Description: Adds an addon's initializer function to the initializer list. *
  ****************************************************************************]]
function me:OnEvent ()
	local LibSharedMedia = LibStub( "LibSharedMedia-3.0", true );
	if ( LibSharedMedia ) then
		me:UnregisterEvent( "ADDON_LOADED" );
		me:SetScript( "OnEvent", nil );
		me.OnEvent = nil;

		LibSharedMedia:Register( LibSharedMedia.MediaType.FONT, "DejaVu Sans Mono", "Interface\\AddOns\\_Clean\\Skin\\DejaVuSansMono.ttf" );
		LibSharedMedia:Register( LibSharedMedia.MediaType.SOUND, "Mac Ping", "Interface\\AddOns\\_Clean\\Skin\\ErrorSound.mp3" );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
end
