--[[****************************************************************************
  * _Clean.Units by Saiket                                                     *
  * _Clean.Units.Grid.lua - Modifies the Grid addon.                           *
  ****************************************************************************]]


local L = _CleanLocalization.Units;
local _Clean = _Clean;
if ( not IsAddOnLoaded( "Grid" ) ) then
	return;
end
local me = {};
_Clean.Units.Grid = me;




--[[****************************************************************************
  * Function: _Clean.Units.Grid:FrameInitialize                                *
  * Description: Hook to modify new GridFrames.                                *
  ****************************************************************************]]
function me:FrameInitialize ()
	self.menu = _Clean.Units.ShowGenericMenu;
	_Clean.Backdrop.Add( self, -2 );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Hook Grid frame creation
	hooksecurefunc( GridFrame, "InitialConfigFunction", me.FrameInitialize );

	-- Add hook to all existing frames
	GridFrame:WithAllFrames( function ( self ) me.FrameInitialize( self.frame ); end );

	-- Add better layouts that include pets from all classes
	local PetGroup = { isPetGroup = true; unitsPerColumn = 10; maxColumns = 4; };
	GridLayout:AddLayout( L.GRID_LAYOUT_CLASS, {
		PetGroup,
		{ groupFilter = "WARRIOR"; },
		{ groupFilter = "PRIEST"; },
		{ groupFilter = "DRUID"; },
		{ groupFilter = "PALADIN"; },
		{ groupFilter = "SHAMAN"; },
		{ groupFilter = "MAGE"; },
		{ groupFilter = "WARLOCK"; },
		{ groupFilter = "HUNTER"; },
		{ groupFilter = "ROGUE"; },
		{ groupFilter = "DEATHKNIGHT"; },
	} );
	GridLayout:AddLayout( L.GRID_LAYOUT_GROUP, {
		PetGroup,
		{ groupFilter = "1"; },
		{ groupFilter = "2"; },
		{ groupFilter = "3"; },
		{ groupFilter = "4"; },
		{ groupFilter = "5"; },
		{ groupFilter = "6"; },
		{ groupFilter = "7"; },
		{ groupFilter = "8"; },
	} );

	-- Disable party frames
	for Index = 1, MAX_PARTY_MEMBERS do
		local Frame = _G[ "PartyMemberFrame"..Index ];
		Frame:Hide();
		_Clean:WrapScript( Frame, "OnShow", [[
			self:Hide();
			return false; -- Don't call real OnShow script
		]] );

		UnregisterUnitWatch( Frame );
		Frame:UnregisterAllEvents();
		if ( Frame.healthbar ) then
			Frame.healthbar:UnregisterAllEvents();
		end
		if ( Frame.manabar ) then
			Frame.manabar:UnregisterAllEvents();
		end
	end
end
