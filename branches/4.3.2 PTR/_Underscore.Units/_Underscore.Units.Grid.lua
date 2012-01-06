--[[****************************************************************************
  * _Underscore.Units by Saiket                                                *
  * _Underscore.Units.Grid.lua - Modifies the Grid addon.                      *
  ****************************************************************************]]


if ( not IsAddOnLoaded( "Grid" ) ) then
	return;
end
local Units = select( 2, ... );




do
	--- Adds a backdrop and enables dropdown menus for new Grid unit frames.
	local function FrameInitialize ( Frame )
		Frame.menu = Units.ShowGenericMenu;
		_Underscore.Backdrop.Create( Frame, -2 );
	end

	-- Hook Grid frame creation
	local GridFrame = Grid:GetModule( "GridFrame" );
	hooksecurefunc( GridFrame, "InitialConfigFunction", FrameInitialize );

	-- Modify all existing frames
	GridFrame:WithAllFrames( function ( self )
		FrameInitialize( self.frame );
	end );
end


do
	-- Add better layouts that include pets from all classes
	local GridLayout = Grid:GetModule( "GridLayout" );
	local MaxLength = 10; -- Wrap groups longer than this
	local PetGroup = { isPetGroup = true; unitsPerColumn = MaxLength; };
	GridLayout:AddLayout( Units.L.GRID_LAYOUT_CLASS, {
		PetGroup,
		{ groupFilter = "WARRIOR"; unitsPerColumn = MaxLength; },
		{ groupFilter = "PRIEST"; unitsPerColumn = MaxLength; },
		{ groupFilter = "DRUID"; unitsPerColumn = MaxLength; },
		{ groupFilter = "PALADIN"; unitsPerColumn = MaxLength; },
		{ groupFilter = "SHAMAN"; unitsPerColumn = MaxLength; },
		{ groupFilter = "MAGE"; unitsPerColumn = MaxLength; },
		{ groupFilter = "WARLOCK"; unitsPerColumn = MaxLength; },
		{ groupFilter = "HUNTER"; unitsPerColumn = MaxLength; },
		{ groupFilter = "ROGUE"; unitsPerColumn = MaxLength; },
		{ groupFilter = "DEATHKNIGHT"; unitsPerColumn = MaxLength; },
	} );
	GridLayout:AddLayout( Units.L.GRID_LAYOUT_GROUP, {
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
end