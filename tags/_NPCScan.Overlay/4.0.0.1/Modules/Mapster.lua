--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Modules/Mapster.lua - Adjusts WorldMap module with Mapster.                *
  ****************************************************************************]]


if ( not IsAddOnLoaded( "Mapster" ) ) then
	return;
end

local AddOnName, Overlay = ...;
local WorldMap = Overlay.Modules.List[ "WorldMap" ];
if ( not ( WorldMap and WorldMap.Registered ) ) then
	return;
end
local Mapster = LibStub( "AceAddon-3.0" ):GetAddon( "Mapster" );
local me = Mapster:NewModule( AddOnName );
Overlay.Modules.Mapster = me;




--- Moves the checkbox so it doesn't overlap Mapster's stuff.
local function UpdateMapsize ( self, Mini )
	WorldMap.Toggle:ClearAllPoints();
	WorldMap.Toggle:SetPoint( "BOTTOM", WorldMapTrackQuest );
	if ( Mini ) then -- Right side so coordinates don't overlap
		local Label = _G[ WorldMap.Toggle:GetName().."Text" ];
		WorldMap.Toggle:SetPoint( "RIGHT", WorldMapDetailFrame, -Label:GetStringWidth() - 4, 0 );
	else -- Left side, between "Track Quests" and player coordinates
		local Label = _G[ WorldMapTrackQuest:GetName().."Text" ];
		WorldMap.Toggle:SetPoint( "LEFT", WorldMapTrackQuest, "RIGHT", Label:GetStringWidth() + 8, -4 );
	end
end
--- Fired when both modules are enabled at the same time.
local function Enable ( self )
	self.UpdateMapsize = UpdateMapsize;
	self:UpdateMapsize( Mapster.miniMap );
	WorldMap.Toggle:Show();
end
--- Hides the toggle button if either the Overlay or Mapster modules are disabled.
local function Disable ( self )
	self.UpdateMapsize = nil;
	WorldMap.Toggle:Hide();
end




--- Fired when Mapster module gets enabled.
function me:OnEnable ()
	self.Enabled = true;
	if ( WorldMap.Loaded ) then
		Enable( self );
	end
end
--- Fired when Mapster module gets disabled.
function me:OnDisable ()
	self.Enabled = nil;
	if ( WorldMap.Loaded ) then
		Disable( self );
	end
end
do
	local function WorldMapOnUnload ()
		if ( me.Enabled ) then
			Disable( me );
		end
		me.OnEnable, me.OnDisable = nil;
	end
	local function WorldMapOnLoad ()
		if ( me.Enabled ) then
			Enable( me );
		end
	end

	--- Sets a module's handler, or hooks the old one if it exists.
	local function HookHandler ( Name, Handler )
		local Backup = WorldMap[ Name ];
		WorldMap[ Name ] = not Backup and Handler or function ( ... )
			Backup( ... );
			Handler( ... );
		end;
	end
	--- Fired when Mapster module gets loaded.
	function me:OnInitialize ()
		self.OnInitialize = nil;

		self:SetEnabledState( true );
		if ( WorldMap.Loaded ) then
			WorldMapOnLoad();
		else
			HookHandler( "OnLoad", WorldMapOnLoad );
		end
		HookHandler( "OnUnload", WorldMapOnUnload );
	end
end