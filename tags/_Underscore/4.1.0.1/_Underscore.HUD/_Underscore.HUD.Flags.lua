--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.Flags.lua - Text AFK/DND indicator for the player.         *
  ****************************************************************************]]


local HUD = select( 2, ... );
local me = CreateFrame( "Frame", nil, UIParent );
HUD.Flags = me;

local UpdateRate = 0.25;




me:SetFrameStrata( "BACKGROUND" );
me.Text = me:CreateFontString( nil, "ARTWORK", "GameFontNormalHuge" );
me.Text:SetPoint( "BOTTOM", AutoFollowStatusText, "TOP" );


local Updater = me:CreateAnimationGroup();

local UnitIsAFK, UnitIsDND = UnitIsAFK, UnitIsDND;
--- Updates AFK/DND state on a timer.
-- Used instead of PLAYER_FLAGS_CHANGED since it's unreliable in cases such as
-- zoning or logging in for the first time, and PLAYER_ENTERING_WORLD doesn't
-- catch those cases either.
function Updater:OnLoop ()
	me.Text:SetText( ( UnitIsAFK( "player" ) and CHAT_FLAG_AFK )
		or ( UnitIsDND( "player" ) and CHAT_FLAG_DND ) or nil );
end

Updater:CreateAnimation( "Animation" ):SetDuration( UpdateRate );
Updater:SetLooping( "REPEAT" );
Updater:SetScript( "OnLoop", Updater.OnLoop );
Updater:Play();