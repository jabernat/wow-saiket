--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Indicators.lua - Modifies all situational indicator widgets.        *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame" );
_Clean.Indicators = me;




--[[****************************************************************************
  * Function: _Clean.Indicators.WorldStateUpdate                               *
  * Description: Disables mouse input for objectives and positions them.       *
  ****************************************************************************]]
do
	local LastFrame;
	local function AddFrame ( self, Scale )
		if ( self and self:IsShown() ) then
			self:ClearAllPoints();
			self:SetPoint( "BOTTOM", LastFrame, "TOP" );
			self:EnableMouse( false );
			self:SetScale( Scale or 1.0 );
			LastFrame = self;
			return true;
		end
	end
	function me.WorldStateUpdate ()
		LastFrame = WorldStateAlwaysUpFrame;
		for Index = 1, NUM_EXTENDED_UI_FRAMES do
			if ( not AddFrame( _G[ "WorldStateCaptureBar"..Index ], 0.8 ) ) then
				break;
			end
		end
		for Index = 1, NUM_ALWAYS_UP_UI_FRAMES do
			if ( not AddFrame( _G[ "AlwaysUpFrame"..Index ] ) ) then
				break;
			end
		end
	end
end


--[[****************************************************************************
  * Function: _Clean.Indicators.DurabilityMove                                 *
  * Description: Moves the durability frame to the center of the bottom pane.  *
  ****************************************************************************]]
function me.DurabilityMove ()
	DurabilityFrame:ClearAllPoints();
	DurabilityFrame:SetPoint( "CENTER", _Clean.BottomPane );
end


--[[****************************************************************************
  * Function: _Clean.Indicators.VehicleMove                                    *
  * Description: Moves the vehicle seating to the center of the bottom pane.   *
  ****************************************************************************]]
function me.VehicleMove ()
	VehicleSeatIndicator:ClearAllPoints();
	VehicleSeatIndicator:SetPoint( "CENTER", _Clean.BottomPane );
end
--[[****************************************************************************
  * Function: _Clean.Indicators.VehicleUpdateSeats                             *
  * Description: Disables unusable seat buttons.                               *
  ****************************************************************************]]
function me.VehicleUpdateSeats ()
	if ( VehicleSeatIndicator.currSkin ) then -- In vehicle
		for Index = 1, UnitVehicleSeatCount( "player" ) do
			local Button = _G[ "VehicleSeatIndicatorButton"..Index ];

			local Type, OccupantName = UnitVehicleSeatInfo( "player", Index );
			Button:EnableMouse( OccupantName ~= UnitName( "player" ) and ( OccupantName or CanSwitchVehicleSeats() ) );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Move capture/worldstate frames
	WorldStateAlwaysUpFrame:SetAlpha( 0.5 );
	WorldStateAlwaysUpFrame:EnableMouse( false );
	WorldStateAlwaysUpFrame:ClearAllPoints();
	WorldStateAlwaysUpFrame:SetPoint( "BOTTOM", _Clean.BottomPane, 0, 6 );
	WorldStateAlwaysUpFrame:SetHeight( 1 );
	WorldStateAlwaysUpFrame:SetFrameStrata( "BACKGROUND" );

	hooksecurefunc( "UIParent_ManageFramePositions", me.WorldStateUpdate );
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", me.WorldStateUpdate );


	-- Move the durability frame to the middle
	hooksecurefunc( "UIParent_ManageFramePositions", me.DurabilityMove );
	me.DurabilityMove();
	DurabilityFrame:SetScale( 2.0 );
	DurabilityFrame:SetFrameStrata( "BACKGROUND" );


	-- Move the vehicle seat indicator to the middle
	hooksecurefunc( "MultiActionBar_Update", me.VehicleMove );
	hooksecurefunc( "VehicleSeatIndicator_Update", me.VehicleUpdateSeats );
	me.VehicleMove();
	VehicleSeatIndicator:SetAlpha( 0.6 );
	VehicleSeatIndicator:SetFrameStrata( "BACKGROUND" );
end
