--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.lua - Common functions and data used by _Clean modules.             *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local me = CreateFrame( "Frame", "_Clean" );

local Colors = {
	HealthSmooth = {
		1.0, 0.0, 0.0, --   0%
		0.6, 0.6, 0.0, --  50%
		0.0, 0.4, 0.0  -- 100%
	};
	Pet =  { 0.1, 0.5, 0.1 };
	Cast = { 0.6, 0.6, 0.3 };
	ExperienceRested = { 0.2, 0.4, 0.7, 0.6 };


	Normal    = { 0.6, 0.85, 1.0 }; -- Frosty blue
	Highlight = { 0.8, 0.8, 8/15 }; -- Gold, same as title
	Foreground = { 0.0, 0.5, 1.0 };
	Background = { 0.0, 0.0, 0.0 };


	-- Shared with oUF layout if loaded
	disconnected = { 0.6, 0.6, 0.6 };
	power = {
		MANA   = { 0.2, 0.4, 0.7 };
		RAGE   = { 0.6, 0.2, 0.3 };
		ENERGY = { 0.6, 0.6, 0.3 };
	};
	class = {};
	reaction = {
		[ 1 ] = { 0.7, 0.2, 0.2 }; -- Hated
		[ 3 ] = { 0.8, 0.5, 0.2 }; -- Unfriendly
		[ 4 ] = { 0.8, 0.7, 0.2 }; -- Neutral
		[ 8 ] = { 0.1, 0.6, 0.2 }; -- Exalted
	};
};
me.Colors = Colors;
Colors.power.RUNIC_POWER = Colors.power.RAGE;
Colors.power.FUEL = Colors.power.ENERGY;
for Class, Color in pairs( RAID_CLASS_COLORS ) do
	Colors.class[ Class ] = { Color.r, Color.g, Color.b };
end
Colors.reaction[ 2 ] = Colors.reaction[ 1 ];
for Index = 5, 7 do
	Colors.reaction[ Index ] = Colors.reaction[ 8 ];
end
Colors.Experience = Colors.reaction[ 8 ];


me.TopMargin = CreateFrame( "Frame", nil, UIParent );
me.BottomPane = CreateFrame( "Frame", nil, UIParent );

local AddOnInitializers = {};
local LockedButtons = {};
local ProtectedFunctionQueue = {};

local InCombat = false;




--[[****************************************************************************
  * Function: _Clean.NilFunction                                               *
  * Description: Recycled generic function placeholder.                        *
  ****************************************************************************]]
function me.NilFunction () end

--[[****************************************************************************
  * Function: _Clean:RemoveIconBorder                                          *
  * Description: Hides the border graphic from an action button-like icon.     *
  ****************************************************************************]]
function me:RemoveIconBorder ()
	self:SetTexCoord( 0.08, 0.92, 0.08, 0.92 );
end




--[[****************************************************************************
  * Function: _Clean.IsAddOnLoadable                                           *
  * Description: Returns true if an addon can possibly load this session.      *
  ****************************************************************************]]
function me.IsAddOnLoadable ( Name )
	local Loadable, Reason = select( 5, GetAddOnInfo( Name ) );
	return Loadable or ( Reason == "DISABLED" and IsAddOnLoadOnDemand( Name ) ); -- Loadable or can become loadable
end
--[[****************************************************************************
  * Function: _Clean.InitializeAddOn                                           *
  * Description: Runs the given addon's initializer if it loaded.              *
  ****************************************************************************]]
function me.InitializeAddOn ( Name )
	Name = Name:upper(); -- For case insensitive file systems (Windows')
	local Initializer = AddOnInitializers[ Name ];
	if ( Initializer and select( 2, IsAddOnLoaded( Name ) ) ) then -- Returns false if addon is currently loading
		if ( type( Initializer ) == "table" ) then
			for _, Script in ipairs( Initializer ) do
				Script();
			end
		else
			Initializer();
		end
		AddOnInitializers[ Name ] = nil;
		return true;
	end
end
--[[****************************************************************************
  * Function: _Clean.RegisterAddOnInitializer                                  *
  * Description: Register a function to run when an addon loads.               *
  ****************************************************************************]]
function me.RegisterAddOnInitializer ( Name, Initializer )
	if ( me.IsAddOnLoadable( Name ) ) then
		Name = Name:upper();
		local OldInitializer = AddOnInitializers[ Name ];
		if ( OldInitializer ) then -- Put multiple initializers in a table
			if ( type( OldInitializer ) ~= "table" ) then
				AddOnInitializers[ Name ] = { OldInitializer };
			end
			tinsert( AddOnInitializers[ Name ], Initializer );
		else
			AddOnInitializers[ Name ] = Initializer;
		end

		return me.InitializeAddOn( Name );
	end
end
--[[****************************************************************************
  * Function: _Clean:ADDON_LOADED                                              *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	me.InitializeAddOn( AddOn );
end


--[[****************************************************************************
  * Function: _Clean.AddLockedButton                                           *
  * Description: Registers a button to only accept mouse clicks when the       *
  *   control modifier is held.                                                *
  ****************************************************************************]]
function me.AddLockedButton ( Button )
	LockedButtons[ Button ] = true;
	local Enable = IsControlKeyDown() == 1;
	me.RunProtectedFunction( function ()
		Button:EnableMouse( Enable );
	end, Button:IsProtected() );
end
--[[****************************************************************************
  * Function: _Clean.RemoveLockedButton                                        *
  * Description: Unlocks a button.                                             *
  ****************************************************************************]]
function me.RemoveLockedButton ( Button )
	LockedButtons[ Button ] = nil;
	me.RunProtectedFunction( function ()
		Button:EnableMouse( true );
	end, Button:IsProtected() );
end
--[[****************************************************************************
  * Function: _Clean:MODIFIER_STATE_CHANGED                                    *
  ****************************************************************************]]
function me:MODIFIER_STATE_CHANGED ( _, Modifier, State )
	if ( Modifier:sub( 2 ) == "CTRL" ) then
		local Enable = State == 1;
		local Protected = false;
		for Button in pairs( LockedButtons ) do
			if ( Button:IsProtected() ) then
				Protected = true;
				break;
			end
		end
		me.RunProtectedFunction( function ()
			for Button in pairs( LockedButtons ) do
				Button:EnableMouse( Enable );
				if ( not Enable ) then
					-- Don't let it get locked on the cursor
					Button:StopMovingOrSizing();
				end
			end
		end, Protected );
	end
end


--[[****************************************************************************
  * Function: _Clean.RunProtectedFunction                                      *
  * Description: Runs an function, or stores it until after combat ends if it  *
  *   calls protected functions.                                               *
  ****************************************************************************]]
function me.RunProtectedFunction ( Function, Protected )
	if ( InCombat and Protected ) then -- Store for later
		ProtectedFunctionQueue[ #ProtectedFunctionQueue + 1 ] = Function;
	else
		Function();
	end
end
--[[****************************************************************************
  * Function: _Clean:PLAYER_REGEN_DISABLED                                     *
  ****************************************************************************]]
function me:PLAYER_REGEN_DISABLED ()
	InCombat = true;
end
--[[****************************************************************************
  * Function: _Clean:PLAYER_REGEN_ENABLED                                      *
  ****************************************************************************]]
function me:PLAYER_REGEN_ENABLED ()
	InCombat = false;

	-- Combat lockdown over; run all stored functions
	for Index = 1, #ProtectedFunctionQueue do
		ProtectedFunctionQueue[ Index ]();
		ProtectedFunctionQueue[ Index ] = nil;
	end
end

--[[****************************************************************************
  * Function: _Clean:OnEvent                                                   *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( self[ Event ] ) == "function" ) then
			self[ Event ]( self, Event, ... );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	me:RegisterEvent( "MODIFIER_STATE_CHANGED" );

	-- Place the layout panes
	me.TopMargin:SetPoint( "TOPLEFT" );
	me.TopMargin:SetPoint( "RIGHT" );
	me.TopMargin:SetHeight( 16 );
	me.BottomPane:SetPoint( "LEFT" );
	me.BottomPane:SetPoint( "RIGHT" );
	me.BottomPane:SetPoint( "TOP", UIParent, "CENTER" );
	me.BottomPane:SetPoint( "BOTTOM" );
	me.BottomPane:SetFrameStrata( "BACKGROUND" );

	-- Remove class icon padding
	local IconPadding = 0.08 / 4; -- Icons are in a 4x4 grid
	local function RemoveClassIconBorders ( TCoords )
		for _, Coords in pairs( TCoords ) do
			Coords[ 1 ], Coords[ 2 ] = Coords[ 1 ] + IconPadding, Coords[ 2 ] - IconPadding;
			Coords[ 3 ], Coords[ 4 ] = Coords[ 3 ] + IconPadding, Coords[ 4 ] - IconPadding;
		end
	end
	RemoveClassIconBorders( CLASS_ICON_TCOORDS );
	RemoveClassIconBorders( CLASS_BUTTONS );


	-- Add media to LibSharedMedia
	LibSharedMedia:Register( LibSharedMedia.MediaType.STATUSBAR, "_Clean", [[Interface\AddOns\_Clean\Skin\Glaze]] );

	-- Alert sounds
	local Sound = LibSharedMedia.MediaType.SOUND;
	LibSharedMedia:Register( Sound, "Blizzard: Space Impact", [[Sound\Effects\DeathImpacts\SpaceDeathUni.wav]] );
	LibSharedMedia:Register( Sound, "Blizzard: Whisp", [[Sound\Event Sounds\Wisp\WispReady1.wav]] );
	LibSharedMedia:Register( Sound, "Blizzard: Alarm Clock", [[Sound\Interface\AlarmClockWarning2.wav]] );
	LibSharedMedia:Register( Sound, "Blizzard: Glyph Creation", [[Sound\Interface\Glyph_MajorCreate.wav]] );
	LibSharedMedia:Register( Sound, "Blizzard: Fanfare", [[Sound\Interface\ReadyCheck.wav]] );
	LibSharedMedia:Register( Sound, "Blizzard: Boss Emote", [[Sound\Interface\RaidBossWarning.wav]] );
end
