--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.Indicators.lua - Modifies situational indicator widgets.   *
  ****************************************************************************]]


local me = {};
select( 2, ... ).Indicators = me;




do
	local LastFrame;
	--- Positions a world state frame just after the last one.
	-- @return True if the frame exists and is in use.
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
	--- Disables mouse input for objectives and repositions them.
	function me.ManageWorldState ()
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


--- Moves the durability frame to the center of the bottom pane.
function me.ManageDurability ()
	DurabilityFrame:ClearAllPoints();
	DurabilityFrame:SetPoint( "CENTER" );
end


do
	local Buttons = {};
	--- Hook to disable unusable seat buttons.
	function me.ManageVehicleSeats ()
		if ( VehicleSeatIndicator.currSkin ) then -- In vehicle
			-- Cache any new buttons
			local Button = _G[ "VehicleSeatIndicatorButton"..( #Buttons + 1 ) ];
			while ( Button ) do
				Buttons[ #Buttons + 1 ] = Button;
				Button = _G[ "VehicleSeatIndicatorButton"..( #Buttons + 1 ) ];
			end

			-- Only mouse-enable usefull buttons
			for Index, Button in ipairs( Buttons ) do
				if ( Button:IsShown() ) then
					local Type, OccupantName = UnitVehicleSeatInfo( "player", Index );
					Button:EnableMouse( OccupantName ~= UnitName( "player" ) and ( OccupantName or CanSwitchVehicleSeats() ) );
				end
			end
		end
	end
end
do
	local SetPoint = VehicleSeatIndicator.SetPoint;
	--- Hook to move the vehicle seating to the center of the bottom pane.
	function me.ManageVehicle ()
		VehicleSeatIndicator:ClearAllPoints();
		SetPoint( VehicleSeatIndicator, "CENTER" );
	end
end




-- Move capture/worldstate frames
WorldStateAlwaysUpFrame:SetParent( _Underscore.BottomPane );
WorldStateAlwaysUpFrame:ClearAllPoints();
WorldStateAlwaysUpFrame:SetPoint( "BOTTOM", 0, 6 );
WorldStateAlwaysUpFrame:SetHeight( 1 );
WorldStateAlwaysUpFrame:EnableMouse( false );
WorldStateAlwaysUpFrame:SetAlpha( 0.5 );
hooksecurefunc( "WorldStateAlwaysUpFrame_Update", me.ManageWorldState );
_Underscore.RegisterPositionManager( me.ManageWorldState );


-- Move the durability frame to the middle
DurabilityFrame:SetParent( _Underscore.BottomPane );
DurabilityFrame:SetScale( 2.0 );
DurabilityFrame:SetAlpha( 0.75 );
me.ManageDurability();
_Underscore.RegisterPositionManager( me.ManageDurability );


-- Move the vehicle seat indicator to the middle
VehicleSeatIndicator:SetParent( _Underscore.BottomPane );
VehicleSeatIndicator:SetAlpha( 0.6 );
hooksecurefunc( "VehicleSeatIndicator_Update", me.ManageVehicleSeats );
hooksecurefunc( VehicleSeatIndicator, "SetPoint", me.ManageVehicle );
me.ManageVehicle();