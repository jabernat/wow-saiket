--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.Flags.lua - Text AFK/DND indicator for the player.         *
  ****************************************************************************]]


local me = CreateFrame( "Frame", nil, UIParent );
select( 2, ... ).Flags = me;

me.Text = me:CreateFontString( nil, "ARTWORK", "GameFontNormalHuge" );

me.UpdateRate = 0.25;




do
	local UnitIsAFK = UnitIsAFK;
	local UnitIsDND = UnitIsDND;
	--- Updates AFK/DND state on a timer.
	-- Used instead of PLAYER_FLAGS_CHANGED since it's unreliable in cases such as
	-- zoning or logging in for the first time, and PLAYER_ENTERING_WORLD doesn't
	-- catch those cases either.
	function me:OnUpdate ( Elapsed )
		self.NextUpdate = self.NextUpdate - Elapsed;
		if ( self.NextUpdate <= 0 ) then
			self.NextUpdate = self.UpdateRate;

			self.Text:SetText( ( UnitIsAFK( "player" ) and CHAT_FLAG_AFK )
				or ( UnitIsDND( "player" ) and CHAT_FLAG_DND ) or nil );
		end
	end
end
--- Catches when AFK status gets reset after zoning.
function me:PLAYER_ENTERING_WORLD ()
	self.NextUpdate = 0;
end




me:SetScript( "OnUpdate", me.OnUpdate );
me:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
me:RegisterEvent( "PLAYER_ENTERING_WORLD" );

me:SetFrameStrata( "BACKGROUND" );
me.Text:SetPoint( "BOTTOM", AutoFollowStatusText, "TOP" );