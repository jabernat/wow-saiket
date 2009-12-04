--[[****************************************************************************
  * _Clean.CastingBar by Saiket                                                *
  * _Clean.CastingBar.lua - Reposition the spell casting progress bar.         *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local L = _CleanLocalization.CastingBar;
local _Clean = _Clean;
local me = {};
_Clean.CastingBar = me;

local BarPadding = 10;
local BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, "_Clean" );




--[[****************************************************************************
  * Function: _Clean.CastingBar:SetIcon                                        *
  * Description: Sets the spell icon for a cast bar.                           *
  ****************************************************************************]]
function me:SetIcon ( Path )
	self.Icon:SetTexture( ( Path ~= [[Interface\Icons\Temp]] ) and Path or nil );
end


--[[****************************************************************************
  * Function: _Clean.CastingBar:SetStatusBarColor                              *
  * Description: Replaces the standard status colors.                          *
  ****************************************************************************]]
function me:SetStatusBarColor ( R, G, B, A )
	local Color;
	if ( R == 0.0 and G == 1.0 and B == 0.0 ) then -- Finished / Channeling
		Color = _Clean.Colors.reaction[ 8 ]; -- Friendly
	elseif ( R == 1.0 and G == 0.0 and B == 0.0 ) then -- Failed
		Color = _Clean.Colors.reaction[ 1 ]; -- Hostile
	elseif ( R == 1.0 and G == 0.7 and B == 0.0 ) then -- Casting
		Color = _Clean.Colors.Highlight;
	end
	if ( Color ) then
		R, G, B = unpack( Color );
		getmetatable( self ).__index.SetStatusBarColor( self, R, G, B, A );
	end
end
--[[****************************************************************************
  * Function: _Clean.CastingBar:OnUpdate                                       *
  * Description: Hides casting bar artwork and updates time text.              *
  ****************************************************************************]]
do
	local select = select;
	local GetTime = GetTime;
	local max = max;
	function me:OnUpdate ()
		-- Hide artwork
		self.Border:Hide();
		self.Flash:Hide();
		self.Spark:Hide();

		local Time = select( 6, ( self.channeling and UnitChannelInfo or UnitCastingInfo )( self.UnitID ) );
		self.Time:SetFormattedText( L.TIME_FORMAT,
			Time and max( 0, Time / 1000 - GetTime() ) or 0 );
	end
end


--[[****************************************************************************
  * Function: _Clean.CastingBar:PLAYER_ENTERING_WORLD                          *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	if ( UnitChannelInfo( self.UnitID ) ) then
		me.UNIT_SPELLCAST_CHANNEL_START( self, nil, self.UnitID );
	elseif ( UnitCastingInfo( self.UnitID ) ) then
		me.UNIT_SPELLCAST_START( self, nil, self.UnitID );
	end
end
--[[****************************************************************************
  * Function: _Clean.CastingBar:UNIT_SPELLCAST_START                           *
  ****************************************************************************]]
function me:UNIT_SPELLCAST_START ( _, UnitID )
	if ( UnitID == self.UnitID ) then
		me.SetIcon( self, select( 4, UnitCastingInfo( UnitID ) ) );
	end
end
--[[****************************************************************************
  * Function: _Clean.CastingBar:UNIT_SPELLCAST_CHANNEL_START                   *
  ****************************************************************************]]
function me:UNIT_SPELLCAST_CHANNEL_START ( _, UnitID )
	if ( UnitID == self.UnitID ) then
		me.SetIcon( self, select( 4, UnitChannelInfo( UnitID ) ) );
	end
end
--[[****************************************************************************
  * Function: _Clean.CastingBar:OnEvent                                        *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( me[ Event ] ) == "function" ) then
			me[ Event ]( self, Event, ... );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	local function AddCastingBar ( self, UnitID, ... ) -- Skins a casting bar frame and positions it
		self.UnitID = UnitID;

		-- Position the bar between the left and right action bars
		self:ClearAllPoints();
		self:SetPoint( "TOPRIGHT", _Clean.ActionBars.BackdropBottomRight, "TOPLEFT", -BarPadding, -BarPadding );
		self:SetPoint( "BOTTOMLEFT", _Clean.ActionBars.BackdropBottomLeft, "BOTTOMRIGHT", BarPadding, BarPadding );
		self:SetStatusBarTexture( BarTexture );

		-- Replace solid background color
		for Index = 1, select( "#", ... ) do
			local Region = select( Index, ... );
			if ( Region:GetObjectType() == "Texture" and Region:GetDrawLayer() == "BACKGROUND" and Region:GetTexture() == "Solid Texture" ) then
				Region:Hide();
				break;
			end
		end
		_Clean.Backdrop.Add( self );

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
		self.Icon:SetWidth( 32 );
		self.Icon:SetHeight( 32 );
		self.Icon:SetPoint( "LEFT", self, 2, 0 );
		self.Icon:SetAlpha( 0.75 );
		_Clean.RemoveIconBorder( self.Icon );
		self.Time = self:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
		self.Time:SetPoint( "LEFT", Text, "RIGHT" );

		self:HookScript( "OnEvent", me.OnEvent );
		self:HookScript( "OnUpdate", me.OnUpdate );
		hooksecurefunc( self, "SetStatusBarColor", me.SetStatusBarColor );
	end

	UIPARENT_MANAGED_FRAME_POSITIONS[ "CastingBarFrame" ] = nil;
	AddCastingBar( CastingBarFrame, "player", CastingBarFrame:GetRegions() );
	AddCastingBar( PetCastingBarFrame, "pet", PetCastingBarFrame:GetRegions() );
end
