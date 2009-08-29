--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.lua - Adds mob patrol paths to your map.                  *
  ****************************************************************************]]


local _NPCScan = _NPCScan;
local me = {};
_NPCScan.Overlay = me;

local ADDON_NAME = "_NPCScan.Overlay";
me.Version = GetAddOnMetadata( ADDON_NAME, "Version" ):match( "^([%d.]+)" );

me.Options = {
	Version = me.Version;
	Modules = {};
	ModulesAlpha = {};
};

me.OptionsDefault = {
	Version = me.Version;
	Modules = {};
	ModulesAlpha = {};
};


me.Modules = {};
me.ModuleInitializers = {}; -- [ ParentAddOn ] = Module;

me.NPCMaps = {}; -- [ NpcID ] = MapName;
me.NPCsEnabled = {};

me.Colors = {
	RAID_CLASS_COLORS.SHAMAN,
	RAID_CLASS_COLORS.DEATHKNIGHT,
	GREEN_FONT_COLOR,
	RAID_CLASS_COLORS.DRUID,
	RAID_CLASS_COLORS.PALADIN,
};

local TexturesUnused = CreateFrame( "Frame" );

local MESSAGE_ADD = "NpcOverlay_Add";
local MESSAGE_REMOVE = "NpcOverlay_Remove";




--[[****************************************************************************
  * Function: _NPCScan.Overlay:TextureCreate                                   *
  * Description: Prepares an unused texture on the given frame.                *
  ****************************************************************************]]
function me:TextureCreate ( Layer, R, G, B )
	local Texture = #TexturesUnused > 0 and TexturesUnused[ #TexturesUnused ];
	if ( Texture ) then
		TexturesUnused[ #TexturesUnused ] = nil;
		Texture:SetParent( self );
		Texture:SetDrawLayer( Layer );
		Texture:ClearAllPoints();
		Texture:Show();
	else
		Texture = self:CreateTexture( nil, Layer );
	end
	Texture:SetVertexColor( R, G, B );

	self[ #self + 1 ] = Texture;
	return Texture;
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:TextureAdd                                      *
  * Description: Draw a triangle texture with vertices at relative coords.     *
  ****************************************************************************]]
do
	local ApplyTransform;
	local Texture;
	do
		local Det, AF, BF, CD, CE;
		local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy;
		function ApplyTransform( A, B, C, D, E, F )
			Det = A * E - B * D;
			AF, BF, CD, CE = A * F, B * F, C * D, C * E;

			ULx, ULy = ( BF - CE ) / Det, ( CD - AF ) / Det;
			LLx, LLy = ( BF - CE - B ) / Det, ( CD - AF + A ) / Det;
			URx, URy = ( BF - CE + E ) / Det, ( CD - AF - D ) / Det;
			LRx, LRy = ( BF - CE + E - B ) / Det, ( CD - AF - D + A ) / Det;

			-- Bounds to prevent "TexCoord out of range" errors
			if ( ULx < -1e4 ) then ULx = -1e4; elseif ( ULx > 1e4 ) then ULx = 1e4; end
			if ( ULy < -1e4 ) then ULy = -1e4; elseif ( ULy > 1e4 ) then ULy = 1e4; end
			if ( LLx < -1e4 ) then LLx = -1e4; elseif ( LLx > 1e4 ) then LLx = 1e4; end
			if ( LLy < -1e4 ) then LLy = -1e4; elseif ( LLy > 1e4 ) then LLy = 1e4; end
			if ( URx < -1e4 ) then URx = -1e4; elseif ( URx > 1e4 ) then URx = 1e4; end
			if ( URy < -1e4 ) then URy = -1e4; elseif ( URy > 1e4 ) then URy = 1e4; end
			if ( LRx < -1e4 ) then LRx = -1e4; elseif ( LRx > 1e4 ) then LRx = 1e4; end
			if ( LRy < -1e4 ) then LRy = -1e4; elseif ( LRy > 1e4 ) then LRy = 1e4; end

			Texture:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
		end
	end
	local MinX, MinY, WindowX, WindowY;
	local ABx, ABy, BCx, BCy;
	local ScaleX, ScaleY, ShearFactor, Sin, Cos;
	local Parent, Width, Height;
	local BorderScale, BorderOffset = 256 / 254, -1 / 256; -- Removes one-pixel transparent border
	function me:TextureAdd ( Layer, R, G, B, Ax, Ay, Bx, By, Cx, Cy )
		--[[ Transform parallelogram so its corners lie on the tri's points:
		1. Translate by BorderOffset to hide top and left transparent borders.
		2. Scale by BorderScale to push bottom and left transparent borders out.
		3. Scale to counter the effects of resizing the image.
		4. Translate to negate moving the image region relative to its parent.
		5. Rotate so point A lies on a line parallel to line BC.
		6. Scale X by the length of line BC, and Y by the length of the perpendicular line from BC to point A.
		7. Shear the image so its bottom left corner aligns with point A.
		]]
		ABx, ABy, BCx, BCy = Ax - Bx, Ay - By, Bx - Cx, By - Cy;
		ScaleX = ( BCx * BCx + BCy * BCy ) ^ 0.5;
		if ( ScaleX == 0 ) then
			return;
		end
		ScaleY = ( ABx * BCy - BCx * ABy ) / ScaleX;
		if ( ScaleY == 0 ) then
			return;
		end
		ShearFactor = -( ABx * BCx + ABy * BCy ) / ( ScaleX * ScaleX );
		Sin, Cos = BCy / ScaleX, -BCx / ScaleX;


		-- Get a texture
		Texture = me.TextureCreate( self, Layer, R, G, B );
		Texture:SetTexture( [[Interface\AddOns\_NPCScan.Overlay\Skin\Triangle]] );


		-- Note: The texture region is made as small as possible to improve framerates.
		MinX, MinY = min( Ax, Bx, Cx ), min( Ay, By, Cy );
		WindowX = max( Ax, Bx, Cx ) - MinX;
		WindowY = max( Ay, By, Cy ) - MinY;

		Width, Height = self:GetWidth(), self:GetHeight();
		Texture:SetPoint( "TOPLEFT", MinX * Width, -MinY * Height );
		Texture:SetWidth( WindowX * Width );
		Texture:SetHeight( WindowY * Height );

		WindowX = BorderScale / WindowX;
		WindowY = BorderScale / WindowY;
		ApplyTransform(
			WindowX * Cos * ScaleX,
			WindowX * ( Cos * ScaleX * ShearFactor + Sin * ScaleY ),
			WindowX * ( Bx - MinX ) + BorderOffset,
			WindowY * -Sin * ScaleX,
			WindowY * ( Cos * ScaleY - Sin * ScaleX * ShearFactor ),
			WindowY * ( By - MinY ) + BorderOffset );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:TextureRemoveAll                                *
  * Description: Removes all triangle textures from a frame.                   *
  ****************************************************************************]]
function me:TextureRemoveAll ()
	for Index = #self, 1, -1 do
		local Texture = self[ Index ];
		self[ Index ] = nil;
		Texture:Hide();
		Texture:SetParent( TexturesUnused );
		TexturesUnused[ #TexturesUnused + 1 ] = Texture;
	end
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay:PathAdd                                         *
  * Description: Draws the given NPC's path onto a frame.                      *
  ****************************************************************************]]
do
	local Max = 2 ^ 16 - 1;
	local Ax1, Ax2, Ay1, Ay2, Bx1, Bx2, By1, By2, Cx1, Cx2, Cy1, Cy2;
	function me:PathAdd ( PathData, Layer, R, G, B )
		for Index = 1, #PathData, 12 do
			Ax1, Ax2, Ay1, Ay2, Bx1, Bx2, By1, By2, Cx1, Cx2, Cy1, Cy2 = PathData:byte( Index, Index + 11 );
			me.TextureAdd( self, Layer, R, G, B,
				( Ax1 * 256 + Ax2 ) / Max, ( Ay1 * 256 + Ay2 ) / Max,
				( Bx1 * 256 + Bx2 ) / Max, ( By1 * 256 + By2 ) / Max,
				( Cx1 * 256 + Cx2 ) / Max, ( Cy1 * 256 + Cy2 ) / Max );
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.ApplyZone                                       *
  * Description: Passes the NpcID, color, PathData, ZoneWidth, and ZoneHeight  *
  *   of all NPCs in a zone to a callback function.                            *
  ****************************************************************************]]
function me.ApplyZone ( Map, Callback )
	local MapData = me.PathData[ Map ];
	if ( MapData ) then
		local ColorIndex = 0;

		for NpcID, PathData in pairs( MapData ) do
			ColorIndex = ColorIndex + 1;
			if ( me.NPCsEnabled[ NpcID ] ) then
				local Color = me.Colors[ ( ColorIndex - 1 ) % #me.Colors + 1 ];
				Callback( PathData, Color.r, Color.g, Color.b, NpcID );
			end
		end
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.ModuleRegister                                  *
  * Description: Registers a canvas module to paint polygons on.               *
  ****************************************************************************]]
function me.ModuleRegister ( Name, Module, ParentAddon )
	me.Modules[ Name ] = Module;
	local Config = me.Config.ModuleRegister( Name, Module.Label );

	if ( ParentAddon ) then
		if ( select( 6, GetAddOnInfo( ParentAddon ) ) == "MISSING" ) then
			me.ModuleUnregister( Name );
		elseif ( IsAddOnLoaded( ParentAddon ) ) then
			Module:OnLoad();
			Module.OnLoad = nil;
		else
			me.ModuleInitializers[ ParentAddon:upper() ] = Module;
		end
	end
	return Config;
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.ModuleUnregister                                *
  * Description: Disables the module for the session and disables its          *
  *   configuration controls.                                                  *
  ****************************************************************************]]
function me.ModuleUnregister ( Name )
	local Config = me.Config.Modules[ Name ];
	if ( Config.Enabled:IsEnabled() == 1 ) then
		Config.Enabled:SetEnabled( false );

		local Module = me.Modules[ Name ];
		if ( me.Options.Modules[ Name ] ) then
			for _, Control in ipairs( Config ) do
				Control:SetEnabled( false );
			end
			if ( Module.Disable ) then
				Module:Disable();
			end
		end

		Module.Update = nil;
		Module.Enable = nil;
		Module.Disable = nil;
		return true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.ModuleEnable                                    *
  ****************************************************************************]]
function me.ModuleEnable ( Name )
	if ( not me.Options.Modules[ Name ] ) then
		me.Options.Modules[ Name ] = true;

		local Config = me.Config.Modules[ Name ];
		Config.Enabled:SetChecked( true );
		if ( Config.Enabled:IsEnabled() == 1 ) then -- Still registered
			local Module = me.Modules[ Name ];
			for _, Control in ipairs( Config ) do
				Control:SetEnabled( true );
			end
			if ( Module.Enable ) then
				Module:Enable();
			end
			if ( Module.Update ) then
				Module:Update();
			end
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.ModuleDisable                                   *
  ****************************************************************************]]
function me.ModuleDisable ( Name )
	local Enabled = me.Options.Modules[ Name ];
	if ( Enabled ~= false ) then -- True or nil, which defaults to enabled
		me.Options.Modules[ Name ] = false;

		local Config = me.Config.Modules[ Name ];
		for _, Control in ipairs( Config ) do
			Control:SetEnabled( false );
		end

		if ( Enabled ~= nil ) then -- Was previously enabled
			Config.Enabled:SetChecked( false );
			if ( Config.Enabled:IsEnabled() == 1 and me.Modules[ Name ].Disable ) then -- Still registered
				me.Modules[ Name ]:Disable();
			end
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.ModuleSetAlpha                                  *
  ****************************************************************************]]
function me.ModuleSetAlpha ( Name, Alpha )
	if ( Alpha ~= me.Options.ModulesAlpha[ Name ] ) then
		me.Options.ModulesAlpha[ Name ] = Alpha;

		me.Config.Modules[ Name ].Alpha:SetValue( Alpha );
		me.Modules[ Name ]:SetAlpha( Alpha );
		return true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:ADDON_LOADED                                    *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, Addon )
	Addon = Addon:upper(); -- For case insensitive file systems (Windows')
	local Module = me.ModuleInitializers[ Addon ];
	if ( Module ) then
		me.ModuleInitializers[ Addon ] = nil;
		Module:OnLoad();
		Module.OnLoad = nil;
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.NPCAdd                                          *
  ****************************************************************************]]
function me.NPCAdd ( NpcID )
	local Map = me.NPCMaps[ NpcID ];
	if ( Map and not me.NPCsEnabled[ NpcID ] ) then
		me.NPCsEnabled[ NpcID ] = true;

		for Name in pairs( me.Options.Modules ) do
			local Module = me.Modules[ Name ];
			if ( Module.Update ) then
				Module:Update( Map );
			end
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.NPCRemove                                       *
  ****************************************************************************]]
function me.NPCRemove ( NpcID )
	if ( me.NPCsEnabled[ NpcID ] ) then
		me.NPCsEnabled[ NpcID ] = nil;

		local Map = me.NPCMaps[ NpcID ];
		for Name in pairs( me.Options.Modules ) do
			local Module = me.Modules[ Name ];
			if ( Module.Update ) then
				Module:Update( Map );
			end
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay[ MESSAGE_ADD ]                                  *
  ****************************************************************************]]
me[ MESSAGE_ADD ] = function ( _, _, NpcID )
	me.NPCAdd( NpcID );
end;
--[[****************************************************************************
  * Function: _NPCScan.Overlay[ MESSAGE_REMOVE ]                               *
  ****************************************************************************]]
me[ MESSAGE_REMOVE ] = function ( _, _, NpcID )
	me.NPCRemove( NpcID );
end;




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Synchronize                                     *
  * Description: Reloads enabled modules from saved settings.                  *
  ****************************************************************************]]
function me.Synchronize ( Options )
	-- Load defaults if settings omitted
	if ( not Options ) then
		Options = me.OptionsDefault;
	end

	for Name, Module in pairs( me.Modules ) do
		if ( Options.Modules[ Name ] ~= false ) then -- New modules (nil) default to enabled
			me.ModuleEnable( Name );
		else
			me.ModuleDisable( Name );
		end
		me.ModuleSetAlpha( Name, Options.ModulesAlpha[ Name ] or Module.AlphaDefault );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay:OnLoad                                          *
  ****************************************************************************]]
function me:OnLoad ()
	-- Build a reverse lookup of NPC IDs to zones
	for Map, MapData in pairs( me.PathData ) do
		for NpcID in pairs( MapData ) do
			me.NPCMaps[ NpcID ] = Map;
		end
	end

	local Options = _NPCScanOverlayOptions;
	_NPCScanOverlayOptions = me.Options;

	me.Synchronize( Options ); -- Loads defaults if nil

	me:RegisterMessage( MESSAGE_ADD );
	me:RegisterMessage( MESSAGE_REMOVE );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	LibStub( "AceEvent-3.0" ):Embed( me );
	me:RegisterEvent( "ADDON_LOADED" );

	me.ModuleInitializers[ ADDON_NAME:upper() ] = me;
end
