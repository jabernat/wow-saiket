--[[****************************************************************************
  * _Underscore.Font by Saiket                                                 *
  * _Underscore.Font.lua - Modifies some of the default fonts.                 *
  ****************************************************************************]]


local NS = select( 2, ... );
_Underscore.Font = NS;

NS.Monospace = CreateFont( "_UnderscoreMonospace" );
NS.MonospaceNumber = CreateFont( "_UnderscoreMonospaceNumber" );

local NUMBER_FONT = [[Fonts\ARIALN.TTF]];




--- Applies monospace font to the macro edit box.
_Underscore.RegisterAddOnInitializer( "Blizzard_MacroUI", function ()
	MacroFrameText:SetFontObject( NS.Monospace );
end );
--- Applies monospace font to _Dev's stats display.
_Underscore.RegisterAddOnInitializer( "_Dev", function ()
	_Dev.Font:SetFontObject( NS.MonospaceNumber );
end );


NS.Monospace:SetFont( NUMBER_FONT, 10 );
NS.MonospaceNumber:SetFont( NUMBER_FONT, 8, "OUTLINE" );


-- Fix the small number font to use antialiasing
local Path, Height, Flags = NumberFontNormalSmall:GetFont();
NumberFontNormalSmall:SetFont( Path, Height, Flags:gsub( ", ([A-Z]+)", { [ "MONOCHROME" ] = ""; [ "THICKOUTLINE" ] = ""; } ) );

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