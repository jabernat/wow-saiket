--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Overlay.lua - _NPCScan.Overlay module to show mob map data. *
  ****************************************************************************]]


local Routes = LibStub( "AceAddon-3.0" ):GetAddon( "Routes" );
local Tools = select( 2, ... );
local Overlay = _NPCScan.Overlay;
local me = Overlay.Modules.WorldMapTemplate.Embed( CreateFrame( "Frame", nil, WorldMapDetailFrame ) );
Tools.Overlay = me;

me.Control = CreateFrame( "Button", nil, nil, "UIPanelButtonTemplate" );

me.AlphaDefault = 1;




do
	local MapCurrent;
	local Max = 2 ^ 16 - 1;
	local X, X2, Y, Y2;
	local SelectionDrawn;
	--- Draws an NPC's points from WowHead on the worldmap.
	local function PaintPoints ( self, _, _, _, R, G, B, NpcID )
		if ( self.NpcID == NpcID ) then
			SelectionDrawn = true;
			local Data = Tools.NPCPointData[ NpcID ];
			if ( Data ) then
				local Width, Height = self:GetSize();
				for Index = 1, #Data, 4 do
					X, X2, Y, Y2 = Data:byte( Index, Index + 3 );
					X, Y = ( X * 256 + X2 ) / Max, ( Y * 256 + Y2 ) / Max;

					local Texture = Overlay.TextureCreate( self, "OVERLAY", R, G, B );
					Texture:SetTexture( [[Interface\OPTIONSFRAME\VoiceChat-Record]] );
					Texture:SetTexCoord( 0, 1, 0, 1 );
					Texture:SetSize( 8, 8 );
					Texture:SetPoint( "CENTER", self, "TOPLEFT", X * Width, -Y * Height );
				end
			end
		end
	end
	--- Draws points on the map for where this NPC was spotted by WowHead.
	function me:Paint ( Map )
		Overlay.TextureRemoveAll( self );
		if ( Map and self.MapID == Map ) then
			MapCurrent, SelectionDrawn = Map, false;
			Overlay.ApplyZone( self, Map, PaintPoints );
			if ( not SelectionDrawn ) then
				-- _NPCScan.Overlay has no data on mob, and therefore no assigned color
				local Color = HIGHLIGHT_FONT_COLOR;
				PaintPoints( self, nil, nil, nil, Color.r, Color.g, Color.b, self.NpcID );
			end
		end
	end
end




--- Enables or disables paths for NpcID on MapFile.
function me.SetRoutesEnabled ( MapFile, NpcID, Enable )
	local RoutesDB = Routes.db.global.routes[ MapFile ];
	if ( RoutesDB ) then
		for Name, Route in pairs( RoutesDB ) do
			local CurrentNpcID = tonumber( Name:match( "^Overlay:([^:]+)" ) );
			if ( CurrentNpcID == NpcID ) then -- Path of selected mob
				Route.hidden = not Enable;
				Routes:DrawWorldmapLines();
				Routes:DrawMinimapLines( true );
			end
		end
	end
end
do
	-- Extract alias MapFiles used by Routes for phased terrain
	local MapFiles = {}; -- [ MapID ] = MapFile;
	for _, Data in pairs( Routes.LZName ) do
		MapFiles[ Data[ 2 ] ] = Data[ 1 ];
	end
	--- Validates that the selected NPC's map can be shown.
	function me.Control:OnSelect ( NpcID )
		if ( me.MapFile ) then
			-- Re-hide routes for last shown mob
			me.SetRoutesEnabled( me.MapFile, me.NpcID, false );
			me:OnMapUpdate( me.MapID );
			me.MapFile = nil;
		end

		me.NpcID, me.MapID = NpcID, Tools.NPCMapIDs[ NpcID ];
		if ( me.MapID ) then
			-- Show routes for this mob
			me.MapFile = MapFiles[ me.MapID ];
			me.SetRoutesEnabled( me.MapFile, me.NpcID, true );
			me:OnMapUpdate( me.MapID );

			self:Enable();
			me:Show();
		else
			self:Disable();
			me:Hide();
		end
	end
end
--- Shows the selected NPC's map.
function me.Control:OnClick ()
	ShowUIPanel( WorldMapFrame, true );
	SetMapByID( me.MapID );
end
--- Hides shown routes on logout.
function me:PLAYER_LOGOUT ()
	self.Control:OnSelect();
end




me:Hide();
me:RegisterEvent( "PLAYER_LOGOUT" );
Overlay.Modules.Register( ..., me, Tools.L.OVERLAY_TITLE );

local Control = me.Control;
Control:SetSize( 144, 21 );
Control:SetText( Tools.L.OVERLAY_CONTROL );
Control:SetScript( "OnClick", Control.OnClick );

Tools.Config.Controls:Add( Control );