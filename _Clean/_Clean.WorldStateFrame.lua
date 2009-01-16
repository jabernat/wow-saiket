--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.WorldStateFrame.lua - Modifies the world PvP objective display.     *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.WorldStateFrame = me;




--[[****************************************************************************
  * Function: _Clean.WorldStateFrame.AlwaysUpFrameUpdate                       *
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Reposition frame
	WorldStateAlwaysUpFrame:SetAlpha( 0.5 );
	WorldStateAlwaysUpFrame:EnableMouse( false );
	WorldStateAlwaysUpFrame:ClearAllPoints();
	WorldStateAlwaysUpFrame:SetPoint( "BOTTOM", _Clean.BottomPane, 0, 6 );
	WorldStateAlwaysUpFrame:SetHeight( 1 );

	-- Hooks
	hooksecurefunc( "UIParent_ManageFramePositions", me.AlwaysUpFrameUpdate );
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", me.AlwaysUpFrameUpdate );
end
