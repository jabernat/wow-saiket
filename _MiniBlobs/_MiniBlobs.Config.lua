--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * _MiniBlobs.Config.lua - Adds an options pane to the menu.                  *
  ****************************************************************************]]


local _MiniBlobs = select( 2, ... );
local me, L = CreateFrame( "Frame", "_MiniBlobsConfig" ), _MiniBlobs.L;
_MiniBlobs.Config = me;

me.Types = {};
me.Quality = CreateFrame( "Slider", "$parentQuality", me, "OptionsSliderTemplate" );




--- Builds a standard tooltip for a control.
function me:ControlOnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
	GameTooltip:SetText( self.tooltipText, nil, nil, nil, nil, 1 );
end


--- Sets blob quality when the slider is moved.
function me.Quality:OnValueChanged ( Quality )
	return _MiniBlobs:SetQuality( Quality );
end
--- Toggles this blob type when its checkbox is clicked.
function me:TypeEnabledOnClick ()
	local Enable = not not self:GetChecked();
	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	return _MiniBlobs:SetTypeEnabled( self:GetParent().Type, Enable );
end
--- Sets blob type alpha when the slider is moved.
function me:TypeAlphaOnValueChanged ( Alpha )
	return _MiniBlobs:SetTypeAlpha( self:GetParent().Type, Alpha );
end
do
	--- Sets blob type style to the selected menu option.
	local function OnSelect ( self, Type, Style )
		return _MiniBlobs:SetTypeStyle( Type, Style );
	end
	-- Sort available styles alphabetically
	local Order = {};
	for Style in pairs( _MiniBlobs.Styles ) do
		Order[ #Order + 1 ] = Style;
	end
	table.sort( Order, function ( Style1, Style2 )
		return L.Styles[ Style1 ] < L.Styles[ Style2 ];
	end );
	--- Shows a dropdown list of available blob styles.
	function me:TypeStyleInitialize ()
		local Type = self:GetParent().Type;
		local StyleActive = _MiniBlobs:GetTypeStyle( Type );
		local Info = UIDropDownMenu_CreateInfo();
		Info.func = OnSelect;
		for _, Style in ipairs( Order ) do
			Info.text, Info.checked = L.Styles[ Style ], Style == StyleActive;
			Info.arg1, Info.arg2 = Type, Style;
			UIDropDownMenu_AddButton( Info );
		end
	end
end
--- Toggles showing only watched quests when this checkbox is clicked.
function me:QuestsWatchedOnClick ()
	local Watched = not not self:GetChecked();
	PlaySound( Watched and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	return _MiniBlobs:SetQuestsWatched( Watched );
end
--- Toggles showing only the selected quest when this checkbox is clicked.
function me:QuestsSelectedOnClick ()
	local Selected = not not self:GetChecked();
	PlaySound( Selected and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	return _MiniBlobs:SetQuestsSelected( Selected );
end


-- Adjust controls to match settings when changed.
function me:MiniBlobs_Quality ( _, Quality )
	return self.Quality:SetValue( Quality );
end
function me:MiniBlobs_TypeEnabled ( _, Type, Enabled )
	local Container = self.Types[ Type ];
	if ( Enabled ) then
		UIDropDownMenu_EnableDropDown( Container.Style );
		BlizzardOptionsPanel_Slider_Enable( Container.Alpha );
		if ( Type == "Quests" ) then
			BlizzardOptionsPanel_CheckButton_Enable( Container.Watched );
			BlizzardOptionsPanel_CheckButton_Enable( Container.Selected );
		end
	else
		UIDropDownMenu_DisableDropDown( Container.Style );
		BlizzardOptionsPanel_Slider_Disable( Container.Alpha );
		if ( Type == "Quests" ) then
			BlizzardOptionsPanel_CheckButton_Disable( Container.Watched );
			BlizzardOptionsPanel_CheckButton_Disable( Container.Selected );
		end
	end
	return Container.Enabled:SetChecked( Enabled );
end
function me:MiniBlobs_TypeAlpha ( _, Type, Alpha )
	return self.Types[ Type ].Alpha:SetValue( Alpha );
end
function me:MiniBlobs_TypeStyle ( _, Type, Style )
	return UIDropDownMenu_SetText( self.Types[ Type ].Style, L.Styles[ Style ] );
end
function me:MiniBlobs_QuestsWatched ( _, Watched )
	return self.Types[ "Quests" ].Watched:SetChecked( Watched );
end
function me:MiniBlobs_QuestsSelected ( _, Selected )
	return self.Types[ "Quests" ].Selected:SetChecked( Selected );
end


--- Reverts to default options.
function me:default ()
	return _MiniBlobs:Unpack( {} );
end




me.name = L.TITLE;
me:Hide();

-- Pane title
local Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( L.TITLE );
local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 24 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.DESC );


local Quality = me.Quality;
Quality:SetPoint( "LEFT", 16, 0 );
Quality:SetPoint( "RIGHT", -16, 0 );
Quality:SetPoint( "TOP", SubText, "BOTTOM", 0, -8 );
Quality:SetMinMaxValues( 0, 1 );
Quality:SetScript( "OnValueChanged", Quality.OnValueChanged );
Quality:SetScript( "OnEnter", me.ControlOnEnter );
Quality:SetScript( "OnLeave", GameTooltip_Hide );
local Name = Quality:GetName();
_G[ Name.."Text" ]:SetText( L.QUALITY );
_G[ Name.."Low" ]:SetText( L.QUALITY_LOW );
_G[ Name.."High" ]:SetText( L.QUALITY_HIGH );
Quality.tooltipText = L.QUALITY_DESC;
-- Highlight the high end of the slider orange
local Highlight = Quality:CreateTexture( nil, "ARTWORK" );
Highlight:SetTexture( 1, 0.5, 0.25, 0.4 );
Highlight:SetSize( 16, Quality:GetHeight() * 0.4 );
Highlight:SetPoint( "RIGHT", -2, 0 );

-- Create a section for each blob type
local Order = {};
for Type in pairs( _MiniBlobs.Types ) do
	Order[ #Order + 1 ] = Type;
end
table.sort( Order, function ( Type1, Type2 )
	return L.Types[ Type1 ] < L.Types[ Type2 ];
end );
local FrameLast = Quality;
for _, Type in ipairs( Order ) do
	local Container = CreateFrame( "Frame", "$parent"..Type, me, "OptionsBoxTemplate" );
	me.Types[ Type ], Container.Type = Container, Type;

	Container:SetPoint( "LEFT", me, 12, 0 );
	Container:SetPoint( "RIGHT", me, -12, 0 );
	Container:SetPoint( "TOP", FrameLast, "BOTTOM", 0, -38 );

	local Background = Container:CreateTexture( nil, "BACKGROUND" );
	Background:SetTexture( 0, 0, 0, 0.5 );
	Background:SetPoint( "BOTTOMLEFT", 5, 5 );
	Background:SetPoint( "TOPRIGHT", -5, -5 );

	local Enabled = CreateFrame( "CheckButton", "$parentEnabled", Container, "UICheckButtonTemplate" );
	Container.Enabled = Enabled;
	Enabled:SetSize( 26, 26 );
	Enabled:SetPoint( "BOTTOMLEFT", Container, "TOPLEFT", 0, -6 );
	Enabled:SetScript( "OnClick", me.TypeEnabledOnClick );
	Enabled:SetScript( "OnEnter", me.ControlOnEnter );
	Enabled:SetScript( "OnLeave", GameTooltip_Hide );
	local Label = _G[ Enabled:GetName().."Text" ];
	Label:SetFontObject( GameFontHighlight );
	Label:SetText( L.Types[ Type ] );
	Enabled.tooltipText = L.TYPE_ENABLED_DESC;
	Enabled:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );

	local Style = CreateFrame( "Frame", "$parentStyle", Container, "UIDropDownMenuTemplate" );
	Container.Style = Style;
	Style:SetPoint( "TOPLEFT", -10, -18 );
	Style:SetPoint( "RIGHT", -3, 0 );
	UIDropDownMenu_JustifyText( Style, "LEFT" );
	UIDropDownMenu_SetAnchor( Style, 0, 0, "TOPRIGHT", Style, "BOTTOMRIGHT" );
	Style.initialize = me.TypeStyleInitialize;
	_G[ Style:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	Style:EnableMouse( true );
	Style:SetScript( "OnEnter", me.ControlOnEnter );
	Style:SetScript( "OnLeave", GameTooltip_Hide );
	Style.tooltipText = L.TYPE_STYLE_DESC;
	local Label = Style:CreateFontString( "$parentLabel", "ARTWORK", "GameFontHighlight" );
	Label:SetPoint( "BOTTOMLEFT", Style, "TOPLEFT", 18, -1 );
	Label:SetText( L.TYPE_STYLE );

	local Alpha = CreateFrame( "Slider", "$parentAlpha", Container, "OptionsSliderTemplate" );
	Container.Alpha = Alpha;
	Alpha:SetPoint( "LEFT", 8, 0 );
	Alpha:SetPoint( "RIGHT", -8, 0 );
	Alpha:SetPoint( "TOP", Style, "BOTTOM", 0, -4 );
	Alpha:SetMinMaxValues( 0, 1 );
	Alpha:SetScript( "OnValueChanged", me.TypeAlphaOnValueChanged );
	local Name = Alpha:GetName();
	_G[ Name.."Low" ]:Hide();
	_G[ Name.."High" ]:Hide();
	local Text = _G[ Name.."Text" ];
	Text:ClearAllPoints();
	Text:SetPoint( "BOTTOMLEFT", Alpha, "TOPLEFT", 0, -3 );
	Text:SetText( L.TYPE_ALPHA );

	Container:SetHeight( Style:GetHeight() + Alpha:GetHeight() + 28 );
	if ( Type == "Quests" ) then
		-- Quest-specific controls
		local Watched = CreateFrame( "CheckButton", "$parentWatched", Container, "UICheckButtonTemplate" );
		Container.Watched = Watched;
		Watched:SetSize( 26, 26 );
		Watched:SetPoint( "TOPLEFT", Alpha, "BOTTOMLEFT", 0, -2 );
		Watched:SetScript( "OnClick", me.QuestsWatchedOnClick );
		Watched:SetScript( "OnEnter", me.ControlOnEnter );
		Watched:SetScript( "OnLeave", GameTooltip_Hide );
		local Label = _G[ Watched:GetName().."Text" ];
		Label:SetText( L.QUESTS_WATCHED );
		Watched.tooltipText = L.QUESTS_WATCHED_DESC;
		Watched:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );

		local Selected = CreateFrame( "CheckButton", "$parentSelected", Container, "UICheckButtonTemplate" );
		Container.Selected = Selected;
		Selected:SetSize( 26, 26 );
		Selected:SetPoint( "TOPLEFT", Watched, "BOTTOMLEFT", 0, -2 );
		Selected:SetScript( "OnClick", me.QuestsSelectedOnClick );
		Selected:SetScript( "OnEnter", me.ControlOnEnter );
		Selected:SetScript( "OnLeave", GameTooltip_Hide );
		local Label = _G[ Selected:GetName().."Text" ];
		Label:SetText( L.QUESTS_SELECTED );
		Selected.tooltipText = L.QUESTS_SELECTED_DESC;
		Selected:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );

		Container:SetHeight( Container:GetHeight() + Watched:GetHeight() + Selected:GetHeight() + 4 );
	end
	FrameLast = Container;
end


_MiniBlobs.RegisterCallback( me, "MiniBlobs_Quality" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_TypeEnabled" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_TypeAlpha" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_TypeStyle" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_QuestsWatched" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_QuestsSelected" );

InterfaceOptions_AddCategory( me );