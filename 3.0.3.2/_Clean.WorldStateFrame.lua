--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.WorldStateFrame.lua - Modifies the world PvP objective display.     *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.WorldStateFrame = me;




--[[****************************************************************************
  * Function: _Clean.WorldStateFrame.CaptureBarManager                         *
  * Description: Moves all capture bars.                                       *
  ****************************************************************************]]
do
	local LastBar;
	function me.CaptureBarManager ()
		LastBar = WorldStateAlwaysUpFrame;
		for Index = 1, NUM_EXTENDED_UI_FRAMES do
			local Bar = _G[ "WorldStateCaptureBar"..Index ];
			if ( Bar and Bar:IsShown() ) then
				Bar:SetAlpha( 0.5 );
				local Target = LastBar;
				_Clean:RunProtectedFunction( function ()
					Bar:EnableMouse( false );
					Bar:ClearAllPoints();
					Bar:SetPoint( "TOP", Target, "BOTTOM", 0, Index == 1 and 12 or 6 );
				end, Bar:IsProtected() );
				LastBar = Bar;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.WorldStateFrame.AlwaysUpFrameUpdate                       *
  * Description: Disables mouse input for objectives and positions them.       *
  ****************************************************************************]]
do
	local AlwaysUpShown, LastFrame, UIType, State, ExtendedUI, _;
	function me.AlwaysUpFrameUpdate ()
		AlwaysUpShown = 0;
		LastFrame = WorldStateAlwaysUpFrame;

		for Index = 1, GetNumWorldStateUI() do
			UIType, State, _, _, _, _, _, ExtendedUI = GetWorldStateUIInfo( Index );
			if (
				( ( UIType ~= 1 )
					or (
						( WORLD_PVP_OBJECTIVES_DISPLAY == "1" )
						or ( WORLD_PVP_OBJECTIVES_DISPLAY == "2" and IsSubZonePVPPOI() )
						or ( select( 2, IsInInstance() ) == "pvp" ) ) )
				and State > 0 -- This bar was updated
				and ExtendedUI == "" -- Always Up
			) then
				AlwaysUpShown = AlwaysUpShown + 1;
				local Frame = _G[ "AlwaysUpFrame"..AlwaysUpShown ];
				local Target = LastFrame;
				_Clean:RunProtectedFunction( function ()
					Frame:EnableMouse( false );
					Frame:ClearAllPoints();
					Frame:SetPoint( "BOTTOM", Target, "TOP" );
				end, Frame:IsProtected() );
				LastFrame = Frame;
			end
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Reposition frame
	WorldStateAlwaysUpFrame:SetAlpha( 0.5 );
	WorldStateAlwaysUpFrame:EnableMouse( false );
	WorldStateAlwaysUpFrame:ClearAllPoints();
	WorldStateAlwaysUpFrame:SetPoint( "CENTER", UIParent );
	WorldStateAlwaysUpFrame:SetPoint( "BOTTOM", ChatFrame1 );
	WorldStateAlwaysUpFrame:SetHeight( 1 );

	-- Hooks
	_Clean:AddPositionManager( me.CaptureBarManager );
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", me.AlwaysUpFrameUpdate );
end
