--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Indicators.lua - Modifies all situational indicator widgets.        *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.Indicators = me;




--[[****************************************************************************
  * Function: _Clean.Indicators.AlwaysUpFrameUpdate                            *
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
	function me.AlwaysUpFrameUpdate ()
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
  * Function: _Clean.Indicators.UpdateDurabilityFrame                          *
  * Description: Moves the durability frame to the center of the bottom pane.  *
  ****************************************************************************]]
function me.UpdateDurabilityFrame ()
	DurabilityFrame:ClearAllPoints();
	DurabilityFrame:SetPoint( "CENTER", _Clean.BottomPane );
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

	hooksecurefunc( "UIParent_ManageFramePositions", me.AlwaysUpFrameUpdate );
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", me.AlwaysUpFrameUpdate );


	-- Move the durability frame to the middle
	hooksecurefunc( "UIParent_ManageFramePositions", me.UpdateDurabilityFrame );
	me.UpdateDurabilityFrame();
	DurabilityFrame:SetScale( 2.0 );
end
