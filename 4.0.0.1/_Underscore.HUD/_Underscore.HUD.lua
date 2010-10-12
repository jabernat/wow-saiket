--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.lua - Displays a table with health and mana values of the  *
  *   current target, player, the player's pet, and focus unit. This table     *
  *   sits in the middle of the screen to make the job of a healer a little    *
  *   easier, although it should prove useful for any class.                   *
  ****************************************************************************]]


local me = select( 2, ... );
_Underscore.HUD = me;
local L = me.L;

me.Frame = CreateFrame( "Frame", nil, UIParent );

me.UpdateRate = 0.1;
local RowHeight = 14;


me.Columns = {}; -- [ Name ] = ColumnFrame;
me.Units = {}; -- [ UnitID ] = RowFrame;

local ColumnMeta = { __index = setmetatable( {}, getmetatable( me.Frame ) ); };
local UnitMeta = { __index = setmetatable( {}, getmetatable( me.Frame ) ); };




do
	--- Throttles column resizes to once per frame at most.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );

		local Width, Name = 1e-3, self.Name;
		for _, Unit in pairs( me.Units ) do
			local Field = Unit[ Name ];
			if ( Field and Unit:IsShown() and Width < Field.Width ) then
				Width = Field.Width;
			end
		end
		self:SetWidth( Width );
	end
	--- Resizes the column to its contents before the next frame paint.
	function ColumnMeta.__index:Resize ()
		self:SetScript( "OnUpdate", OnUpdate );
	end
end




do
	--- Sets a field's text and resizes its column.
	local function FieldSetText ( self, Value )
		self:SetText( Value );

		local Width = self:GetStringWidth();
		if ( self.Width ~= Width ) then
			self.Width = Width;
			self.Column:Resize();
		end
	end

	--- Resizes the unit row when shown.
	function UnitMeta.__index:OnShow ()
		self:SetHeight( RowHeight );
		self.NextUpdate = 0;
	end
	--- Shrinks the unit row when hidden so lower rows shift up.
	function UnitMeta.__index:OnHide ()
		self:SetHeight( 1e-3 ); -- Not a noticeable height, but renders properly
		-- Resize affected columns
		for Name, Column in pairs( me.Columns ) do
			local Field = self[ Name ];
			if ( Field ) then
				Field.Value = nil;
				FieldSetText( Field, nil );
			end
		end
	end
	--- Periodically updates unit health and power.
	function UnitMeta.__index:OnUpdate ( Elapsed )
		self.NextUpdate = self.NextUpdate - Elapsed;
		if ( self.NextUpdate <= 0 ) then
			self.NextUpdate = me.UpdateRate;

			self:UpdateHealth();
			self:UpdatePower();
		end
	end

	--- Updates every field for the given unit.
	function UnitMeta.__index:Update ()
		if ( UnitExists( self.UnitID ) ) then
			self:UpdateName();
			self:UpdateHealth( true ); -- Force health and power to recolor
			self:UpdatePower( true );
			self:UpdateCondition();
			self:Show();
		else
			self:Hide();
		end
	end

	local UnitIsConnected = UnitIsConnected;
	--- @return True if the given UnitID is online.
	local function IsOnline ( UnitID )
		return UnitID == "player" -- Player is never offline
			or UnitIsConnected( UnitID ); -- Always true for non-players
	end

	local ceil, unpack = ceil, unpack;
	local Colors = _Underscore.Colors;
	--- Updates the given unit's name.
	function UnitMeta.__index:UpdateName ()
		local Field = self[ "Name" ];
		if ( Field ) then -- Name field can be omitted
			local UnitID = self.UnitID;
			FieldSetText( Field, UnitName( UnitID ) );
			Field:SetTextColor( unpack( UnitIsPlayer( UnitID ) and Colors.class[ select( 2, UnitClass( UnitID ) ) ] or Colors.Highlight ) );
		end
	end

	local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
	local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax;
	--- Updates the given unit's health.
	-- @param Force  Forces an update even if health value didn't change.
	function UnitMeta.__index:UpdateHealth ( Force )
		local Field, UnitID = self[ "Health" ], self.UnitID;
		local Value, Max = false, UnitHealthMax( UnitID );
		if ( Max ~= 0 and IsOnline( UnitID ) ) then
			Value = UnitIsDeadOrGhost( UnitID ) and 0
				or UnitHealth( UnitID ) / Max;
		end

		if ( Force or self.Value ~= Value ) then
			self.Value = Value;
			FieldSetText( Field, Value and ceil( 100 * Value ) or L.VALUE_IGNORED ); -- Never rounds to 0

			-- Update color
			local R, G, B;
			if ( Value == 1 ) then
				R, G, B = 1, 1, 1;
			elseif ( not Value or Value == 0 ) then
				R, G, B = 0.5, 0.5, 0.5;
			else -- Blend
				if ( Value > 0.5 ) then
					R, G, B = ( 1 - Value ) * 2, 1, 0;
				else
					R, G, B = 1, Value * 2, 0;
				end
			end
			Field:SetTextColor( R, G, B );
		end
	end

	local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax;
	local UnitPowerType = UnitPowerType;
	local IgnoredPowerTypes = {
		FOCUS = true;
		HAPPINESS = true;
	};
	--- Updates the given unit's power (mana/rage/etc).
	-- @param Force  Forces an update even if power value/type didn't change.
	function UnitMeta.__index:UpdatePower ( Force )
		local Field, UnitID = self[ "Power" ], self.UnitID;
		local Value, Max = false, UnitPowerMax( UnitID );
		local _, PowerType, R, G, B = UnitPowerType( UnitID );
		if ( Max ~= 0 and not IgnoredPowerTypes[ PowerType ] and IsOnline( UnitID ) ) then
			Value = UnitIsDeadOrGhost( UnitID ) and 0
				or UnitPower( UnitID ) / Max;
		end

		if ( Force or Field.Value ~= Value ) then
			Field.Value = Value;
			FieldSetText( Field, Value and ceil( 100 * Value ) or L.VALUE_IGNORED ); -- Never rounds to 0

			-- Update color
			if ( Value == 1 ) then
				R, G, B = 1, 1, 1;
			elseif ( not Value or Value == 0 ) then
				R, G, B = 0.5, 0.5, 0.5;
			else -- Blend
				local Color = Colors.power[ PowerType ]
					or ( not R and Colors.power[ "MANA" ] ); -- Doesn't have a custom color
				if ( Color ) then
					R, G, B = unpack( Color );
				end
				local Color2 = 0.5 * ( 1 - Value );
				R, G, B = Color2 + R * Value, Color2 + G * Value, Color2 + B * Value;
			end
			Field:SetTextColor( R, G, B );
		end
	end

	local UnitBuff = UnitBuff;
	local UnitIsGhost = UnitIsGhost;
	local UnitIsDead = UnitIsDead;
	local FeignDeath = GetSpellInfo( 28728 );
	--- Updates the given unit's condition label.
	function UnitMeta.__index:UpdateCondition ()
		local UnitID = self.UnitID;
		local Condition = ( not IsOnline( UnitID ) and "OFFLINE" )
			or ( UnitBuff( UnitID, FeignDeath ) and "FEIGN" )
			or ( UnitIsGhost( UnitID ) and "GHOST" )
			or ( UnitIsDead( UnitID ) and "DEAD" );
		FieldSetText( self[ "Condition" ], Condition and L[ Condition ] or nil );
	end
end




--- Update the name field when a unit's name changes.
function me.Frame:UNIT_NAME_UPDATE ( _, UnitID )
	local Unit = me.Units[ UnitID ];
	if ( Unit ) then
		Unit:UpdateName();
	end
end
--- Update the condition field when a unit's "UnitIsCorpse" result changes.
function me.Frame:UNIT_DYNAMIC_FLAGS ( _, UnitID )
	local Unit = me.Units[ UnitID ];
	if ( Unit ) then
		Unit:UpdateCondition();
	end
end
--- Update the condition field when a unit feigns or becomes a ghost.
me.Frame.UNIT_AURA = me.Frame.UNIT_DYNAMIC_FLAGS;


--- Updates pet units when they change.
function me.Frame:UNIT_PET ( _, OwnerUnitID )
	local Unit = me.Units[ OwnerUnitID == "player" and "pet" or OwnerUnitID.."pet" ];
	if ( Unit ) then
		Unit:Update();
	end
end
--- Updates the target unit when it changes.
function me.Frame:PLAYER_TARGET_CHANGED ()
	me.Units[ "target" ]:Update();
end
--- Updates the focus unit when it changes.
function me.Frame:PLAYER_FOCUS_CHANGED ()
	me.Units[ "focus" ]:Update();
end

--- Refresh all units after zoning.
function me.Frame:PLAYER_ENTERING_WORLD ()
	for _, Unit in pairs( me.Units ) do
		Unit:Update();
	end
end




local Frame = me.Frame;
Frame:SetSize( 1, 1 );
Frame:SetPoint( "CENTER" );
Frame:SetFrameStrata( "BACKGROUND" );
Frame:SetAlpha( 0.5 );

Frame:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
Frame:RegisterEvent( "UNIT_NAME_UPDATE" );
Frame:RegisterEvent( "UNIT_DYNAMIC_FLAGS" );
Frame:RegisterEvent( "UNIT_AURA" );
Frame:RegisterEvent( "UNIT_PET" );
Frame:RegisterEvent( "PLAYER_TARGET_CHANGED" );
Frame:RegisterEvent( "PLAYER_FOCUS_CHANGED" );
Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );


-- Setup all columns
local function CreateColumn ( Name, Align )
	local Column = setmetatable( CreateFrame( "Frame", nil, Frame ), ColumnMeta );
	me.Columns[ Name ] = Column;
	Column.Name, Column.Align = Name, Align;

	Column:SetSize( 1e-3, 1e-3 );
	return Column;
end
CreateColumn( "Name", "RIGHT" ):SetPoint( "RIGHT", Frame, "LEFT", -16, 0 );
local Health = CreateColumn( "Health", "RIGHT" );
Health:SetPoint( "LEFT", Frame, "RIGHT", 4, 0 );
local Power = CreateColumn( "Power", "RIGHT" );
Power:SetPoint( "LEFT", Health, "RIGHT", 4, 0 );
CreateColumn( "Condition", "LEFT" ):SetPoint( "LEFT", Power, "RIGHT", 16, 0 );


-- Setup all unit rows
local function CreateUnit ( UnitID )
	local Unit = setmetatable( CreateFrame( "Frame", nil, Frame ), UnitMeta );
	me.Units[ UnitID ], Unit.UnitID = Unit, UnitID;

	Unit:Hide();
	Unit:SetSize( 1e-3, 1e-3 );
	Unit:SetScript( "OnShow", Unit.OnShow );
	Unit:SetScript( "OnHide", Unit.OnHide );
	Unit:SetScript( "OnUpdate", Unit.OnUpdate );

	-- Create all fields
	for Name, Column in pairs( me.Columns ) do
		local Field = Unit:CreateFontString( nil, "ARTWORK", "NumberFontNormalLarge" );
		Unit[ Name ] = Field;
		Field.Column, Field.Width = Column, 0;
		Field:SetPoint( "TOP" );
		Field:SetPoint( Column.Align, Column );
	end
	local Color = GRAY_FONT_COLOR;
	Unit[ "Condition" ]:SetTextColor( Color.r, Color.g, Color.b );
	return Unit;
end
CreateUnit( "target" ):SetPoint( "BOTTOM", Frame, "TOP", 0, 16 );
local Player = CreateUnit( "player" );
Player:SetPoint( "TOP", Frame, "BOTTOM" );
Player[ "Name" ] = false; -- Don't show player's name
local Pet = CreateUnit( "pet" );
Pet:SetPoint( "TOP", Player, "BOTTOM" );
Pet:SetScale( 0.8 );
CreateUnit( "focus" ):SetPoint( "TOP", Pet, "BOTTOM", 0, -16 );