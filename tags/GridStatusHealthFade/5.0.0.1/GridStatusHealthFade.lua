--[[****************************************************************************
  * GridStatusHealthFade by Saiket (Originally by North101)                    *
  * GridStatusHealthFade.lua - Adds a health status that fades from one color  *
  *   at max health to another at no health.                                   *
  ****************************************************************************]]


local L = select( 2, ... ).L;
local NS = Grid:GetModule( "GridStatus" ):NewModule( "GridStatusHealthFade" );

local STATUS_ID = "alert_healthFade";

local COLOR_CACHE_STEPS = 25; -- Number of color tables to pre-calculate
-- Value should divide 100 without remainder so that colors change only when percent text changes
local ColorCache = {};

NS.menuName, NS.options = L.TITLE, false;
NS.defaultDB = {
	debug = false;
	[ STATUS_ID ] = {
		text = L.TITLE;
		enable = true; priority = 1; range = false;
		ColorHigh = { r = 0; g = 1; b = 0; a = 1; };
		ColorLow = { r = 1; g = 0; b = 0; a = 1; };
	};
};




do
	--- Recalculates cached gradient colors.
	local function UpdateColorCache ()
		-- Rotate color tables so SendStatusGained thinks the colors changed
		table.insert( ColorCache, table.remove( ColorCache, 1 ) );

		local Low = NS.db.profile[ STATUS_ID ].ColorLow;
		local High = NS.db.profile[ STATUS_ID ].ColorHigh;
		for Step = 0, COLOR_CACHE_STEPS do
			local Percentage = Step / COLOR_CACHE_STEPS;
			local Color = ColorCache[ Step ];
			Color.r = Low.r + ( High.r - Low.r ) * Percentage;
			Color.g = Low.g + ( High.g - Low.g ) * Percentage;
			Color.b = Low.b + ( High.b - Low.b ) * Percentage;
			Color.a = Low.a + ( High.a - Low.a ) * Percentage;
		end
	end
	local function ColorGet ( self )
		local Property = self[ 3 ];
		local Color = NS.db.profile[ STATUS_ID ][ Property ];
		return Color.r, Color.g, Color.b, Color.a;
	end
	local function ColorSet ( self, R, G, B, A )
		local Property = self[ 3 ];
		local Color = NS.db.profile[ STATUS_ID ][ Property ];
		Color.r, Color.g, Color.b, Color.a = R, G, B, A or 1;
		UpdateColorCache();
		NS:UpdateAllUnits();
	end
	local Options = {
		color = false; -- Don't use original color picker
		ColorHigh = {
			type = "color"; hasAlpha = true; order = 1;
			name = L.COLOR_HIGH; desc = L.COLOR_HIGH_DESC;
			get = ColorGet; set = ColorSet;
		};
		ColorLow = {
			type = "color"; hasAlpha = true; order = 2;
			name = L.COLOR_LOW; desc = L.COLOR_LOW_DESC;
			get = ColorGet; set = ColorSet;
		};
	};
	--- Registers the HealthFade status and its options with Grid OnLoad.
	function NS:PostInitialize ()
		for Step = 0, COLOR_CACHE_STEPS do
			ColorCache[ Step ] = {};
		end
		UpdateColorCache();
		self:RegisterStatus( STATUS_ID, L.TITLE, Options, true );
	end
end
--- Called when this status is enabled and used.
function NS:OnStatusEnable ( Status )
	if ( Status == STATUS_ID ) then
		self:RegisterMessage( "Grid_UnitJoined" );
		self:RegisterEvent( "UNIT_HEALTH_FREQUENT", "UpdateUnit" );
		self:RegisterEvent( "UNIT_MAXHEALTH", "UpdateUnit" );
		self:RegisterEvent( "UNIT_CONNECTION", "UpdateUnit" );
		self:RegisterEvent( "PLAYER_ENTERING_WORLD", "UpdateAllUnits" );
		self:UpdateAllUnits();
	end
end
--- Called when this status gets disabled or becomes unused.
function NS:OnStatusDisable ( Status )
	if ( Status == STATUS_ID ) then
		self:UnregisterAllEvents();
		self:UnregisterAllMessages();
		self.core:SendStatusLostAllUnits( STATUS_ID );
	end
end
--- Completely reinitializes the status.
function NS:PostReset ()
	self:UpdateAllUnits();
end


--- Immediately updates new raid units.
function NS:Grid_UnitJoined ( Event, GUID, UnitID )
	self:UpdateUnit( Event, UnitID );
end
do
	local GridRoster = Grid:GetModule( "GridRoster" );
	--- Fully updates all active units.
	function NS:UpdateAllUnits ( Event )
		for GUID, UnitID in GridRoster:IterateRoster() do
			self:UpdateUnit( Event, UnitID );
		end
	end
	local UnitGUID = UnitGUID;
	local UnitHealth = UnitHealth;
	local UnitHealthMax = UnitHealthMax;
	local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
	local ceil = math.ceil;
	--- Updates or removes the health fade status for a given unit.
	function NS:UpdateUnit( Event, UnitID )
		local GUID = UnitGUID( UnitID );
		if ( not GridRoster:IsGUIDInRaid( GUID ) ) then
			return;
		end
		local HealthMax = UnitHealthMax( UnitID );
		if ( HealthMax == 0 ) then -- Unknown (offline, etc.)
			return self.core:SendStatusLost( GUID, STATUS_ID );
		end

		local Percentage;
		if ( UnitIsDeadOrGhost( UnitID ) ) then
			Percentage = 0; -- Keep ghosts' low health from rounding to 1%
		else
			local Health = UnitHealth( UnitID );
			Percentage = Health <= HealthMax and Health / HealthMax or 1; -- Cap at 100%
		end

		local DB = self.db.profile[ STATUS_ID ];
		return self.core:SendStatusGained( GUID, STATUS_ID,
			DB.priority, DB.range and 40,
			ColorCache[ ceil( Percentage * COLOR_CACHE_STEPS ) ],
			L.LABEL_FORMAT:format( ceil( Percentage * 100 ) ) );
	end
end