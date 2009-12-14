--[[****************************************************************************
  * _Clean.Tooltip by Saiket                                                   *
  * _Clean.Tooltip.lua - Modifies the tooltip frames.                          *
  ****************************************************************************]]


local L = _CleanLocalization.Tooltip;
local _Clean = _Clean;
local me = {};
_Clean.Tooltip = me;

local IconSize = 32;




--[[****************************************************************************
  * Function: _Clean.Tooltip:SetDefaultAnchor                                  *
  * Description: Moves the default tooltip position to the top center.         *
  ****************************************************************************]]
function me:SetDefaultAnchor ()
	self:ClearAllPoints();
	self:SetPoint( "TOP", _Clean.TopMargin, "BOTTOM", 0, 4 );
end




--[[****************************************************************************
  * Function: _Clean.Tooltip:IconCreate                                        *
  * Description: Creates an icon on the tooltip frame.                         *
  ****************************************************************************]]
do
	local function OnTooltipCleared ( self )
		self.Icon:Hide();
		self.Normal:Hide();
	end
	function me:IconCreate ()
		if ( not self.Icon ) then
			local Icon, Normal = self:CreateTexture( nil, "ARTWORK" ), self:CreateTexture( nil, "OVERLAY" );
			self.Icon, self.Normal = Icon, Normal;
			Icon:SetWidth( IconSize );
			Icon:SetHeight( IconSize );
			Icon:SetPoint( "TOPRIGHT", self, "TOPLEFT", 2, -2 );
			_Clean.SkinButton( nil, Icon, Normal );

			self:HookScript( "OnTooltipCleared", OnTooltipCleared );
			OnTooltipCleared( self );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Tooltip:IconSet                                           *
  * Description: Sets or hides the tooltip's icon.                             *
  ****************************************************************************]]
function me:IconSet ( Texture, ... )
	local Icon, Normal = self.Icon, self.Normal;
	Icon:SetTexture( Texture );
	if ( Texture ) then
		if ( ... ) then
			Icon:SetTexCoord( ... );
		else -- Restore default
			_Clean.SkinButtonIcon( Icon );
		end
		Icon:Show();
		Normal:Show();
	else
		Icon:Hide();
		Normal:Hide();
	end
end


--[[****************************************************************************
  * Function: _Clean.Tooltip:UnitRegister                                      *
  * Description: Add a class icon and guild name brackets to unit tooltips.    *
  ****************************************************************************]]
do
	local function Update ( self, UnitID )
		if ( UnitExists( UnitID ) and UnitIsPlayer( UnitID ) ) then
			local GuildName = GetGuildInfo( UnitID );
			if ( GuildName ) then
				local Text = _G[ self:GetName().."TextLeft2" ];
				Text:SetFormattedText( L.GUILD_FORMAT, GuildName );
				Text:SetTextColor( GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b );
				self:AppendText( "" ); -- Automatically resize
			end

			me.IconSet( self,
				[[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]],
				unpack( CLASS_ICON_TCOORDS[ select( 2, UnitClass( UnitID ) ) ] ) );
		else
			me.IconSet( self );
		end
	end
	local function OnTooltipSetUnit ( self )
		local UnitID = select( 2, self:GetUnit() );
		if ( UnitID ) then
			Update( self, UnitID );
		end
	end
	local function SetUnit ( self, ActualUnitID )
		local UnitID = select( 2, self:GetUnit() );
		if ( not UnitID and self:IsShown() ) then -- OnTooltipSetUnit can't handle this case
			Update( self, ActualUnitID );
		end
	end
	function me:UnitRegister ()
		me.IconCreate( self );

		hooksecurefunc( self, "SetUnit", SetUnit );
		self:HookScript( "OnTooltipSetUnit", OnTooltipSetUnit );
	end
end
--[[****************************************************************************
  * Function: _Clean.Tooltip:ItemRegister                                      *
  * Description: Add item icons to tooltips.                                   *
  ****************************************************************************]]
do
	local function OnTooltipSetItem ( self )
		me.IconSet( self, GetItemIcon( select( 2, self:GetItem() ) ) );
	end
	function me:ItemRegister ()
		me.IconCreate( self );

		self:HookScript( "OnTooltipSetItem", OnTooltipSetItem );
	end
end
--[[****************************************************************************
  * Function: _Clean.Tooltip:SpellRegister                                     *
  * Description: Add spell icons to tooltips.                                  *
  ****************************************************************************]]
do
	local function OnTooltipSetSpell ( self )
		me.IconSet( self, ( select( 3, GetSpellInfo( select( 3, self:GetSpell() ) ) ) ) );
	end
	function me:SpellRegister ()
		me.IconCreate( self );

		self:HookScript( "OnTooltipSetSpell", OnTooltipSetSpell );
	end
end
--[[****************************************************************************
  * Function: _Clean.Tooltip:AchievementRegister                               *
  * Description: Add achievement icons to tooltips.                            *
  ****************************************************************************]]
do
	local function SetHyperlink ( self, Link )
		if ( self:IsShown() ) then
			local ID = Link:match( "^achievement:(%d+)" ) or Link:match( "|Hachievement:(%d+)" );
			if ( ID ) then
				me.IconSet( self, ( select( 10, GetAchievementInfo( ID ) ) ) );
			end
		end
	end
	function me:AchievementRegister ()
		me.IconCreate( self );

		hooksecurefunc( self, "SetHyperlink", SetHyperlink );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	hooksecurefunc( "GameTooltip_SetDefaultAnchor", me.SetDefaultAnchor );

	me.UnitRegister( GameTooltip );

	me.UnitRegister( ItemRefTooltip );
	me.ItemRegister( ItemRefTooltip );
	me.SpellRegister( ItemRefTooltip );
	me.AchievementRegister( ItemRefTooltip );
end
