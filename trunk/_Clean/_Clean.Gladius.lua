--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Gladius.lua - Modifies the Gladius addon's unit frames.             *
  ****************************************************************************]]


if ( select( 6, GetAddOnInfo( "Gladius" ) ) == "MISSING" ) then
	return;
end
local _Clean = _Clean;
local me = {};
_Clean.Gladius = me;




--[[****************************************************************************
  * Function: _Clean.Gladius:HealthOnValueChanged                              *
  * Description: Reverses the health bar and applies a faded color.            *
  ****************************************************************************]]
function me:HealthOnValueChanged ( Value )
	Value = Value / 100;
	local R, G, B, A;
	if ( Value == 0 ) then
		R, G, B, A = 1, 1, 1, 0.25;
	else
		R, G, B, A = 1 - Value, Value, 0, Value * -0.75 / 0.5 + 1.75;
	end
	self.Texture:SetVertexColor( R, G, B, A );
	self.Text:SetTextColor( R, G, B, A );
	me.HealthOnSizeChanged( self, self:GetWidth() );
end
--[[****************************************************************************
  * Function: _Clean.Gladius:HealthOnSizeChanged                               *
  * Description: Resizes the health bar.                                       *
  ****************************************************************************]]
function me:HealthOnSizeChanged ( Width )
	Width = ( 1 - self:GetValue() / 100 ) * Width;
	if ( Width > 0 ) then
		self.Texture:SetWidth( Width );
		self.Texture:Show();
	else
		self.Texture:Hide();
	end
end
--[[****************************************************************************
  * Function: _Clean.Gladius:HealthSetStatusBarTexture                         *
  * Description: Sets the fake status bar texture.                             *
  ****************************************************************************]]
function me:HealthSetStatusBarTexture ( Texture )
	if ( type( Texture ) == "string" ) then
		self.Texture:SetTexture( Texture );
	end
end

--[[****************************************************************************
  * Function: _Clean.Gladius:HealthSetStatusBarColor                           *
  * Description: Colors the unit's name based on its class.                    *
  ****************************************************************************]]
function me:HealthSetStatusBarColor ( R, G, B, A )
	self:GetParent().text:SetTextColorBackup( R, G, B, A );
end
--[[****************************************************************************
  * Function: _Clean.Gladius:ManaSetStatusBarColor                             *
  * Description: Colors the unit's mana value based on its power type.         *
  ****************************************************************************]]
function me:ManaSetStatusBarColor ( R, G, B, A )
	self:GetParent().manaText:SetTextColorBackup( R, G, B, A );
end

--[[****************************************************************************
  * Function: _Clean.Gladius:SpellSetText                                      *
  * Description: Removes rank text from cast bar.                              *
  ****************************************************************************]]
function me:SpellSetText ( Text )
	self:SetTextBackup( type( Text ) == "string" and Text:gsub( " %([^)]-%)$", "" ) or Text );
end

--[[****************************************************************************
  * Function: _Clean.Gladius:OnEnter                                           *
  ****************************************************************************]]
function me:OnEnter ()
	self.Highlight:Show();
end
--[[****************************************************************************
  * Function: _Clean.Gladius:OnLeave                                           *
  ****************************************************************************]]
function me:OnLeave ()
	self.Highlight:Hide();
end




--[[****************************************************************************
  * Function: _Clean.Gladius:CreateButton                                      *
  ****************************************************************************]]
function me:CreateButton ( Index )
	local Button = _G[ "GladiusButtonFrame"..Index ];

	-- Black backdrop
	local Background = Button:CreateTexture( nil, "BACKGROUND" );
	Background:SetTexture( 0, 0, 0 );
	Background:SetPoint( "TOPRIGHT", Button.secure, 2, 2 );
	Background:SetPoint( "BOTTOMLEFT", Button.secure, -2, -4 );

	-- Left icon
	Button.classIcon:SetVertexColor( 0.25, 0.25, 0.25 );
	_Clean.RemoveButtonIconBorder( Button.auraFrame.icon );

	-- Fade bar backgrounds
	Button.health.bg:SetAlpha( 0.05 );
	Button.mana.bg:SetAlpha( 0.1 );
	Button.castBar.bg:SetAlpha( 0.05 );

	-- Use "healer mode" reverse bars that blend colors
	local Health = Button.health;
	Health.Text = Button.healthText;
	Health.Texture = Health:CreateTexture( nil, "ARTWORK" );
	Health.Texture:SetPoint( "TOPRIGHT" );
	Health.Texture:SetPoint( "BOTTOM" );
	Health.Texture:SetTexture( Health:GetStatusBarTexture():GetTexture() );
	Health:SetStatusBarTexture( nil );
	Health.SetStatusBarTexture  = me.HealthSetStatusBarTexture;
	_Clean.HookScript( Health, "OnValueChanged", me.HealthOnValueChanged );
	_Clean.HookScript( Health, "OnSizeChanged", me.HealthOnSizeChanged );

	-- Use class color for name
	hooksecurefunc( Health, "SetStatusBarColor", me.HealthSetStatusBarColor );
	Button.text.SetTextColorBackup = Button.text.SetTextColor;
	Button.text.SetTextColor = _Clean.NilFunction;

	-- Color mana text like mana bar
	hooksecurefunc( Button.mana, "SetStatusBarColor", me.ManaSetStatusBarColor );
	Button.manaText.SetTextColorBackup = Button.manaText.SetTextColor;
	Button.manaText.SetTextColor = _Clean.NilFunction;

	-- Remove original highlight and use mouseover highlight
	local Secure = Button.secure; -- Actual unit button
	Secure.Highlight = Secure:CreateTexture( nil, "OVERLAY" );
	Secure.Highlight:Hide();
	Secure.Highlight:SetAllPoints( Background );
	Secure.Highlight:SetBlendMode( "ADD" );
	Secure.Highlight:SetTexture( Button.highlight:GetTexture() );
	Button.highlight:SetTexture( nil );
	_Clean.HookScript( Secure, "OnEnter", me.OnEnter );
	_Clean.HookScript( Secure, "OnLeave", me.OnLeave );

	-- Remove ranks from casting text
	local SpellText = Button.castBar.spellText;
	SpellText.SetTextBackup = SpellText.SetText;
	SpellText.SetText = me.SpellSetText;
end
--[[****************************************************************************
  * Function: _Clean.Gladius:CreateFrame                                       *
  ****************************************************************************]]
function me:CreateFrame ()
	Gladius.frame:SetBackdrop( {} );
	Gladius.frame:EnableMouse( false );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "Gladius", function ()
		hooksecurefunc( Gladius, "CreateFrame", me.CreateFrame );
		hooksecurefunc( Gladius, "CreateButton", me.CreateButton );

		-- Force glaze texture
		Gladius.options.args.bars.args.colors.args.barTexture.values[ "_Clean" ] = "_Clean";
		Gladius.db.profile.barTexture = "_Clean";
	end );
end
