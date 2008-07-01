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
function me.CaptureBarManager ()
	local LastBar = WorldStateAlwaysUpFrame;
	for Index = 1, NUM_EXTENDED_UI_FRAMES do
		local Bar = _G[ "WorldStateCaptureBar"..Index ];
		if ( Bar and Bar:IsShown() ) then
			Bar:SetAlpha( 0.5 );
			_Clean.RunProtectedMethod( Bar, "EnableMouse", false );
			_Clean.ClearAllPoints( Bar );
			_Clean.SetPoint( Bar, "TOP", LastBar, "BOTTOM", 0, Index == 1 and 12 or 6 );
			LastBar = Bar;
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.WorldStateFrame.AlwaysUpFrameUpdate                       *
  * Description: Disables mouse input for objectives and positions them.       *
  ****************************************************************************]]
function me.AlwaysUpFrameUpdate ()
	local AlwaysUpShown = 0;
	local LastFrame = WorldStateAlwaysUpFrame;

	for Index = 1, GetNumWorldStateUI() do
		local UIType, State, _, _, _, _, _, ExtendedUI = GetWorldStateUIInfo( Index );
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
			_Clean.RunProtectedMethod( Frame, "EnableMouse", false );
			_Clean.ClearAllPoints( Frame );
			_Clean.SetPoint( Frame, "BOTTOM", LastFrame, "TOP" );
			LastFrame = Frame;
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
	_Clean.AddPositionManager( me.CaptureBarManager );
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", me.AlwaysUpFrameUpdate );
end
