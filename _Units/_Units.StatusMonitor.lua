--[[****************************************************************************
  * _Units by Saiket                                                           *
  * _Units.StatusMonitor.lua - Displays a table with health and mana values of *
  *   the current target, player, the player's pet, and focus unit. This       *
  *   table sits in the middle of the screen to make the job of a healer a     *
  *   little easier, although it should prove useful for any class.            *
  ****************************************************************************]]


local L = _UnitsLocalization;
local _Units = _Units;
local me = CreateFrame( "Frame", nil, UIParent );
_Units.StatusMonitor = me;

me.Alpha = 0.5;
me.RowHeight = 14;
me.UpdateRate = 0.1;


me.Columns = {};
me.Units = {};




--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitUpdateName                              *
  * Description: Updates the given unit's name.                                *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitName, UnitClass = UnitName, UnitClass;
	local select = select;
	local unpack = unpack;

	local Field;
	local Color, R, G, B;
	function me.UnitUpdateName ( UnitID )
		if ( UnitID ~= "player" ) then -- Never display the player's name
			Field = me.Units[ UnitID ][ "Name" ];
			Field:SetText( UnitName( UnitID ) );

			if ( UnitIsPlayer( UnitID ) ) then
				R, G, B = unpack( _Units.Colors.class[ select( 2, UnitClass( UnitID ) ) ] );
			else
				Color = NORMAL_FONT_COLOR;
				R, G, B = Color.r, Color.g, Color.b;
			end
			Field:SetTextColor( R, G, B );
		end
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitUpdateHealth                            *
  * Description: Updates the given unit's health along with its condition.     *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitIsConnected = UnitIsConnected;
	local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
	local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax;
	local ceil = ceil;

	local Field, Value, Max;
	local R, G, B;
	function me.UnitUpdateHealth ( UnitID, Force )
		Field = me.Units[ UnitID ][ "Health" ];

		Max = UnitHealthMax( UnitID );
		if ( Max == 0 ) then
			Value = false;
		else
			if ( ( UnitIsPlayer( UnitID ) and not UnitIsConnected( UnitID ) ) or UnitIsDeadOrGhost( UnitID ) ) then
				Value = 0;
			else
				Value = ceil( 100 * UnitHealth( UnitID ) / Max ); -- Never rounds to 0
			end
		end
		if ( Force or Field.Value ~= Value ) then
			Field.Value = Value;
			Field:SetText( Value or L.STATUSMONITOR_IGNORED );
			me.RequestColumnAutosize( "Health" );

			-- Calculate color
			if ( not Value or Value == 0 ) then
				R, G, B = 0.5, 0.5, 0.5;
			elseif ( Value == 100 ) then
				R, G, B = 1, 1, 1;
			else -- Blend
				Value = Value / 100;
				B = 0;
				if ( Value > 0.5 ) then
					R, G = ( 1 - Value ) * 2, 1;
				else
					R, G = 1, Value * 2;
				end
			end
			Field:SetTextColor( R, G, B );
		end
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitUpdatePower                             *
  * Description: Updates the given unit's power (mana/rage/etc).               *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitIsConnected = UnitIsConnected;
	local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
	local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax;
	local UnitPowerType = UnitPowerType;
	local ceil = ceil;
	local unpack = unpack;

	local IgnoredPowerTypes = {
		FOCUS = true;
		HAPPINESS = true;
	};
	local Field, Value, Max;
	local PowerType, _;
	local R, G, B, Color2;
	function me.UnitUpdatePower ( UnitID, Force )
		Field = me.Units[ UnitID ][ "Power" ];

		Max, _, PowerType, R, G, B = UnitPowerMax( UnitID ), UnitPowerType( UnitID );
		if ( Max == 0 or IgnoredPowerTypes[ PowerType ] ) then
			Value = false;
		else
			if ( ( UnitIsPlayer( UnitID ) and not UnitIsConnected( UnitID ) ) or UnitIsDeadOrGhost( UnitID ) ) then
				Value = 0;
			else
				Value = ceil( 100 * UnitPower( UnitID ) / Max ); -- Never rounds to 0
			end
		end
		if ( Force or Field.Value ~= Value ) then
			Field.Value = Value;
			Field:SetText( Value or L.STATUSMONITOR_IGNORED );
			me.RequestColumnAutosize( "Power" );

			-- Calculate color
			if ( not Value or Value == 0 ) then
				R, G, B = 0.5, 0.5, 0.5;
			elseif ( Value == 100 ) then
				R, G, B = 1, 1, 1;
			else -- Blend
				if ( not R ) then -- Power type doesn't have a custom color
					R, G, B = unpack( _Units.Colors.power[ PowerType ] or _Units.Colors.power[ "MANA" ] );
				end
				Value = Value / 100;
				Color2 = 0.5 * ( 1 - Value );
				R, G, B = Color2 + R * Value, Color2 + G * Value, Color2 + B * Value;
			end
			Field:SetTextColor( R, G, B );
		end
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitUpdateCondition                         *
  * Description: Updates the given unit's condition label.                     *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitIsConnected = UnitIsConnected;
	local UnitBuff = UnitBuff;
	local UnitIsGhost = UnitIsGhost;
	local UnitIsDead = UnitIsDead;

	local FeignDeath = GetSpellInfo( 28728 );
	function me.UnitUpdateCondition ( UnitID )
		me.Units[ UnitID ][ "Condition" ]:SetText( L[
			( UnitIsPlayer( UnitID ) and not UnitIsConnected( UnitID ) and "OFFLINE" )
			or ( UnitBuff( UnitID, FeignDeath ) and "FEIGN" )
			or ( UnitIsGhost( UnitID ) and "GHOST" )
			or ( UnitIsDead( UnitID ) and "DEAD" ) ] );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitUpdate                                  *
  * Description: Updates every stat for the given unit.                        *
  ****************************************************************************]]
do
	local UnitExists, UnitName = UnitExists, UnitName;
	function me.UnitUpdate ( UnitID )
		local Row = me.Units[ UnitID ];
		if ( UnitExists( UnitID ) and UnitName( UnitID ) ) then
			Row:Show();
			me.UnitUpdateName( UnitID );
			me.UnitUpdateHealth( UnitID, true ); -- Force health and power to recolor
			me.UnitUpdatePower( UnitID, true );
			me.UnitUpdateCondition( UnitID );
		else
			Row:Hide();
		end
	end
end


--[[****************************************************************************
  * Function: _Units.StatusMonitor:UnitOnShow                                  *
  ****************************************************************************]]
function me:UnitOnShow ()
	self:SetHeight( me.RowHeight + ( self.Margin or 0 ) );
	self.NextUpdate = 0;
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UnitOnHide                                  *
  ****************************************************************************]]
function me:UnitOnHide ()
	self:SetHeight( 1e-4 ); -- Not a noticeable height, but renders properly
	for Name in pairs( me.Columns ) do
		self[ Name ].Value = nil;
		me.RequestColumnAutosize( Name );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UnitOnUpdate                                *
  ****************************************************************************]]
do
	local UnitID;
	function me:UnitOnUpdate ( Elapsed )
		self.NextUpdate = self.NextUpdate - Elapsed;
		if ( self.NextUpdate <= 0 ) then
			self.NextUpdate = me.UpdateRate;

			UnitID = self.UnitID;
			me.UnitUpdateHealth( UnitID );
			me.UnitUpdatePower( UnitID );
		end
	end
end




--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_NAME_UPDATE                            *
  ****************************************************************************]]
function me:UNIT_NAME_UPDATE ( _, UnitID )
	if ( me.Units[ UnitID ] ) then
		me.UnitUpdateName( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_HEALTH                                 *
  ****************************************************************************]]
function me:UNIT_HEALTH ( _, UnitID )
	if ( me.Units[ UnitID ] ) then
		me.UnitUpdateCondition( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_MAXHEALTH                              *
  ****************************************************************************]]
me.UNIT_MAXHEALTH = me.UNIT_HEALTH;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_AURA                                   *
  ****************************************************************************]]
me.UNIT_AURA = me.UNIT_HEALTH;


--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_PET                                    *
  * Description: Fired when a unit's pet changes.                              *
  ****************************************************************************]]
function me:UNIT_PET ( _, UnitID )
	UnitID = UnitID == "player" and "pet" or UnitID.."pet";
	if ( me.Units[ UnitID ] ) then
		me.UnitUpdate( UnitID );
	end
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_TARGET_CHANGED                       *
  ****************************************************************************]]
function me:PLAYER_TARGET_CHANGED ()
	me.UnitUpdate( "target" );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_FOCUS_CHANGED                        *
  ****************************************************************************]]
function me:PLAYER_FOCUS_CHANGED ()
	me.UnitUpdate( "focus" );
end

--[[****************************************************************************
  * Function: _Units.StatusMonitor:PLAYER_ENTERING_WORLD                       *
  * Description: Refresh everything.                                           *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	for UnitID in pairs( me.Units ) do
		me.UnitUpdate( UnitID );
	end
end




--[[****************************************************************************
  * Function: _Units.StatusMonitor.RequestColumnAutosize                       *
  * Description: Queues a column to be autosized next frame.                   *
  ****************************************************************************]]
function me.RequestColumnAutosize ( Column )
	me.Columns[ Column ].Autosize = true;
	me:SetScript( "OnUpdate", me.OnUpdate );
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:OnUpdate                                    *
  * Description: Autosizes all columns that need it on frame draw and then     *
  *   unhooks itself.                                                          *
  ****************************************************************************]]
do
	local pairs = pairs;
	local max = max;
	local MaxWidth;
	function me:OnUpdate ()
		for Name, Column in pairs( me.Columns ) do
			if ( Column.Autosize ) then
				MaxWidth, Column.Autosize = 1;
				for _, Row in pairs( me.Units ) do
					if ( Row:IsShown() ) then
						MaxWidth = max( MaxWidth, Row[ Name ]:GetStringWidth() );
					end
				end

				Column:SetWidth( MaxWidth );
			end
		end
		self:SetScript( "OnUpdate", nil );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetWidth( 1 );
	me:SetHeight( 1 );
	me:SetPoint( "CENTER" );
	me:SetFrameStrata( "BACKGROUND" );
	me:SetAlpha( me.Alpha );

	me:SetScript( "OnEvent", _Units.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "UNIT_NAME_UPDATE" );
	me:RegisterEvent( "UNIT_HEALTH" );
	me:RegisterEvent( "UNIT_MAXHEALTH" );
	me:RegisterEvent( "UNIT_AURA" );
	me:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	me:RegisterEvent( "PLAYER_FOCUS_CHANGED" );
	me:RegisterEvent( "UNIT_PET" );
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );


	-- Setup all columns
	local function CreateColumn ( Name, Align )
		local Frame = CreateFrame( "Frame", nil, me );
		me.Columns[ Name ] = Frame;
		Frame.Align = Align;

		Frame:SetWidth( 1 );
		Frame:SetHeight( 1 );

		return Frame;
	end

	CreateColumn( "Name", "RIGHT" ):SetPoint( "RIGHT", me, "LEFT", -16, 0 );
	CreateColumn( "Health", "RIGHT" ):SetPoint( "LEFT", me, "RIGHT", 4, 0 );
	CreateColumn( "Power", "RIGHT" ):SetPoint( "LEFT", me.Columns[ "Health" ], "RIGHT", 4, 0 );
	CreateColumn( "Condition", "LEFT" ):SetPoint( "LEFT", me.Columns[ "Power" ], "RIGHT", 16, 0 );


	-- Setup all rows
	local function CreateRow ( UnitID, Margin )
		local Frame = CreateFrame( "Frame", nil, me );
		me.Units[ UnitID ] = Frame;
		Frame.UnitID = UnitID;
		Frame.Margin = Margin;

		Frame:SetScript( "OnShow", me.UnitOnShow );
		Frame:SetScript( "OnHide", me.UnitOnHide );
		Frame:SetScript( "OnUpdate", me.UnitOnUpdate );

		Frame:SetWidth( 1 );

		-- Create all fields
		for Name, Column in pairs( me.Columns ) do
			local Field = Frame:CreateFontString( nil, "ARTWORK", "NumberFontNormalLarge" );
			Frame[ Name ] = Field;
			Field:SetPoint( "BOTTOM" );
			Field:SetPoint( Column.Align, Column );
		end
		local Color = GRAY_FONT_COLOR;
		Frame[ "Condition" ]:SetTextColor( Color.r, Color.g, Color.b );
		Frame:Hide();

		return Frame;
	end

	CreateRow( "target" ):SetPoint( "BOTTOM", me, "TOP", 0, 16 );
	CreateRow( "player" ):SetPoint( "TOP", me, "BOTTOM" );
	CreateRow( "pet", -4 ):SetPoint( "TOP", me.Units[ "player" ], "BOTTOM" );
	me.Units[ "pet" ]:SetScale( 0.8 );
	CreateRow( "focus", 8 ):SetPoint( "TOP", me.Units[ "pet" ], "BOTTOM", 0, -8 );
end
