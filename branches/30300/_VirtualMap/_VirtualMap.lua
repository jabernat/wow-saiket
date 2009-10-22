--[[****************************************************************************
  * _VirtualMap by Saiket, a modification of GatherHud by Grum and Xinhuan     *
  ****************************************************************************]]


local GatherMate = GatherMate;

local me = setmetatable( LibStub( "AceAddon-3.0" ):NewAddon( "_VirtualMap", "AceEvent-3.0" ), { __index = CreateFrame( "Frame", "_VirtualMap", UIParent ) } );
me[ 0 ] = me[ 0 ]; -- Copy userdata from metatable
local L = _VirtualMapLocalization;

local NodeTextures = GatherMate.nodeTextures;
me.NodeTextures = NodeTextures;

me.Pitch    = 0;
me.Yaw      = 0;
me.Distance = 0;


local HUD = CreateFrame( "Frame", nil, me );
me.HUD = HUD;
local PlayerIcon = CreateFrame( "Frame", nil, HUD );
HUD.PlayerIcon = PlayerIcon;
PlayerIcon.Texture = PlayerIcon:CreateTexture( nil, "ARTWORK" );
PlayerIcon.TextureHalo = PlayerIcon:CreateTexture( nil, "ARTWORK" );
local Border = CreateFrame( "Frame", nil, HUD );
HUD.Border = Border;
Border.Texture = Border:CreateTexture( nil, "ARTWORK" );
Border.TextureHalo = Border:CreateTexture( nil, "ARTWORK" );
local NorthIndicator = CreateFrame( "Frame", nil, HUD );
HUD.NorthIndicator = NorthIndicator;
HUD.NorthIndicator.Text = HUD.NorthIndicator:CreateFontString( nil, "ARTWORK", "GameFontNormalHuge" );

local PinsActive = {}; -- Pins in use
HUD.PinsActive = PinsActive;
local PinsInactive = {};
HUD.PinsInactive = PinsInactive;


local DB;
me.Defaults = {
	global = {
		settings = {
			Enabled = true;

			HUDScale  = 1;
			HUDWidth  = 800;
			HUDX      = 0;
			HUDY      = 0;
			HUDAlpha  = 1;
			Radius    = 1000;
			LookAhead = 85;

			IconSize     = 16;
			IconDepth    = 0.5;
			IconAlpha    = 1.0;
		};
	};
};
me.Options = { order = 190;
	name = L.TITLE;
	type = "group";
	get = function( Key )
		return DB.settings[ Key.arg ];
	end;
	set = function( Key, Value )
		DB.settings[ Key.arg ] = Value;
		me.ForceUpdate = true;
	end;
	args = {
		Description = { order = 0;
			name = L.DESC;
			type = "description";
		};
		Enabled = { order = 1;
			name = L.ENABLE; desc = L.ENABLE_DESC;
			arg = "Enabled"; type = "toggle";
			set = function( _, Enable )
				DB.settings.Enabled = Enable;
				if ( Enable ) then
					me:Enable();
				else
					me:Disable();
				end
			end;
			disabled = false;
		};
		HUDGroup = { order = 10;
			name = L.HUDGROUP; desc = L.HUDGROUP_DESC;
			type = "group"; inline = true;
			disabled = function ()
				return not me:IsEnabled();
			end;
			args = {
				HUDX = { order = 10;
					name = L.HUDX; desc = L.HUDX_DESC;
					arg = "HUDX"; type = "range"; min = -800; max = 800; step = 1;
					set = function( _, X )
						DB.settings.HUDX = X;
						HUD:SetPoint( "CENTER", UIParent, X, DB.settings.HUDY );
					end;
				};
				HUDY = { order = 20;
					name = L.HUDY; desc = L.HUDY_DESC;
					arg = "HUDY"; type = "range"; min = -600; max = 600; step = 1;
					set = function( _, Y )
						DB.settings.HUDY = HudY;
						HUD:SetPoint( "CENTER", UIParent, DB.settings.HUDX, Y );
					end;
				};
				HUDWidth = { order = 30;
					name = L.HUDWIDTH; desc = L.HUDWIDTH_DESC;
					arg = "HUDWidth"; type = "range"; min = 1; max = 1600; step = 1;
					set = function( _, Width )
						DB.settings.HUDWidth = Width;
						HUD:SetWidth( Width );
						Border.TextureHalo:SetWidth( Width * 544 / 512 );
						me.ForceUpdate = true;
					end;
				};
				HUDAlpha = { order = 40;
					name = L.HUDALPHA; desc = L.HUDALPHA_DESC;
					arg = "HUDAlpha"; type = "range"; min = 0.25; max = 1; step = 0.01;
				};
				Radius = { order = 60;
					name = L.RADIUS; desc = L.RADIUS_DESC;
					arg = "Radius"; type = "range"; min = 1; max = 3600; step = 1;
					set = function( _, Radius )
						DB.settings.Radius = Radius;
						me.ForceUpdate = true;
						me.NextDataUpdate = 0;
					end;
				};
			};
		};
		IconGroup = { order = 20;
			name = L.ICONGROUP; desc = L.ICONGROUP_DESC;
			type = "group"; inline = true;
			disabled = function ()
				return not me:IsEnabled();
			end;
			args = {
				IconSize = { order = 70;
					name = L.ICONSIZE; desc = L.ICONSIZE_DESC;
					arg = "IconSize"; type = "range"; min = 1; max = 32; step = 1;
					set = function( _, Size )
						DB.settings.IconSize = Size;
						PlayerIcon:SetWidth( Size );
						PlayerIcon.TextureHalo:SetWidth( Size * 80 / 64 );
						me.ForceUpdate = true;
					end;
				};
				IconDepth = { order = 80;
					name = L.ICONDEPTH; desc = L.ICONDEPTH_DESC;
					arg = "IconDepth"; type = "range"; min = 0; max = 1; step = 0.01;
				};
				IconAlpha = { order = 90;
					name = L.ICONALPHA; desc = L.ICONALPHA_DESC;
					arg = "IconAlpha"; type = "range"; min = 0; max = 1; step = 0.01;
				};
			};
		};
	};
};

-- Enumerated pin constants as table keys to reduce memory
local PIN_X, PIN_Y, PIN_DEPTH, PIN_KEEP, PIN_TEXTURE = 1, 2, 3, 4, 5;




--[[****************************************************************************
  * Function: _VirtualMap.Toggle                                               *
  * Description: Toggles the mod enabled or disabled.                          *
  ****************************************************************************]]
function me.Toggle ( Enable )
	if ( Enable == nil ) then
		Enable = not me:IsEnabled();
	end

	DB.settings.Enabled = Enable;
	if ( Enable ) then
		me:Enable();
	else
		me:Disable();
	end
end
--[[****************************************************************************
  * Function: _VirtualMap:OnEnable                                             *
  * Description: Called when the addon is enabled.                             *
  ****************************************************************************]]
function me:OnEnable ()
	if ( DB.settings.Enabled ) then
		HUD:SetPoint( "CENTER", UIParent, DB.settings.HUDX, DB.settings.HUDY );
		HUD:SetWidth( DB.settings.HUDWidth );
		PlayerIcon:SetWidth( DB.settings.IconSize );

		-- Note: Image is 544x544, scaled to 512x512
		Border.TextureHalo:SetWidth( DB.settings.HUDWidth * 544 / 512 );
		PlayerIcon.TextureHalo:SetWidth( DB.settings.IconSize * 80 / 64 );

		me:Show();

		LibStub( "LibCamera-1.0" ).RegisterCallback( me, "LibCamera_Update", "UpdateCamera" );
	else
		me:Disable();
	end
end
--[[****************************************************************************
  * Function: _VirtualMap:OnDisable                                            *
  * Description: Hides the HUD and its updater.                                *
  ****************************************************************************]]
function me:OnDisable ()
	me:Hide();
	LibStub( "LibCamera-1.0" ).UnregisterCallback( me, "LibCamera_Update" );
end
--[[****************************************************************************
  * Function: _VirtualMap:UpdateCamera                                         *
  * Description: Updates the display from the camera's point of view.          *
  ****************************************************************************]]
function me:UpdateCamera ( Event, Pitch, Yaw, Distance )
	me.Pitch    = Pitch;
	me.Yaw      = Yaw;
	me.Distance = Distance;

	me.ForceUpdate = true;
end

--[[****************************************************************************
  * Function: _VirtualMap:OnInitialize                                         *
  * Description: Sets up options.                                              *
  ****************************************************************************]]
function me:OnInitialize ()
	me.DB = LibStub( "AceDB-3.0" ):New( "_VirtualMapOptions", me.Defaults );
	DB = me.DB.global;

	LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( "_VirtualMap", me.Options );

	-- Register our options table with GatherMate's Config
	GatherMate:GetModule( "Config" ):RegisterModule( "_VirtualMap", me.Options );

	self:RegisterMessage( "GatherMateConfigChanged", "UpdateFull" );
end




--[[****************************************************************************
  * Function: _VirtualMap.HUD:GetPin                                           *
  * Description: Gets (or creates) a pin frame.                                *
  ****************************************************************************]]
do
	local CreateFrame = CreateFrame;
	local next = next;

	local Pin, Texture;
	function HUD.GetPin( ID, Coord, IconPath )
		Pin = PinsActive[ ID ];
		if ( Pin ) then
			return Pin;
		end

		Pin = next( PinsInactive );
		if ( Pin ) then
			PinsInactive[ Pin ] = nil;
			Texture = Pin[ PIN_TEXTURE ];
		else -- No free pins
			Pin = CreateFrame( "Frame", nil, HUD );
			Texture = Pin:CreateTexture( nil, "ARTWORK" );
			Texture:SetAllPoints( Pin )
			Pin[ PIN_TEXTURE ] = Texture;
		end

		PinsActive[ ID ] = Pin;
		Texture:SetTexture( IconPath );
		Pin[ PIN_X ], Pin[ PIN_Y ] = GatherMate:getXY( Coord );

		return Pin;
	end
end




--[[****************************************************************************
  * Function: _VirtualMap.HUD.ShouldUpdate                                     *
  * Description: Returns true if the HUD should be visible and updated.        *
  ****************************************************************************]]
do
	local IsInInstance = IsInInstance;
	local InCombatLockdown = InCombatLockdown;
	local IsResting = IsResting;
	function HUD.ShouldUpdate ()
		return not ( IsInInstance() or InCombatLockdown() or IsResting() );
	end
end


--[[****************************************************************************
  * Function: _VirtualMap.Update                                               *
  * Description: Redraws the HUD view.                                         *
  ****************************************************************************]]
do
	local tinsert = table.insert;
	local sort = table.sort;
	local sin = math.sin;
	local cos = math.cos;
	local abs = math.abs;
	local max = math.max;
	local min = math.min;

	local DepthTable = {};
	local function DepthSort ( PinA, PinB )
		return PinA[ PIN_DEPTH ] > PinB[ PIN_DEPTH ];
	end

	local TextColor = NORMAL_FONT_COLOR;
	local Settings, Radius, HeightCompression, PitchCompression, Width, Height,
		Scale, Radius2, PinDepth, PinAlpha, ZoneWidth, ZoneHeight, CurrentX,
		CurrentY, CurrentSin, CurrentCos, Texture, dX, dY, PinX, PinY, Brightness,
		BrightnessFar, BorderLevel, DepthTop, PinOffset, PinBrightness, PinBrightnessFar;

	function me.Update ()
		if ( not ( me.Zone and me.PlayerX and me.PlayerY ) or me.Zone == "" or me.PlayerX == 0 or me.PlayerY == 0 ) then
			return;
		end

		Settings = DB.settings;

		Radius  = Settings.Radius;
		HeightCompression = sin( me.Pitch );
		PitchCompression = ( cos( me.Pitch ) < 0 and -1 or 1 ) * ( 1 - abs( HeightCompression ) );
		Width  = Settings.HUDWidth;
		Height = Width * HeightCompression;
		Scale = Width / ( Radius * 2 );
		Radius2 = Radius ^ 2;
		PinDepth = Settings.IconDepth * PitchCompression;
		PinAlpha = Settings.IconAlpha;
		local IconSize = Settings.IconSize;

		HUD:SetHeight( max( abs( Height ), 1 ) );
		HUD:SetScale( Settings.HUDScale * 50 / ( me.Distance * 2 ) ); -- Half size when fully zoomed out
		HUD:SetAlpha( Settings.HUDAlpha * min( me.Distance / 2, 1 ) ); -- Fade out when zoomed far in

		ZoneWidth = me.ZoneWidth;
		ZoneHeight = me.ZoneHeight;
		CurrentX = me.PlayerX * ZoneWidth;
		CurrentY = me.PlayerY * ZoneHeight;

		CurrentSin = sin( me.Yaw );
		CurrentCos = cos( me.Yaw );

		if ( PitchCompression > 0 ) then
			Brightness = 0.1 + 0.5 * ( HeightCompression + 1 );
			BrightnessFar = 0.1 + 0.5 * max( HeightCompression, 0 );
		else
			Brightness = 0.1 + 0.5 * max( HeightCompression, 0 );
			BrightnessFar = 0.1 + 0.5 * ( HeightCompression + 1 );
		end
		for ID, Pin in pairs( PinsActive ) do
			-- Delta + offset rotation
			dX = Pin[ PIN_X ] * ZoneWidth - CurrentX;
			dY = Pin[ PIN_Y] * ZoneHeight - CurrentY;

			PinX =  dX * CurrentCos - dY * CurrentSin;
			PinY = -dX * CurrentSin - dY * CurrentCos;

			if ( PinX * PinX + PinY * PinY < Radius2 ) then
				PinSize = IconSize * ( 1 - PinY / Radius * PinDepth );
				Pin[ PIN_KEEP ] = true;
				Pin[ PIN_DEPTH ] = PitchCompression > 0 and PinY or -PinY;
				tinsert( DepthTable, Pin );

				PinOffset = 0.4 * ( 1 - abs( PitchCompression ) * ( Pin[ PIN_DEPTH ] / Radius + 1 ) / 2 );
				PinBrightness = Brightness + PinOffset;
				PinBrightnessFar = BrightnessFar + PinOffset;
				Pin:SetWidth( PinSize );
				Pin:SetHeight( PinSize );
				Pin:SetPoint( "BOTTOM", HUD, "CENTER", PinX * Scale, PinY * Scale * HeightCompression );
				Texture = Pin[ PIN_TEXTURE ];
				Texture:SetAlpha( PinAlpha );
				Texture:SetGradient( "VERTICAL", PinBrightnessFar, PinBrightnessFar, PinBrightnessFar, PinBrightness, PinBrightness, PinBrightness );

				Pin:Show();
			else -- Hide if out of bounds
				Pin:Hide();
				Pin[ PIN_KEEP ] = false;
			end
		end

		-- Adjust north indicator
		DepthTop = #DepthTable + 2;
		if ( PitchCompression > 0 ) then
			BorderLevel = CurrentCos < 0 and DepthTop - 1 or 1;
		else
			BorderLevel = CurrentCos < 0 and 1 or DepthTop - 1;
		end
		HUD.NorthIndicator:SetFrameLevel( BorderLevel );
		HUD.NorthIndicator.Text:SetPoint( "BOTTOM", HUD, "CENTER",
			Radius * CurrentSin * Scale,
			Radius * CurrentCos * Scale * HeightCompression );
		HUD.NorthIndicator.Text:SetTextHeight( 15 * ( 1 - CurrentCos * PinDepth ) );
		Brightness = 0.6 + 0.4 * ( 1 - CurrentCos * PitchCompression ) / 2;
		HUD.NorthIndicator.Text:SetTextColor( TextColor.r * Brightness, TextColor.g * Brightness, TextColor.b * Brightness );

		-- Shade the ring
		BorderLevel = HeightCompression < 0 and DepthTop or 0;
		Brightness = HeightCompression < 0
			and ( -HeightCompression / 4 ) -- Looking up at disk
			or ( 1 - HeightCompression / 4 ); -- Looking down upon disk
		BrightnessFar = Brightness * HeightCompression;
		Border:SetFrameLevel( BorderLevel );
		if ( HeightCompression > 0 ) then
			if ( PitchCompression > 0 ) then
				Border.Texture:SetGradient( "VERTICAL", Brightness, Brightness, Brightness,
					BrightnessFar, BrightnessFar, BrightnessFar );
			else
				Border.Texture:SetGradient( "VERTICAL", BrightnessFar, BrightnessFar, BrightnessFar,
					Brightness, Brightness, Brightness );
			end
		else
			Border.Texture:SetVertexColor( Brightness, Brightness, Brightness );
		end

		PlayerIcon:SetHeight( Settings.IconSize * abs( HeightCompression ) );
		PlayerIcon:SetFrameLevel( BorderLevel );
		PlayerIcon.Texture:SetVertexColor( Brightness, Brightness, Brightness, 1.0 );

		-- Adjust the highlight rings
		if ( HeightCompression < 0 ) then
			Border.TextureHalo:SetHeight( -HeightCompression * Width * 544 / 512 );
			BrightnessFar = BrightnessFar * HeightCompression; -- Squares the compression
			if ( PitchCompression > 0 ) then
				Border.TextureHalo:SetGradientAlpha( "VERTICAL", 1, 1, 1, BrightnessFar, 1, 1, 1, Brightness );
			else
				Border.TextureHalo:SetGradientAlpha( "VERTICAL", 1, 1, 1, Brightness, 1, 1, 1, BrightnessFar );
			end
			Border.TextureHalo:Show();
			PlayerIcon.TextureHalo:SetHeight( -HeightCompression * Settings.IconSize * 80 / 64 );
			PlayerIcon.TextureHalo:SetAlpha( Brightness );
			PlayerIcon.TextureHalo:Show();
		else
			Border.TextureHalo:Hide();
			PlayerIcon.TextureHalo:Hide();
		end

		-- Depth-sort pins
		sort( DepthTable, DepthSort );
		for Index, Pin in ipairs( DepthTable ) do
			Pin:SetFrameLevel( Index + 1 );
			DepthTable[ Index ] = nil;
		end
	end
end
--[[****************************************************************************
  * Function: _VirtualMap.UpdateData                                           *
  * Description: Refreshes stored node positions.                              *
  ****************************************************************************]]
do
	local pairs = pairs;
	local GetPin = HUD.GetPin;

	local UniqueOffsets = {
		[ "Herb Gathering" ] = 1e9,
		[ "Fishing" ]        = 2e9,
		[ "Mining" ]         = 3e9,
		[ "Extract Gas" ]    = 4e9,
		[ "Treasure" ]       = 5e9,
	};
	local Settings, Pin, Offset;

	function me.UpdateData ()
		if ( not ( me.PlayerX or me.PlayerY ) ) then
			return;
		end

		Settings = DB.settings;
		for _, Type in pairs( GatherMate.db_types ) do
			if ( GatherMate.Visible[ Type ] ) then
				Offset = UniqueOffsets[ Type ];
				for Coord, ID in GatherMate:FindNearbyNode( me.Zone, me.PlayerX, me.PlayerY, Type, Settings.Radius + Settings.LookAhead ) do
					GetPin( Coord + Offset, Coord, NodeTextures[ Type ][ ID ] )[ PIN_KEEP ] = true;
				end
			end
		end

		-- Clean up all of the pins that we have marked inactive
		for ID, Pin in pairs( PinsActive ) do
			if ( Pin[ PIN_KEEP ] ) then -- Do nothing, we're keeping it
				Pin[ PIN_KEEP ] = false;
			else
				PinsActive[ ID ] = nil;
				PinsInactive[ Pin ] = true;
				Pin:Hide();
			end
		end
	end
end
--[[****************************************************************************
  * Function: _VirtualMap.UpdateFull                                           *
  * Description: Forces a full update of the UI.                               *
  ****************************************************************************]]
function me.UpdateFull ()
	me.ForceUpdate = true;
	me.NextDataUpdate = 0;
end
--[[****************************************************************************
  * Function: _VirtualMap:OnUpdate                                             *
  * Description: Updates the HUD display continuously.                         *
  ****************************************************************************]]
do
	local GetPlayerMapPosition = GetPlayerMapPosition;
	local GetRealZoneText = GetRealZoneText;

	local Changed, NewX, NewY, NewZone, ZoneData;

	function me:OnUpdate ( Elapsed )
		Changed = false;

		-- Cache player position
		NewX, NewY = GetPlayerMapPosition( "player" );
		if ( ( NewX ~= 0 and NewY ~= 0 ) and HUD.ShouldUpdate() ) then
			if ( me.PlayerX ~= NewX or me.PlayerY ~= NewY ) then
				me.PlayerX, me.PlayerY = NewX, NewY;
				Changed = true;
			end
			HUD:Show();
		else
			HUD:Hide();
			return;
		end

		-- Cache zone data
		NewZone = GetRealZoneText();
		if ( NewZone ~= me.Zone ) then
			me.Zone = NewZone;
			ZoneData = GatherMate.zoneData[ me.Zone ];
			me.ZoneWidth, me.ZoneHeight = ZoneData[ 1 ], ZoneData[ 2 ];

			-- Recycle all pins
			for ID, Pin in pairs( PinsActive ) do
				PinsActive[ ID ] = nil;
				Pin:Hide();
				PinsInactive[ Pin ] = true;
			end

			me.NextDataUpdate = 0; -- Force data update
			Changed = true;
		end


		-- Only run full update occasionally
		me.NextDataUpdate = me.NextDataUpdate - Elapsed;
		if ( me.NextDataUpdate <= 0 ) then
			me.NextDataUpdate = 2;

			me:UpdateData();
		end
		if ( me.ForceUpdate or Changed ) then
			me.ForceUpdate = false;
			me:Update();
		end
	end
end
--[[****************************************************************************
  * Function: _VirtualMap:OnShow                                               *
  * Description: Forces a full update of the UI.                               *
  ****************************************************************************]]
function me.OnShow ()
	me.UpdateFull();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Set up frames
	me:Hide();
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnShow", me.OnShow );

	HUD:Hide();
	HUD:SetPoint( "CENTER", UIParent );
	HUD:SetFrameStrata( "BACKGROUND" );

	PlayerIcon:SetPoint( "CENTER", HUD );
	PlayerIcon.Texture:SetTexture( "Interface\\AddOns\\_VirtualMap\\Skin\\HUDPlayerIcon.tga" );
	PlayerIcon.Texture:SetAllPoints( PlayerIcon );
	PlayerIcon.TextureHalo:SetPoint( "CENTER", PlayerIcon );
	PlayerIcon.TextureHalo:SetTexture( "Interface\\AddOns\\_VirtualMap\\Skin\\HUDPlayerIconHalo.tga" );
	PlayerIcon.TextureHalo:SetBlendMode( "ADD" );

	Border:SetAllPoints( HUD );
	Border.Texture:SetTexture( "Interface\\AddOns\\_VirtualMap\\Skin\\HUDBorder.tga" );
	Border.Texture:SetAllPoints( Border );
	Border.TextureHalo:SetPoint( "CENTER", Border );
	Border.TextureHalo:SetTexture( "Interface\\AddOns\\_VirtualMap\\Skin\\HUDBorderHalo.tga" );
	Border.TextureHalo:SetBlendMode( "ADD" );

	HUD.NorthIndicator.Text:SetText( L.NORTH_INDICATOR );

	SlashCmdList[ "_VIRTUALMAP" ] = function () me.Toggle(); end;
end
