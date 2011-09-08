--[[****************************************************************************
  * _Underscore.CastingBar by Saiket                                           *
  * _Underscore.CastingBar.lua - Reposition the spell casting progress bar.    *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local NS = select( 2, ... );
_Underscore.CastingBar = NS;

NS.LagUpdateRate = 1; -- Seconds

local BarPadding = 10;
local BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, _Underscore.MediaBar );




--- Sets the spell icon for a cast bar.
function NS:SetIcon ( Path )
	self.Icon:SetTexture( ( Path ~= [[Interface\Icons\Temp]] ) and Path or nil );
end


do
	local Colors = _Underscore.Colors;	
	--- Replaces the standard status colors.
	function NS:SetStatusBarColor ( R, G, B, A )
		local Color;
		if ( R == 0.0 and G == 1.0 and B == 0.0 ) then -- Finished / Channeling
			Color = Colors.reaction[ 8 ]; -- Friendly
		elseif ( R == 1.0 and G == 0.0 and B == 0.0 ) then -- Failed
			Color = Colors.reaction[ 1 ]; -- Hostile
		elseif ( R == 1.0 and G == 0.7 and B == 0.0 ) then -- Casting
			Color = Colors.Highlight;
		end
		if ( Color ) then
			R, G, B = unpack( Color );
			getmetatable( self ).__index.SetStatusBarColor( self, R, G, B, A );
		end
	end
end
--- Reset lag update timer for player's cast bar only.
function NS:PlayerOnShow ()
	self.Lag.UpdateNext = 0;
end
do
	local select = select;
	local GetTime = GetTime;
	local max = max;
	local GetNetStats = GetNetStats;
	--- Hides casting bar artwork and updates time text.
	function NS:OnUpdate ( Elapsed )
		-- Hide artwork
		self.Border:Hide();
		self.Flash:Hide();
		self.Spark:Hide();

		-- Update cast time
		local Time = select( 6, ( self.channeling and UnitChannelInfo or UnitCastingInfo )( self.UnitID ) );
		self.Time:SetFormattedText( NS.L.TIME_FORMAT,
			Time and max( 0, Time / 1000 - GetTime() ) or 0 );

		-- Update latency
		local Lag = self.Lag;
		if ( Lag ) then
			Lag.UpdateNext = Lag.UpdateNext - Elapsed;
			if ( Lag.UpdateNext <= 0 ) then
				Lag.UpdateNext = NS.LagUpdateRate;

				Lag:SetWidth( min( 1, select( 4, GetNetStats() ) / 1000 / select( 2, self:GetMinMaxValues() ) ) * self:GetWidth() );
			end
		end
	end
end


--- Updates castbars immediately after zoning.
function NS:PLAYER_ENTERING_WORLD ()
	if ( UnitChannelInfo( self.UnitID ) ) then
		NS.UNIT_SPELLCAST_CHANNEL_START( self, nil, self.UnitID );
	elseif ( UnitCastingInfo( self.UnitID ) ) then
		NS.UNIT_SPELLCAST_START( self, nil, self.UnitID );
	end
end
--- Updates castbars when beginning a cast.
function NS:UNIT_SPELLCAST_START ( _, UnitID )
	if ( UnitID == self.UnitID ) then
		NS.SetIcon( self, select( 4, UnitCastingInfo( UnitID ) ) );
	end
end
--- Updates castbars when beginning a channeled spell.
function NS:UNIT_SPELLCAST_CHANNEL_START ( _, UnitID )
	if ( UnitID == self.UnitID ) then
		NS.SetIcon( self, select( 4, UnitChannelInfo( UnitID ) ) );
	end
end
--- Generic event handler that checks the module for event handlers rather than the castbars.
function NS:OnEvent ( Event, ... )
	if ( NS[ Event ] ) then
		return NS[ Event ]( self, Event, ... );
	end
end




--- Skins a casting bar frame and positions it.
-- @param ...  Castbar regions.
local function AddCastingBar ( self, UnitID, ... )
	self.UnitID = UnitID;

	-- Position the bar between the left and right action bars
	self:ClearAllPoints();
	self:SetPoint( "TOPRIGHT", _Underscore.ActionBars.BackdropBottomRight, "TOPLEFT", -BarPadding, -BarPadding );
	self:SetPoint( "BOTTOMLEFT", _Underscore.ActionBars.BackdropBottomLeft, "BOTTOMRIGHT", BarPadding, BarPadding );
	self:SetWidth( 0 ); -- Allow GetWidth to return actual width
	self:SetStatusBarTexture( BarTexture );

	-- Replace solid background color
	for Index = 1, select( "#", ... ) do
		local Region = select( Index, ... );
		if ( Region:GetObjectType() == "Texture" and Region:GetDrawLayer() == "BACKGROUND"
			and ( Region:GetTexture() or "" ):match( "^Color%-%x%x%x%x+$" )
		) then
			Region:Hide();
			break;
		end
	end
	_Underscore.Backdrop.Create( self, 0 );

	local Text = _G[ self:GetName().."Text" ];
	Text:ClearAllPoints();
	Text:SetPoint( "CENTER" );
	Text:SetWidth( 0 ); -- Allow region to expand with text
	Text:SetFontObject( GameFontHighlightLarge );

	-- Regions
	self.Border = _G[ self:GetName().."Border" ];
	self.Flash = _G[ self:GetName().."Flash" ];
	self.Spark = _G[ self:GetName().."Spark" ];
	self.Icon = self:CreateTexture( nil, "ARTWORK" );
	self.Icon:SetSize( 32, 32 );
	self.Icon:SetPoint( "LEFT", self, 2, 0 );
	self.Icon:SetAlpha( 0.75 );
	_Underscore.SkinButton( nil, self.Icon, self:CreateTexture( nil, "OVERLAY" ) );
	self.Time = self:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
	self.Time:SetPoint( "LEFT", Text, "RIGHT" );

	if ( UnitID == "player" ) then
		self.Lag = self:CreateTexture( nil, "BORDER" );
		self.Lag:SetPoint( "TOPRIGHT" );
		self.Lag:SetPoint( "BOTTOM" );
		self.Lag:SetTexture( BarTexture );
		self.Lag:SetBlendMode( "ADD" );
		local R, G, B = unpack( _Underscore.Colors.disconnected );
		self.Lag:SetVertexColor( R, G, B, 0.5 );
		self:HookScript( "OnShow", NS.PlayerOnShow );
	end
	self:HookScript( "OnEvent", NS.OnEvent );
	self:HookScript( "OnUpdate", NS.OnUpdate );
	hooksecurefunc( self, "SetStatusBarColor", NS.SetStatusBarColor );
end

UIPARENT_MANAGED_FRAME_POSITIONS[ "CastingBarFrame" ] = nil;
AddCastingBar( CastingBarFrame, "player", CastingBarFrame:GetRegions() );
AddCastingBar( PetCastingBarFrame, "pet", PetCastingBarFrame:GetRegions() );