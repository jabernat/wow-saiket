--[[****************************************************************************
  * _Underscore.Tooltip by Saiket                                              *
  * _Underscore.Tooltip.lua - Modifies the tooltip frames.                     *
  ****************************************************************************]]


local LibSharedMedia = LibStub( "LibSharedMedia-3.0" );
local _Underscore = _Underscore;
local me = select( 2, ... );
_Underscore.Tooltip = me;
local L = me.L;

local TooltipPadding = -4; -- Distance between actual border of tooltip frame and its rendered outline
local IconSize = 32;
local BarTexture = LibSharedMedia:Fetch( LibSharedMedia.MediaType.STATUSBAR, _Underscore.MediaBar );




--- Moves the default tooltip position to the top center.
function me:SetDefaultAnchor ()
	self:ClearAllPoints();
	self:SetPoint( "TOP", _Underscore.TopMargin, "BOTTOM", 0, -TooltipPadding );
end

do
	--- Sets the tooltip's health bar to a green color.
	local function StatusBarOnValueChanged ( self )
		self:SetStatusBarColor( unpack( _Underscore.Colors.reaction[ 8 ] ) );
	end
	--- Undoes attempts to put a normal backdrop on the tooltip.
	local function SetBackdrop ( self )
		getmetatable( self ).__index.SetBackdrop( self, nil );
	end
	-- Skins and hooks a tooltip frame.
	function me:Skin ()
		self:SetBackdrop( nil );
		hooksecurefunc( self, "SetBackdrop", SetBackdrop );

		_Underscore.Backdrop.Create( self, TooltipPadding ):SetAlpha( 0.75 );
		self:SetHitRectInsets( -TooltipPadding, -TooltipPadding, -TooltipPadding, -TooltipPadding );
		local StatusBar = _G[ self:GetName().."StatusBar" ];
		if ( StatusBar ) then
			StatusBar:ClearAllPoints();
			StatusBar:SetPoint( "TOPLEFT", self, "BOTTOMLEFT", -TooltipPadding, -TooltipPadding );
			StatusBar:SetPoint( "RIGHT", TooltipPadding, 0 );
			StatusBar:SetStatusBarTexture( BarTexture );
			StatusBar:HookScript( "OnValueChanged", StatusBarOnValueChanged );
			StatusBarOnValueChanged( StatusBar );
		end
	end
end




do
	--- Hides old icons when the tooltip is reset.
	local function OnTooltipCleared ( self )
		self.Icon:Hide();
		self.Normal:Hide();
	end
	--- Creates an icon on the tooltip frame.
	function me:IconCreate ()
		if ( not self.Icon ) then
			local Icon, Normal = self:CreateTexture( nil, "ARTWORK" ), self:CreateTexture( nil, "OVERLAY" );
			self.Icon, self.Normal = Icon, Normal;
			Icon:SetSize( IconSize, IconSize );
			Icon:SetPoint( "TOPRIGHT", self, "TOPLEFT", -TooltipPadding, TooltipPadding );
			_Underscore.SkinButton( nil, Icon, Normal );

			self:HookScript( "OnTooltipCleared", OnTooltipCleared );
			OnTooltipCleared( self );
		end
	end
end
--- Sets or hides the tooltip's icon.
-- @param Texture  Path to set the icon to, or nil to hide it.
-- @param ...  Custom texcoords to use for the icon.
function me:IconSet ( Texture, ... )
	local Icon, Normal = self.Icon, self.Normal;
	Icon:SetTexture( Texture );
	if ( Texture ) then
		if ( ... ) then
			Icon:SetTexCoord( ... );
		else -- Restore default
			_Underscore.SkinButtonIcon( Icon );
		end
		Icon:Show();
		Normal:Show();
	else
		Icon:Hide();
		Normal:Hide();
	end
end


do
	local select = select;
	--- Updates a given UnitID's tooltip.
	local function Update ( self, UnitID )
		if ( UnitIsPlayer( UnitID ) ) then
			local GuildName = GetGuildInfo( UnitID );
			if ( GuildName ) then
				local Text, Color = _G[ self:GetName().."TextLeft2" ], GRAY_FONT_COLOR;
				Text:SetFormattedText( L.GUILD_FORMAT, GuildName );
				Text:SetTextColor( Color.r, Color.g, Color.b );
				self:AppendText( "" ); -- Automatically resize
			end

			me.IconSet( self, [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]],
				unpack( CLASS_ICON_TCOORDS[ select( 2, UnitClass( UnitID ) ) ] ) );
		else
			me.IconSet( self );
		end
	end
	--- Hook to update unit tooltips if a UnitID is available.
	local function OnTooltipSetUnit ( self )
		local UnitID = select( 2, self:GetUnit() );
		if ( UnitID ) then
			Update( self, UnitID );
		end
	end
	--- Hook to update unit tooltips for units without UnitIDs.
	local function SetUnit ( self, ActualUnitID )
		local UnitID = select( 2, self:GetUnit() );
		if ( not UnitID and self:IsShown() ) then -- OnTooltipSetUnit can't handle this case
			Update( self, ActualUnitID );
		end
	end
	--- Register a tooltip to add class icons and guild name brackets for units.
	function me:RegisterUnit ()
		me.IconCreate( self );

		hooksecurefunc( self, "SetUnit", SetUnit );
		self:HookScript( "OnTooltipSetUnit", OnTooltipSetUnit );
	end
end


do
	--- Hook to add item icons when shown.
	local function OnTooltipSetItem ( self )
		me.IconSet( self, GetItemIcon( select( 2, self:GetItem() ) ) );
	end
	--- Register a tooltip to add item icons.
	function me:RegisterItem ()
		me.IconCreate( self );

		self:HookScript( "OnTooltipSetItem", OnTooltipSetItem );
	end
end


do
	--- Hook to add spell icons when shown.
	local function OnTooltipSetSpell ( self )
		me.IconSet( self, ( select( 3, GetSpellInfo( ( select( 3, self:GetSpell() ) ) ) ) ) );
	end
	--- Register a tooltip to add spell icons.
	function me:RegisterSpell ()
		me.IconCreate( self );

		self:HookScript( "OnTooltipSetSpell", OnTooltipSetSpell );
	end
end


do
	--- Hook to add achievement icons when shown.
	local function SetHyperlink ( self, Link )
		if ( self:IsShown() ) then
			local ID = Link:match( "^achievement:(%d+)" ) or Link:match( "|Hachievement:(%d+)" );
			if ( ID ) then
				me.IconSet( self, ( select( 10, GetAchievementInfo( ID ) ) ) );
			end
		end
	end
	--- Register a tooltip to add achievement icons.
	function me:RegisterAchievement ()
		me.IconCreate( self );

		hooksecurefunc( self, "SetHyperlink", SetHyperlink );
	end
end




--- Skins a tooltip and its child shopping tooltips.
local function SkinAll ( self )
	me.Skin( self );
	for _, ShoppingTooltip in ipairs( self.shoppingTooltips ) do
		me.Skin( ShoppingTooltip );
	end
end

me.RegisterUnit( GameTooltip );
SkinAll( GameTooltip );
hooksecurefunc( "GameTooltip_SetDefaultAnchor", me.SetDefaultAnchor );
GameTooltip:SetScale( 0.75 );

me.RegisterUnit( ItemRefTooltip );
me.RegisterItem( ItemRefTooltip );
me.RegisterSpell( ItemRefTooltip );
me.RegisterAchievement( ItemRefTooltip );
SkinAll( ItemRefTooltip );
ItemRefTooltip:SetPadding( 0 ); -- Remove padding on right side that close button occupies

SkinAll( WorldMapTooltip );