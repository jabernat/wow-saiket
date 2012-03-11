--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Overlay.lua - Module to show and manipulate map overlays.   *
  ****************************************************************************]]


local Tools = select( 2, ... );
local Overlay = _NPCScan.Overlay;
local NS = CreateFrame( "Frame", nil, WorldMapDetailFrame );
Tools.Overlay = NS;

NS.Control = CreateFrame( "Button", nil, nil, "UIPanelButtonTemplate" );

local POINT_SIZE = 8;
local POINT_COLOR = { r = 1.0; g = 0.1; b = 1.0; }; -- Purple




do
	local COORD_MAX = 2 ^ 16 - 1;
	local X, X2, Y, Y2;
	--- Draws an NPC's points from WowHead on the worldmap.
	local function PaintPoints ( self, Points, R, G, B )
		local Width, Height = self:GetSize();
		for Index = 1, #Points, 4 do
			X, X2, Y, Y2 = Points:byte( Index, Index + 3 );
			X, Y = ( X * 256 + X2 ) / COORD_MAX, ( Y * 256 + Y2 ) / COORD_MAX;

			local Texture = Overlay.TextureCreate( self, "OVERLAY", R, G, B );
			Texture:SetTexture( [[Interface\OPTIONSFRAME\VoiceChat-Record]] );
			Texture:SetTexCoord( 0, 1, 0, 1 );
			Texture:SetSize( POINT_SIZE, POINT_SIZE );
			Texture:SetPoint( "CENTER", self, "TOPLEFT", X * Width, -Y * Height );
		end
	end
	--- Throttles repaints to once per frame.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );
		local NpcID, _, MapID, Floor = Tools:GetSelectedNPC();
		local MapIDCurrent, FloorCurrent = GetCurrentMapAreaID(), GetCurrentMapDungeonLevel();
		if ( self.NpcID == NpcID and self.MapID == MapIDCurrent and self.Floor == FloorCurrent ) then
			return; -- Already rendered this map
		end
		self.NpcID, self.MapID, self.Floor = NpcID, MapIDCurrent, FloorCurrent;

		Overlay.TextureRemoveAll( self );
		if ( self.MapID ~= MapID or self.Floor ~= Floor ) then
			return; -- Viewing wrong map
		end
		local Points = Tools.NPCData.MapData[ MapID ][ Floor ][ NpcID ];
		if ( Points ) then
			PaintPoints( self, Points, POINT_COLOR.r, POINT_COLOR.g, POINT_COLOR.b );
		end
	end
	--- Draws points on the map for where this NPC was spotted by WowHead.
	function NS:Paint ()
		self:SetScript( "OnUpdate", OnUpdate );
	end
end
NS.OnShow = NS.Paint;
NS.WORLD_MAP_UPDATE = NS.Paint;


--- Validates that the selected NPC's map can be shown.
function NS:OnSelectNPC ( _, NpcID, _, MapID )
	if ( MapID and MapID ~= 0 ) then
		self:Show();
		self.Control:Enable();
	else
		self:Hide();
		self.Control:Disable();
	end
	if ( MapID and WorldMapFrame:IsShown() ) then
		if ( MapID == 0 ) then
			SetMapZoom( WORLDMAP_COSMIC_ID ); -- Mapless NPC
		else
			self.Control:OnClick(); -- View map
		end
	end
	self:Paint();
end
--- Shows the selected NPC's map.
function NS.Control:OnClick ()
	ShowUIPanel( WorldMapFrame, true );
	local _, _, MapID, Floor = Tools:GetSelectedNPC();
	SetMapByID( MapID );
	SetDungeonMapLevel( Floor );
end




NS:Hide();
NS:SetAllPoints();
NS:SetScript( "OnShow", NS.OnShow );
NS:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
NS:RegisterEvent( "WORLD_MAP_UPDATE" );

local Control = NS.Control;
Control:SetText( Tools.L.OVERLAY_CONTROL );
Control:SetSize( Control:GetTextWidth() + 16, 21 );
Control:SetScript( "OnClick", Control.OnClick );

Tools:AddControl( Control );
Tools.RegisterCallback( NS, "OnSelectNPC" );
NS:OnSelectNPC( nil, Tools:GetSelectedNPC() );