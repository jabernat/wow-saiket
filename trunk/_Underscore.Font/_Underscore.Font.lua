--[[****************************************************************************
  * _Underscore.Font by Saiket                                                 *
  * _Underscore.Font.lua - Modifies some of the default fonts.                 *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local me = {};
_Underscore.Font = me;

me.Monospace = CreateFont( "_UnderscoreMonospace" );
me.MonospaceNumber = CreateFont( "_UnderscoreMonospaceNumber" );

local DejaVuSansMono = [[Interface\AddOns\]]..( ... )..[[\Skin\DejaVuSansMono.ttf]];




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.Monospace:SetFont( DejaVuSansMono, 10, "" );
	me.MonospaceNumber:SetFont( DejaVuSansMono, 8, "OUTLINE" );
	_Underscore.RegisterAddOnInitializer( "Blizzard_MacroUI", function ()
		MacroFrameText:SetFontObject( me.Monospace );
	end );
	_Underscore.RegisterAddOnInitializer( "_Dev", function ()
		_Dev.Font:SetFontObject( me.MonospaceNumber );
	end );

	-- Fix the small number font to use antialiasing
	local Path, Height, Flags = NumberFontNormalSmall:GetFont();
	NumberFontNormalSmall:SetFont( Path, Height,
		Flags:gsub( ", ([A-Z]+)", { [ "MONOCHROME" ] = ""; [ "THICKOUTLINE" ] = ""; } ) );

	-- Change the default font color
	local R, G, B = unpack( _Underscore.Colors.Normal );
	GameFontNormal:SetTextColor( R, G, B );
	GameFontNormalMed3:SetTextColor( R, G, B );
	GameFontNormalSmall:SetTextColor( R, G, B );
	GameFontNormalLarge:SetTextColor( R, G, B );
	GameFontNormalHuge:SetTextColor( R, G, B );
	BossEmoteNormalHuge:SetTextColor( R, G, B );
	NumberFontNormalRightYellow:SetTextColor( R, G, B );
	NumberFontNormalYellow:SetTextColor( R, G, B );
	NumberFontNormalLargeRightYellow:SetTextColor( R, G, B );
	NumberFontNormalLargeYellow:SetTextColor( R, G, B );
	DialogButtonNormalText:SetTextColor( R, G, B );
	CombatTextFont:SetTextColor( R, G, B );
	AchievementPointsFont:SetTextColor( R, G, B );
	AchievementPointsFontSmall:SetTextColor( R, G, B );
	AchievementDateFont:SetTextColor( R, G, B );


	LibSharedMedia:Register( LibSharedMedia.MediaType.FONT, "DejaVu Sans Mono", DejaVuSansMono );
end
