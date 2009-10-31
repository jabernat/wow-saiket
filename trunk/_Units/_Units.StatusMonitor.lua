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


me.Columns = {};
me.Units = {};




--[[****************************************************************************
  * Function: _Units.StatusMonitor.UnitUpdateName                              *
  * Description: Updates the given unit's name.                                *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitIsConnected = UnitIsConnected;
	local UnitName, UnitClass = UnitName, UnitClass;
	local select = select;

	local Field, Color;
	function me.UnitUpdateName ( UnitID )
		if ( UnitID ~= "player" ) then -- Never display the player's name
			Field = me.Units[ UnitID ][ "Name" ];
			Field:SetText( UnitName( UnitID ) );

			if ( UnitIsPlayer( UnitID ) ) then
				if ( UnitIsConnected( UnitID ) ) then
					Color = oUF.colors.class[ select( 2, UnitClass( UnitID ) ) ];
				else
					Color = oUF.colors.disconnected;
				end
			else
				Color = NORMAL_FONT_COLOR;
			end
			Field:SetTextColor( Color.r, Color.g, Color.b );
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
	local UnitIsFeignDeath = UnitIsFeignDeath;
	local UnitIsGhost = UnitIsGhost;
	local UnitIsDead = UnitIsDead;

	local Field;
	local Health, Disconnected;
	local R, G, B;
	function me.UnitUpdateHealth ( UnitID )
		Field, Disconnected = me.Units[ UnitID ][ "Health" ], UnitIsPlayer( UnitID ) and not UnitIsConnected( UnitID );

		if ( Disconnected or UnitIsDeadOrGhost( UnitID ) ) then
			Health = 0;
		else
			Health = UnitHealth( UnitID ) / UnitHealthMax( UnitID );
		end
		Field:SetText( ceil( Health * 100 ) ); -- Never rounds to 0
		me.RequestColumnAutosize( "Health" );

		-- Calculate color
		if ( Health == 1 ) then -- 100%
			R, G, B = 1, 1, 1;
		elseif ( Health == 0 ) then
			R, G, B = 0.5, 0.5, 0.5;
		else
			B = 0;
			if ( Health > 0.5 ) then
				R = ( 1 - Health ) * 2;
				G = 1;
			else -- Health > 0
				R = 1;
				G = Health * 2;
			end
		end
		Field:SetTextColor( R, G, B );

		me.Units[ UnitID ][ "Condition" ]:SetText( L[
			( Disconnected and "OFFLINE" )
			or ( UnitIsFeignDeath( UnitID ) and "FEIGN" )
			or ( UnitIsGhost( UnitID ) and "GHOST" )
			or ( UnitIsDead( UnitID ) and "DEAD" ) ] );
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
	local Field, _;
	local Power, PowerMax, PowerType;
	local R, G, B;
	function me.UnitUpdatePower ( UnitID )
		Field = me.Units[ UnitID ][ "Power" ];

		PowerMax, _, PowerType = UnitPowerMax( UnitID ), UnitPowerType( UnitID );
		if ( PowerMax == 0 or IgnoredPowerTypes[ PowerType ] ) then
			Power = 0;
			Field:SetText( L.STATUSMONITOR_POWER_IGNORED );
		else
			if ( ( UnitIsPlayer( UnitID ) and not UnitIsConnected( UnitID ) ) or UnitIsDeadOrGhost( UnitID ) ) then
				Power = 0;
			else
				Power = UnitPower( UnitID ) / PowerMax;
			end
			Field:SetText( ceil( Power * 100 ) ); -- Never rounds to 0
		end
		me.RequestColumnAutosize( "Power" );

		-- Calculate color
		if ( Power == 0 ) then
			R, G, B = 0.5, 0.5, 0.5;
		elseif ( Power == 1 ) then -- 100%
			R, G, B = 1, 1, 1;
		else
			local Color, Color2 = _Units.PowerColors[ PowerType ], 0.5 * ( 1 - Power );
			R, G, B = Color2 + Color[ 1 ] * Power, Color2 + Color[ 2 ] * Power, Color2 + Color[ 3 ] * Power;
		end
		Field:SetTextColor( R, G, B );
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
			me.UnitUpdateHealth( UnitID );
			me.UnitUpdatePower( UnitID );
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
end
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UnitOnHide                                  *
  ****************************************************************************]]
function me:UnitOnHide ()
	self:SetHeight( 1e-4 ); -- Not a noticeable height, but renders properly
	for Name in pairs( me.Columns ) do
		me.RequestColumnAutosize( Name );
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
		me.UnitUpdateHealth( UnitID );
	end
end
me.UNIT_MAXHEALTH = me.UNIT_HEALTH;
--[[****************************************************************************
  * Function: _Units.StatusMonitor:UNIT_DISPLAYPOWER                           *
  * Description: Fired when a unit's power type changes.                       *
  ****************************************************************************]]
function me:UNIT_DISPLAYPOWER ( _, UnitID )
	if ( me.Units[ UnitID ] ) then
		me.UnitUpdatePower( UnitID );
	end
end
me.UNIT_ENERGY = me.UNIT_DISPLAYPOWER;
me.UNIT_MANA = me.UNIT_DISPLAYPOWER;
me.UNIT_RAGE = me.UNIT_DISPLAYPOWER;
me.UNIT_RUNIC_POWER = me.UNIT_DISPLAYPOWER;
me.UNIT_MAXENERGY = me.UNIT_DISPLAYPOWER;
me.UNIT_MAXMANA = me.UNIT_DISPLAYPOWER;
me.UNIT_MAXRAGE = me.UNIT_DISPLAYPOWER;
me.UNIT_MAXRUNIC_POWER = me.UNIT_DISPLAYPOWER;


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
  * Function: _Units.StatusMonitor:PLAYER_ALIVE                                *
  * Description: Fired when releasing spirit or when rezzed before releasing.  *
  ****************************************************************************]]
function me:PLAYER_ALIVE ()
	me.UnitUpdate( "player" );
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
	local max = max;
	function me:OnUpdate ()
		for Name, Column in pairs( me.Columns ) do
			if ( Column.Autosize ) then
				local Max = 1;
				for _, Row in pairs( me.Units ) do
					if ( Row:IsShown() ) then
						Max = max( Max, Row[ Name ]:GetStringWidth() );
					end
				end

				Column:SetWidth( Max );
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
	me:RegisterEvent( "UNIT_ENERGY" );
	me:RegisterEvent( "UNIT_MANA" );
	me:RegisterEvent( "UNIT_RAGE" );
	me:RegisterEvent( "UNIT_RUNIC_POWER" );
	me:RegisterEvent( "UNIT_MAXENERGY" );
	me:RegisterEvent( "UNIT_MAXMANA" );
	me:RegisterEvent( "UNIT_MAXRAGE" );
	me:RegisterEvent( "UNIT_MAXRUNIC_POWER" );
	me:RegisterEvent( "UNIT_DISPLAYPOWER" );
	me:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	me:RegisterEvent( "PLAYER_FOCUS_CHANGED" );
	me:RegisterEvent( "UNIT_PET" );
	me:RegisterEvent( "PLAYER_ALIVE" ); -- From corpse to ghost/alive
	me:RegisterEvent( "PLAYER_DEAD" ); -- Alive to corpse
	me:RegisterEvent( "PLAYER_UNGHOST" ); -- From ghost to alive
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
		Frame.Margin = Margin;

		Frame:SetScript( "OnShow", me.UnitOnShow );
		Frame:SetScript( "OnHide", me.UnitOnHide );

		Frame:SetWidth( 1 );
		Frame:Hide();

		-- Create all fields
		for Name, Column in pairs( me.Columns ) do
			local Field = Frame:CreateFontString( nil, "ARTWORK", "NumberFontNormalLarge" );
			Frame[ Name ] = Field;
			Field:SetPoint( "BOTTOM" );
			Field:SetPoint( Column.Align, Column );
		end
		local Color = GRAY_FONT_COLOR;
		Frame[ "Condition" ]:SetTextColor( Color.r, Color.g, Color.b );

		return Frame;
	end

	CreateRow( "target" ):SetPoint( "BOTTOM", me, "TOP", 0, 16 );
	CreateRow( "player" ):SetPoint( "TOP", me, "BOTTOM" );
	CreateRow( "pet", -4 ):SetPoint( "TOP", me.Units[ "player" ], "BOTTOM" );
	me.Units[ "pet" ]:SetScale( 0.8 );
	CreateRow( "focus", 8 ):SetPoint( "TOP", me.Units[ "pet" ], "BOTTOM", 0, -8 );
end
