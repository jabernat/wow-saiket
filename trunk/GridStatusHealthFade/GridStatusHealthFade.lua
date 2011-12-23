--[[****************************************************************************
  * GridStatusHealthFade by Saiket (Originally by North101)                    *
  * GridStatusHealthFade.lua - Adds a health status that fades from one color  *
  *   at max health to another at no health.                                   *
  ****************************************************************************]]


local L = select( 2, ... ).L;
local NS = Grid:GetModule( "GridStatus" ):NewModule( "GridStatusHealthFade" );

local STATUS_ID = "alert_healthFade";

NS.ColorTables = {};
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
	local function ColorGet ( self )
		local Property = self[ 3 ];
		local Color = NS.db.profile[ STATUS_ID ][ Property ];
		return Color.r, Color.g, Color.b, Color.a;
	end
	local function ColorSet ( self, R, G, B, A )
		local Property = self[ 3 ];
		local Color = NS.db.profile[ STATUS_ID ][ Property ];
		Color.r, Color.g, Color.b, Color.a = R, G, B, A or 1;
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
		self:RegisterStatus( STATUS_ID, L.TITLE, Options, true );
	end
end
--- Called when this status is enabled and used.
function NS:OnStatusEnable ( Status )
	if ( Status == STATUS_ID ) then
		self:RegisterMessage( "Grid_UnitJoined" );
		self:RegisterMessage( "Grid_UnitLeft" );
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
		wipe( self.ColorTables );
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
--- Removes cached color tables of units that leave group.
function NS:Grid_UnitLeft ( Event, GUID, UnitID )
	self.ColorTables[ GUID ] = nil;
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
		local Health, Percentage;
		if ( HealthMax == 0 ) then -- Unknown (offline, etc.)
			Percentage = 1;
		elseif ( UnitIsDeadOrGhost( UnitID ) ) then
			Health, Percentage = 0, 0; -- Keep ghosts' low health from rounding to 1%
		else
			Health = UnitHealth( UnitID );
			Percentage = Health / HealthMax;
		end

		local DB = self.db.profile[ STATUS_ID ];
		local Color = self.ColorTables[ GUID ];
		if ( not Color ) then
			Color = {};
			self.ColorTables[ GUID ] = Color;
		end
		local High, Low = DB.ColorHigh, DB.ColorLow;
		Color.r = High.r * Percentage + Low.r * ( 1 - Percentage );
		Color.g = High.g * Percentage + Low.g * ( 1 - Percentage );
		Color.b = High.b * Percentage + Low.b * ( 1 - Percentage );
		Color.a = High.a * Percentage + Low.a * ( 1 - Percentage );

		-- Hack to force updates when the color changes
		local Cache = self.core:GetCachedStatus( GUID, STATUS_ID );
		if ( Cache ) then
			Cache.color = nil;
		end
		self.core:SendStatusGained( GUID, STATUS_ID,
			DB.priority,
			( DB.range and 40 ),
			Color,
			Health and L.LABEL_FORMAT:format( ceil( Percentage * 100 ) ),
			Percentage, 1,
			DB.icon );
	end
end