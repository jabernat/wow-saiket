--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.Flags.lua - Text AFK/DND indicator for the player.         *
  ****************************************************************************]]


local L = _UnderscoreLocalization.HUD;
local me = CreateFrame( "Frame", nil, UIParent );
_Underscore.HUD.Flags = me;

me.Text = me:CreateFontString( nil, "ARTWORK", "GameFontNormalHuge" );




--[[****************************************************************************
  * Function: _Underscore.HUD.Flags:PLAYER_FLAGS_CHANGED                       *
  ****************************************************************************]]
function me:PLAYER_FLAGS_CHANGED ( _, UnitID )
	if ( UnitID == "player" ) then
		local Status;
		if ( UnitIsAFK( "player" ) ) then
			Status = L.FLAG_AFK;
		elseif ( UnitIsDND( "player" ) ) then
			Status = L.FLAG_DND;
		end
		if ( Status ) then
			self.Text:SetText( Status );
			self:Show();
		else
			self:Hide();
		end
	end
end
--[[****************************************************************************
  * Function: _Underscore.HUD.Flags:PLAYER_ENTERING_WORLD                      *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	self:Hide();
end
--[[****************************************************************************
  * Function: _Underscore.HUD.Flags:OnUpdate                                   *
  ****************************************************************************]]
function me:OnUpdate ()
	me:SetScript( "OnUpdate", nil );
	me.OnUpdate = nil;

	self:PLAYER_FLAGS_CHANGED( nil, "player" );
	self:RegisterEvent( "PLAYER_ENTERING_WORLD" );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", _Underscore.OnEvent );
	me:RegisterEvent( "PLAYER_FLAGS_CHANGED" );

	me:SetFrameStrata( "BACKGROUND" );
	me.Text:SetPoint( "BOTTOM", AutoFollowStatusText, "TOP" );
end
