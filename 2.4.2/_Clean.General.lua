--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.General.lua - General or minor modifications to the UI.             *
  *                                                                            *
  * + Compresses the time format used for buff icons.                          *
  * + Moves the default tooltip position to the top center of the screen.      *
  * + Uses 24-hour time formats wherever possible.                             *
  * + Shrinks the player's buff frames.                                        *
  ****************************************************************************]]


local _Clean = _Clean;
local L = _CleanLocalization;
local me = {};
_Clean.General = me;

local ProcessedIcons = {};
me.ProcessedIcons = ProcessedIcons;


local _G = getfenv( 0 );




--[[****************************************************************************
  * Function: _Clean.General.SecondsToTimeAbbrev                               *
  * Description: This is used to format buff duration times.                   *
  ****************************************************************************]]
function me.SecondsToTimeAbbrev ( Seconds )
	return L.SECONDSTOTIMEABBREV_FORMAT:format( Seconds / 60, mod( Seconds, 60 ) );
end
--[[****************************************************************************
  * Function: _Clean.General.SecondsToTime                                     *
  * Description: This is used to format times.                                 *
  ****************************************************************************]]
do
	local mod = mod;
	function me.SecondsToTime ( Seconds, NoSeconds )
		local TimeString = L.SECONDSTOTIME_FORMAT:format(
			mod( Seconds / 3600, 24 ),
			mod( Seconds / 60, 60 ),
			mod( Seconds, 60 ) );

		return Seconds >= 86400
			and L.SECONDSTOTIME_DAYS_FORMAT:format( Seconds / 86400, TimeString )
			or TimeString;
	end
end


--[[****************************************************************************
  * Function: _Clean.General.GameTooltipSetDefaultAnchor                       *
  * Description: Moves the default tooltip position to the top center.         *
  ****************************************************************************]]
function me:GameTooltipSetDefaultAnchor ( Parent )
	_Clean.ClearAllPoints( self );
	_Clean.SetPoint( self, "TOP", UIParent, 0, -2 );
end
--[[****************************************************************************
  * Function: _Clean.General.BuffButtonUpdate                                  *
  * Description: Hides the icon's border if not already hidden.                *
  ****************************************************************************]]
function me.BuffButtonUpdate ( Prefix, Index )
	local Icon = _G[ Prefix..Index.."Icon" ];
	if ( Icon and not ProcessedIcons[ Icon ] ) then
		ProcessedIcons[ Icon ] = true;
		_Clean.RemoveButtonIconBorder( Icon );
	end
end


--[[****************************************************************************
  * Function: _Clean.General.PetBarManager                                     *
  * Description: Manages the pet bar's position.                               *
  ****************************************************************************]]
function me.PetBarManager ()
	if ( PetActionBarFrame:IsShown() ) then
		_Clean.ClearAllPoints( PetActionBarFrame );
		_Clean.SetPoint( PetActionBarFrame, "CENTER", UIParent );
		_Clean.SetPoint( PetActionBarFrame, "BOTTOM", ChatFrame1, "TOP" );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	PossessBarFrame:ClearAllPoints();
	PossessBarFrame:SetPoint( "BOTTOMLEFT", MultiBarBottomLeftButton1, "TOPLEFT" );

	-- Fix the small number font to use antialiasing
	local Path, Height, Flags = NumberFontNormalSmall:GetFont();
	Flags = Flags:gsub( ", ([A-Z]+)", { [ "MONOCHROME" ] = ""; [ "THICKOUTLINE" ] = ""; } );
	NumberFontNormalSmall:SetFont( Path, Height, Flags );


	-- Shrink the buff buttons and remove their borders
	BuffFrame:SetScale( 0.85 );
	TemporaryEnchantFrame:SetScale( 0.85 );
	hooksecurefunc( "BuffButton_Update", me.BuffButtonUpdate );

	-- Move and shrink the GM ticket frame
	TicketStatusFrame:ClearAllPoints();
	TicketStatusFrame:SetPoint( "TOPRIGHT", Minimap, "TOPLEFT", -8, 0 );
	TicketStatusFrame:SetScale( 0.85 );
	TicketStatusFrame:SetAlpha( 0.75 );

	-- Hooks
	SecondsToTimeAbbrev = me.SecondsToTimeAbbrev;
	SecondsToTime = me.SecondsToTime;

	UIPARENT_MANAGED_FRAME_POSITIONS[ "PossessBarFrame" ] = nil;
	_Clean.AddPositionManager( me.PetBarManager );
	hooksecurefunc( "GameTooltip_SetDefaultAnchor", me.GameTooltipSetDefaultAnchor );
end
