--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.StatusMonitor.lua - Displays a table with health and mana values of *
  *   the current target, player, the player's pet, and party members. This    *
  *   table sits in the middle of the screen to make the job of a healer a     *
  *   little easier, although it should prove useful for any class.            *
  ****************************************************************************]]


local L = _UnitsLocalization;
local _Units = _Units;
local me = CreateFrame( "Frame", nil, UIParent );
_Units.StatusMonitor = me;

local UnitFrame = {
	Height = 14;
	Alpha = 0.5;
};
me.UnitFrame = UnitFrame;


local Columns = {
	--[[ Contains configuration and data for each data column.
	Fields:
	  "Position": The column's position in the table; "0" is the center, where
      positive indexes grow to the right and negative ones to the left.
		"Align": Text alignment of column's text fields.
		"Offset": Distance between column and next closest column to the middle.
	]]
	[ "Name" ]      = { Position = -2; Align = "RIGHT"; Offset = 16; };
	[ "Health" ]    = { Position = -1; Align = "RIGHT"; Offset =  4; };
	[ "Mana" ]      = { Position =  1; Align = "RIGHT"; Offset =  4; };
	[ "Condition" ] = { Position =  2; Align =  "LEFT"; Offset = 16; };
};
me.Columns = Columns;

local Units = {
	--[[ Contains configuration and data for each unit frame.
	Fields:
	  "Position": Where the unit should be ordered in the list (>=1); "TOP" places
	    the unit above the table flow.
	  "Margin": Margin above the unit's row.
	  "Party": True if should update with generic party update events.
	  "Scale": Frame scale of the row.
	  "Offset": Margin below the unit's row.
	Each element is given the same fields as those in the Columns table above,
	  which point to those specific frames for the row.
	]]
	[ "target" ] = { Position = "TOP"; Offset = 8; }; -- Only one Top unit at a time!
	[ "player" ] = { Position = 1; };
	[ "pet" ]    = { Position = 2; Margin = -4; Scale = 0.8; };
	[ "focus" ]  = { Position = 3; Margin =  8; };
};
me.Units = Units;
local UnitsParty = {}; -- Compiled automatically based on Party flag
me.UnitsParty = UnitsParty;




--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitIsDisconnected                          *
  * Description: Returns true if a unit is a disconnected player.              *
  ****************************************************************************]]
function me.UnitIsDisconnected ( UnitID )
	return UnitIsPlayer( UnitID ) and not UnitIsConnected( UnitID );
end
local UnitIsDisconnected = me.UnitIsDisconnected;


--[[****************************************************************************
  * Function: _Units.StatusMonitor.ColumnAutosize                              *
  * Description: Resizes a column anchor to the width of its largest element.  *
  ****************************************************************************]]
function me.ColumnAutosize ( Column )
	local Max = 0;
	for _, UnitData in pairs( Units ) do
		if ( UnitData:IsShown() ) then
			Max = max( Max, UnitData[ Column ]:GetStringWidth() );
		end
	end

	Columns[ Column ]:SetWidth( Max );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.RequestColumnAutosize                       *
  * Description: Queues a column to be autosized next frame.                   *
  ****************************************************************************]]
function me.RequestColumnAutosize ( Column )
	Columns[ Column ].Autosize = true;
	me:SetScript( "OnUpdate", me.OnUpdate );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.ArrangeUnits                                *
  * Description: Sets the position of all unit frames.                         *
  ****************************************************************************]]
function me.ArrangeUnits ()
	-- Generate a list of unit frames in their display order
	local UnitOrder = {};
	for UnitID, UnitData in pairs( Units ) do
		if ( UnitData.Position ~= "TOP" ) then -- Place in normal order
			UnitOrder[ UnitData.Position ] = UnitData;
		else -- Special top unit; position it now
			UnitData:SetPoint( "BOTTOM", me, "TOP", 0, UnitData.Offset or 0 );
		end
	end

	-- Position unit frames
	local LastFrame = me;
	for _, UnitData in ipairs( UnitOrder ) do
		UnitData:SetPoint( "TOP", LastFrame, "BOTTOM", 0, UnitData.Offset or 0 );
		LastFrame = UnitData;
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.ArrangeColumns                              *
  * Description: Sets the position of columns.                                 *
  ****************************************************************************]]
function me.ArrangeColumns ()
	-- Generate a list of columns in their display order
	local ColumnOrder = {
		[ 0 ] = me;
	};
	for Column, ColumnFrame in pairs( Columns ) do
		-- Align column text from unit frames
		for _, UnitData in pairs( Units ) do
			local ColumnText = UnitData[ Column ];
			ColumnText:ClearAllPoints();
			ColumnText:SetPoint( "BOTTOM" );
			ColumnText:SetPoint( ColumnFrame.Align, ColumnFrame );
		end
		ColumnOrder[ ColumnFrame.Position ] = ColumnFrame;
	end

	-- Position right-hand columns
	local Index = 1;
	while ColumnOrder[ Index ] do
		ColumnOrder[ Index ]:SetPoint( "LEFT", ColumnOrder[ Index - 1 ], "RIGHT",
			ColumnOrder[ Index ].Offset or 0, 0 );
		Index = Index + 1;
	end
	-- Left-hand columns
	Index = -1;
	while ColumnOrder[ Index ] do
		ColumnOrder[ Index ]:SetPoint( "RIGHT", ColumnOrder[ Index + 1 ], "LEFT",
			-( ColumnOrder[ Index ].Offset or 0 ), 0 );
		Index = Index - 1;
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UpdateAllUnits                              *
  * Description: Updates stats of all unit frames.                             *
  ****************************************************************************]]
function me.UpdateAllUnits ()
	for UnitID in pairs( Units ) do
		UnitFrame.Update( UnitID );
	end
end


--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_HEALTH                                 *
  ****************************************************************************]]
function me:UNIT_HEALTH ( _, UnitID )
	if ( Units[ UnitID ] ) then
		UnitFrame.UpdateHealth( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_HEALTHMAX                              *
  ****************************************************************************]]
me.UNIT_HEALTHMAX = me.UNIT_HEALTH;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_MANA                                   *
  ****************************************************************************]]
function me:UNIT_MANA ( _, UnitID )
	if ( Units[ UnitID ] ) then
		UnitFrame.UpdateMana( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_MANAMAX                                *
  ****************************************************************************]]
me.UNIT_MANAMAX = me.UNIT_MANA;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_NAME_UPDATE                            *
  ****************************************************************************]]
function me:UNIT_NAME_UPDATE ( _, UnitID )
	if ( Units[ UnitID ] ) then
		UnitFrame.UpdateName( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_DISPLAYPOWER                           *
  ****************************************************************************]]
function me:UNIT_DISPLAYPOWER ( _, UnitID )
	if ( Units[ UnitID ] ) then
		UnitFrame.UpdateMana( UnitID );
	end
end

--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_PET                                    *
  * Description: Fired when a unit's pet changes.                              *
  ****************************************************************************]]
function me:UNIT_PET ( _, UnitID )
	UnitID = UnitID == "player" and "pet" or UnitID.."pet";
	if ( Units[ UnitID ] ) then
		UnitFrame.Update( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_TARGET_CHANGED                       *
  ****************************************************************************]]
function me:PLAYER_TARGET_CHANGED ()
	UnitFrame.Update( "target" );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_FOCUS_CHANGED                        *
  ****************************************************************************]]
function me:PLAYER_FOCUS_CHANGED ()
	UnitFrame.Update( "focus" );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PARTY_MEMBERS_CHANGED                       *
  * Description: Refreshes whole party.                                        *
  ****************************************************************************]]
function me:PARTY_MEMBERS_CHANGED ()
	for UnitID, UnitData in pairs( UnitsParty ) do
		UnitFrame.Update( UnitID );
	end
end

--[[****************************************************************************
  * Function: _Units.StatusMonitor:PARTY_MEMBER_ENABLE                         *
  * Description: Fired when one of the party members come online.              *
  ****************************************************************************]]
function me:PARTY_MEMBER_ENABLE ()
	for UnitID, UnitData in pairs( UnitsParty ) do
		UnitFrame.Update( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PARTY_MEMBER_DISABLE                        *
  * Description: Fired when one of the party members go offline or die.        *
  ****************************************************************************]]
me.PARTY_MEMBER_DISABLE = me.PARTY_MEMBER_ENABLE;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_ALIVE                                *
  * Description: Fired when releasing spirit or when rezzed before releasing.  *
  ****************************************************************************]]
function me:PLAYER_ALIVE ()
	UnitFrame.Update( "player" );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_DEAD                                 *
  ****************************************************************************]]
me.PLAYER_DEAD = me.PLAYER_ALIVE;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_UNGHOST                              *
  * Description: Fired when your ghost rezzes.                                 *
  ****************************************************************************]]
me.PLAYER_UNGHOST = me.PLAYER_ALIVE;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_ENTERING_WORLD                       *
  * Description: Refresh everything.                                           *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	self.UpdateAllUnits();
end

--[[****************************************************************************
  * Function: _Units.StatusMonitor:OnEvent                                     *
  * Description: Updates unit visibility and stat values.                      *
  ****************************************************************************]]
me.OnEvent = _Units.OnEvent;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:OnUpdate                                    *
  * Description: Autosizes all columns that need it on frame draw and then     *
  *   unhooks itself.                                                          *
  ****************************************************************************]]
function me:OnUpdate ()
	for Column, ColumnFrame in pairs( Columns ) do
		if ( ColumnFrame.Autosize ) then
			self.ColumnAutosize( Column );
		end
	end
	self:SetScript( "OnUpdate", nil );
end




--------------------------------------------------------------------------------
-- _Units.StatusMonitor.UnitFrame
---------------------------------

--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.Show                              *
  * Description: Enables display of a unit.                                    *
  ****************************************************************************]]
function UnitFrame.Show ( UnitID )
	local Frame = Units[ UnitID ];
	Frame:SetHeight( UnitFrame.Height + ( Frame.Margin or 0 ) );
	Frame:Show();
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.Hide                              *
  * Description: Disables display of a unit.                                   *
  ****************************************************************************]]
function UnitFrame.Hide ( UnitID )
	local Frame = Units[ UnitID ];
	Frame:SetHeight( 0.0001 ); -- Not a noticeable height, but renders properly
	Frame:Hide();
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.Create                            *
  * Description: Creates a new unit structure and allocates a display frame.   *
  ****************************************************************************]]
function UnitFrame.Create ( UnitID )
	local UnitData = Units[ UnitID ];
	local Frame = CreateFrame( "Frame", nil, me );
	UnitData[ 0 ] = Frame[ 0 ];
	setmetatable( UnitData, getmetatable( Frame ) );

	-- Position and configuration
	UnitData:SetWidth( 1 );
	UnitData:SetHeight( UnitFrame.Height + ( UnitData.Margin or 0 ) );
	if ( UnitData.Scale ) then
		UnitData:SetScale( UnitData.Scale );
	end
	UnitData:SetAlpha( UnitFrame.Alpha );
	UnitFrame.Hide( UnitID );

	-- Create all column fields
	for Column, ColumnFrame in pairs( Columns ) do
		UnitData[ Column ] = UnitData:CreateFontString( nil, "ARTWORK", "NumberFontNormalLarge" );
	end
	local Color = GRAY_FONT_COLOR;
	UnitData.Condition:SetTextColor( Color.r, Color.g, Color.b );
end

--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.UpdateName                        *
  * Description: Updates the given unit's name.                                *
  ****************************************************************************]]
function UnitFrame.UpdateName ( UnitID )
	local NameString = Units[ UnitID ].Name;
	local Color = UnitIsPlayer( UnitID )
		and ( UnitIsConnected( UnitID ) and RAID_CLASS_COLORS[ select( 2, UnitClass( UnitID ) ) ] or GRAY_FONT_COLOR )
		or NORMAL_FONT_COLOR;

	NameString:SetText( UnitName( UnitID ) );
	NameString:SetTextColor( Color.r, Color.g, Color.b );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.UpdateHealth                      *
  * Description: Updates the given unit's health along with its condition.     *
  ****************************************************************************]]
function UnitFrame.UpdateHealth ( UnitID )
	local HealthString = Units[ UnitID ].Health;

	-- Update health percentage
	local Health = ( UnitIsDisconnected( UnitID ) or UnitIsDeadOrGhost( UnitID ) )
		and 0
		or UnitHealth( UnitID ) / UnitHealthMax( UnitID );
	HealthString:SetText( ceil( Health * 100 ) ); -- Ceil makes sure low health never rounds to 0
	me.RequestColumnAutosize( "Health" );

	-- Calculate health color
	local R, G, B;
	if ( Health == 1 ) then
		R, G, B = 1, 1, 1;
	elseif ( Health == 0 ) then
		R, G, B = 0.5, 0.5, 0.5;
	else -- Somewhat hurt
		B = 0;
		if ( Health > 0.5 ) then
			R = ( 1 - Health ) * 2;
			G = 1;
		else -- Health > 0
			R = 1;
			G = Health * 2;
		end
	end
	HealthString:SetTextColor( R, G, B );

	-- Determine condition text
	local Condition = ( UnitIsDisconnected( UnitID ) and "OFFLINE" )
		or ( UnitIsFeignDeath( UnitID ) and "FEIGN" )
		or ( UnitIsGhost( UnitID ) and "GHOST" )
		or ( UnitIsDead( UnitID ) and "DEAD" );
	Units[ UnitID ].Condition:SetText( L[ Condition ] );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.UpdateMana                        *
  * Description: Updates the given unit's mana.                                *
  ****************************************************************************]]
function UnitFrame.UpdateMana ( UnitID )
	local ManaString = Units[ UnitID ].Mana;

	-- Update mana percentage
	local ManaMax = UnitManaMax( UnitID );
	local Mana;
	if ( ManaMax == 0 or UnitPowerType( UnitID ) ~= 0 ) then
		Mana = 0;
		ManaString:SetText( L.STATUSMONITOR_MANA_NOT_AVAILABLE );
	else
		Mana = ( UnitIsDisconnected( UnitID ) or UnitIsDeadOrGhost( UnitID ) )
			and 0
			or UnitMana( UnitID ) / ManaMax;
		ManaString:SetText( ceil( Mana * 100 ) ); -- Ceil makes sure low mana never rounds to 0
	end
	me.RequestColumnAutosize( "Mana" );

	-- Calculate energy color
	local R, G, B;
	if ( Mana == 0 ) then -- Traps not UsesMana also
		R, G, B = 0.5, 0.5, 0.5;
	elseif ( Mana == 1 ) then
		R, G, B = 1, 1, 1;
	else -- Mana: light teal to dark blue
		R, G, B = 0, Mana / 2 + 0.25, Mana / 2 + 0.5;
	end
	ManaString:SetTextColor( R, G, B );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitFrame.Update                            *
  * Description: Updates every stat for the given unit.                        *
  ****************************************************************************]]
function UnitFrame.Update ( UnitID )
	if ( UnitExists( UnitID ) and UnitName( UnitID ) ) then
		UnitFrame.Show( UnitID );
		UnitFrame.UpdateName( UnitID );
		UnitFrame.UpdateHealth( UnitID );
		UnitFrame.UpdateMana( UnitID );
	else
		UnitFrame.Hide( UnitID );
		me.RequestColumnAutosize( "Health" );
		me.RequestColumnAutosize( "Mana" );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Compile table of party-related units
	for UnitID, UnitData in pairs( Units ) do
		if ( UnitData.Party ) then
			UnitsParty[ UnitID ] = UnitData;
		end
	end


	me:SetWidth( 1 );
	me:SetHeight( 1 );
	me:SetPoint( "CENTER" );
	me:SetFrameStrata( "LOW" );
	me:EnableMouse( false );

	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	me:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	me:RegisterEvent( "PLAYER_FOCUS_CHANGED" );
	me:RegisterEvent( "PLAYER_ALIVE" ); -- From corpse to ghost/alive
	me:RegisterEvent( "PLAYER_DEAD" ); -- Alive to corpse
	me:RegisterEvent( "PLAYER_UNGHOST" ); -- From ghost to alive
	me:RegisterEvent( "UNIT_NAME_UPDATE" );
	me:RegisterEvent( "UNIT_HEALTH" );
	me:RegisterEvent( "UNIT_MAXHEALTH" );
	me:RegisterEvent( "UNIT_MANA" );
	me:RegisterEvent( "UNIT_MAXMANA" );
	me:RegisterEvent( "UNIT_DISPLAYPOWER" );
	if ( next( UnitsParty ) ) then -- At least one party related unit
		me:RegisterEvent( "PARTY_MEMBERS_CHANGED" );
		me:RegisterEvent( "PARTY_MEMBER_ENABLE" );  -- Connected
		me:RegisterEvent( "PARTY_MEMBER_DISABLE" ); -- Offline/dead
	end
	for UnitID in pairs( Units ) do
		if ( UnitID:match( "pet$" ) ) then -- Has a pet
			me:RegisterEvent( "UNIT_PET" );
			break;
		end
	end


	-- Allocate and position unit frames
	for UnitID, UnitData in pairs( Units ) do
		UnitFrame.Create( UnitID );
	end
	me.ArrangeUnits();

	-- Allocate and position all columns
	for Column, ColumnData in pairs( Columns ) do
		local Frame = CreateFrame( "Frame", nil, me );
		ColumnData[ 0 ] = Frame[ 0 ];
		setmetatable( ColumnData, getmetatable( Frame ) );
		ColumnData:SetWidth( 1 );
		ColumnData:SetHeight( 1 );
	end
	me.ArrangeColumns();

	me.UpdateAllUnits();
end
