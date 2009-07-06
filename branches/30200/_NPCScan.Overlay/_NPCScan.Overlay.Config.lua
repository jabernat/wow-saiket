--[[****************************************************************************
  * _NPCScan by Saiket                                                         *
  * _NPCScan.Overlay.Config.lua - Adds a configuration pane to enable and      *
  *   disable display modules like the WorldMap and BattlefieldMinimap.        *
  ****************************************************************************]]


local _NPCScan = _NPCScan;
local L = _NPCScanLocalization.OVERLAY;
local me = CreateFrame( "Frame" );
_NPCScan.Overlay.Config = me;

me.Modules = {};




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:ModuleOnClick                            *
  ****************************************************************************]]
function me:ModuleOnClick ( Enable )
	local Enable = self:GetChecked() == 1;

	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	_NPCScan.Overlay[ Enable and "ModuleEnable" or "ModuleDisable" ]( self.Name );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config.ModuleRegister                           *
  ****************************************************************************]]
do
	local LastCheckbox;
	function me.ModuleRegister ( Name, Text )
		local Checkbox = CreateFrame( "CheckButton", "_NPCScanOverlayModule"..Name, me, "UICheckButtonTemplate" );
		me.Modules[ Name ] = Checkbox;

		Checkbox.Name = Name;
		Checkbox:SetWidth( 26 );
		Checkbox:SetHeight( 26 );
		Checkbox:SetScript( "OnClick", me.ModuleOnClick );
		local Label = _G[ Checkbox:GetName().."Text" ];
		Label:SetText( Text );
		Checkbox:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );

		if ( LastCheckbox ) then
			Checkbox:SetPoint( "TOPLEFT", LastCheckbox, "BOTTOMLEFT", 0, 4 );
		else
			Checkbox:SetPoint( "TOPLEFT", me.SubText, "BOTTOMLEFT", -2, -8 );
		end
		LastCheckbox = Checkbox;
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:default                                  *
  ****************************************************************************]]
function me:default ()
	_NPCScan.Overlay.Synchronize();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.CONFIG_TITLE;
	me.parent = _NPCScanLocalization.CONFIG_TITLE;
	me:Hide();

	-- Pane title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	me.Title:SetPoint( "TOPLEFT", 16, -16 );
	me.Title:SetText( L.CONFIG_TITLE );
	local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
	me.SubText = SubText;
	SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
	SubText:SetPoint( "RIGHT", -32, 0 );
	SubText:SetHeight( 32 );
	SubText:SetJustifyH( "LEFT" );
	SubText:SetJustifyV( "TOP" );
	SubText:SetText( L.CONFIG_DESC );


	InterfaceOptions_AddCategory( me );
end
