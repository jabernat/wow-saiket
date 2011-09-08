--[[****************************************************************************
  * GridStatusHealthFade by Saiket (Originally by North101)                    *
  * GridStatusHealthFade.lua - Adds a health status that fades from one color  *
  *   at max health to another at no health.                                   *
  ****************************************************************************]]


local L = select( 2, ... ).L;
local NS = Grid:GetModule( "GridStatus" ):NewModule( "GridStatusHealthFade" );

local STATUS_ID = "alert_healthFade";

NS.ColorTables = {};

NS.menuName = L.TITLE;
NS.options = false;

NS.defaultDB = {
	debug = false;
	[ STATUS_ID ] = {
		text = L.TITLE;
		enable = true;
		priority = 1;
		range = false;
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
	};
	local Count = 0;
	--- Shortcut to add a color picker to the options table.
	local function AddColorPicker ( Property, Name, Description )
		Count = Count + 1;
		Options[ Property ] = {
			type = "color"; hasAlpha = true; order = Count;
			name = Name; desc = Description;
			get = ColorGet; set = ColorSet;
		};
	end
	--- Registers the HealthFade status and its options with Grid OnLoad.
	function NS:OnInitialize ()
		self.super.OnInitialize( self );
		AddColorPicker( "ColorHigh", L.COLOR_HIGH, L.COLOR_HIGH_DESC );
		AddColorPicker( "ColorLow", L.COLOR_LOW, L.COLOR_LOW_DESC );
		self:RegisterStatus( STATUS_ID, L.TITLE, Options, true );
	end
end
--- Called when this status is enabled and used.
function NS:OnStatusEnable ( Status )
	if ( Status == STATUS_ID ) then
		self:RegisterMessage( "Grid_UnitJoined", "UpdateUnit" );
		self:RegisterMessage( "Grid_UnitLeft", "RemoveUnit" );
		self:RegisterMessage( "Grid_UnitChanged", "UpdateUnit" );
		self:RegisterEvent( "UNIT_HEALTH" );
		self:RegisterEvent( "UNIT_MAXHEALTH" );
		self:UpdateAllUnits();
	end
end
--- Called when this status gets disabled or becomes unused.
function NS:OnStatusDisable ( Status )
	if ( Status == STATUS_ID ) then
		self:UnregisterAllEvents();
		self:UnregisterAllMessages();
		self.core:SendStatusLostAllUnits( STATUS_ID );
		wipe( NS.ColorTables );
	end
end
--- Completely reinitializes the status.
function NS:Reset ()
	self.super.Reset( self );
	self:UpdateAllUnits();
end




do
	local UnitGUID = UnitGUID;
	--- Update status when health changes.
	function NS:UNIT_HEALTH( Event, UnitID )
		self:UpdateUnit( Event, UnitGUID( UnitID ), UnitID );
	end

	--- Update status when max health changes.
	function NS:UNIT_MAXHEALTH( Event, UnitID )
		self:UpdateUnit( Event, UnitGUID( UnitID ), UnitID );
	end
end


--- When a unit leaves the raid, removes its color table from the cache.
function NS:RemoveUnit ( Event, GUID, UnitID )
	NS.ColorTables[ GUID ] = nil;
end
do
	local GridRoster = Grid:GetModule( "GridRoster" );
	--- Fully updates all active units.
	function NS:UpdateAllUnits ()
		for GUID, UnitID in GridRoster:IterateRoster() do
			self:UpdateUnit( nil, GUID, UnitID );
		end
	end
end
do
	local UnitHealth = UnitHealth;
	local UnitHealthMax = UnitHealthMax;
	local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
	local ceil = ceil;
	--- Updates or removes the health fade status for a given unit.
	function NS:UpdateUnit( Event, GUID, UnitID, ... )
		local Settings = self.db.profile[ STATUS_ID ];

		local HealthMax = UnitHealthMax( UnitID );
		local Percentage;
		if ( HealthMax == 0 ) then -- Unknown (offline, etc.)
			Percentage = 1;
		elseif ( UnitIsDeadOrGhost( UnitID ) ) then
			Percentage = 0; -- Keep label from rounding up to 1%
		else
			Percentage = UnitHealth( UnitID ) / HealthMax;
		end

		local Color = NS.ColorTables[ GUID ];
		if ( not Color ) then
			Color = {};
			NS.ColorTables[ GUID ] = Color;
		end
		local High, Low = Settings.ColorHigh, Settings.ColorLow;
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
			Settings.priority,
			( Settings.range and 40 ),
			Color,
			Health ~= 0 and L.LABEL_FORMAT:format( ceil( Percentage * 100 ) ),
			Percentage, 1,
			Settings.icon );
	end
end