--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * _MiniBlobs.Config.lua - Adds an options pane to the menu.                  *
  ****************************************************************************]]


local _MiniBlobs = select( 2, ... );
local NS, L = CreateFrame( "Frame", "_MiniBlobsConfig" ), _MiniBlobs.L;
_MiniBlobs.Config = NS;

NS.Types = {};
NS.Quality = CreateFrame( "Slider", "$parentQuality", NS, "OptionsSliderTemplate" );




--- Builds a standard tooltip for a control.
function NS:ControlOnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
	GameTooltip:SetText( self.tooltipText, nil, nil, nil, nil, 1 );
end


--- Sets blob quality when the slider is moved.
function NS.Quality:OnValueChanged ( Quality )
	return _MiniBlobs:SetQuality( Quality );
end
--- Toggles this blob type when its checkbox is clicked.
function NS:TypeEnabledOnClick ()
	local Enable = not not self:GetChecked();
	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	return _MiniBlobs:SetTypeEnabled( self:GetParent().Type, Enable );
end
--- Sets blob type alpha when the slider is moved.
function NS:TypeAlphaOnValueChanged ( Alpha )
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
	function NS:TypeStyleInitialize ()
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
do
	--- Sets quest filter to the selected menu option.
	local function OnSelect ( self, Filter )
		return _MiniBlobs:SetQuestsFilter( Filter );
	end
	local Order = { "NONE", "WATCHED", "SELECTED" };
	--- Shows a dropdown list of available quest filter options.
	function NS:QuestsFilterInitialize ()
		local FilterActive = _MiniBlobs:GetQuestsFilter();
		local Info = UIDropDownMenu_CreateInfo();
		Info.func = OnSelect;
		for _, Filter in ipairs( Order ) do
			Info.text, Info.checked = L.QuestsFilters[ Filter ], Filter == FilterActive;
			Info.arg1 = Filter;
			UIDropDownMenu_AddButton( Info );
		end
	end
end


-- Adjust controls to match settings when changed.
function NS:MiniBlobs_Quality ( _, Quality )
	return self.Quality:SetValue( Quality );
end
function NS:MiniBlobs_TypeEnabled ( _, Type, Enabled )
	local Container = self.Types[ Type ];
	if ( Enabled ) then
		UIDropDownMenu_EnableDropDown( Container.Style );
		BlizzardOptionsPanel_Slider_Enable( Container.Alpha );
		if ( Type == "Quests" ) then
			UIDropDownMenu_EnableDropDown( Container.Filter );
		end
	else
		UIDropDownMenu_DisableDropDown( Container.Style );
		BlizzardOptionsPanel_Slider_Disable( Container.Alpha );
		if ( Type == "Quests" ) then
			UIDropDownMenu_DisableDropDown( Container.Filter );
		end
	end
	return Container.Enabled:SetChecked( Enabled );
end
function NS:MiniBlobs_TypeAlpha ( _, Type, Alpha )
	return self.Types[ Type ].Alpha:SetValue( Alpha );
end
function NS:MiniBlobs_TypeStyle ( _, Type, Style )
	return UIDropDownMenu_SetText( self.Types[ Type ].Style, L.Styles[ Style ] );
end
function NS:MiniBlobs_QuestsFilter ( _, Filter )
	return UIDropDownMenu_SetText( self.Types[ "Quests" ].Filter, L.QuestsFilters[ Filter ] );
end


--- Reverts to default options.
function NS:default ()
	return _MiniBlobs:Unpack( {} );
end




NS.name = L.TITLE;
NS:Hide();

-- Pane title
local Title = NS:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( L.TITLE );
local SubText = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 24 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.DESC );


local Quality = NS.Quality;
Quality:SetPoint( "LEFT", 16, 0 );
Quality:SetPoint( "RIGHT", -16, 0 );
Quality:SetPoint( "TOP", SubText, "BOTTOM", 0, -8 );
Quality:SetMinMaxValues( 0, 1 );
Quality:SetScript( "OnValueChanged", Quality.OnValueChanged );
Quality:SetScript( "OnEnter", NS.ControlOnEnter );
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
	local Container = CreateFrame( "Frame", "$parent"..Type, NS, "OptionsBoxTemplate" );
	NS.Types[ Type ], Container.Type = Container, Type;

	Container:SetPoint( "LEFT", NS, 12, 0 );
	Container:SetPoint( "RIGHT", NS, -12, 0 );
	Container:SetPoint( "TOP", FrameLast, "BOTTOM", 0, -38 );

	local Background = Container:CreateTexture( nil, "BACKGROUND" );
	Background:SetTexture( 0, 0, 0, 0.5 );
	Background:SetPoint( "BOTTOMLEFT", 5, 5 );
	Background:SetPoint( "TOPRIGHT", -5, -5 );

	local Enabled = CreateFrame( "CheckButton", "$parentEnabled", Container, "UICheckButtonTemplate" );
	Container.Enabled = Enabled;
	Enabled:SetSize( 26, 26 );
	Enabled:SetPoint( "BOTTOMLEFT", Container, "TOPLEFT", 0, -6 );
	Enabled:SetScript( "OnClick", NS.TypeEnabledOnClick );
	Enabled:SetScript( "OnEnter", NS.ControlOnEnter );
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
	Style.initialize = NS.TypeStyleInitialize;
	_G[ Style:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	Style:EnableMouse( true );
	Style:SetScript( "OnEnter", NS.ControlOnEnter );
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
	Alpha:SetScript( "OnValueChanged", NS.TypeAlphaOnValueChanged );
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
		local Filter = CreateFrame( "Frame", "$parentFilter", Container, "UIDropDownMenuTemplate" );
		Container.Filter = Filter;
		Filter:SetPoint( "TOP", Alpha, "BOTTOM", 0, -18 );
		Filter:SetPoint( "LEFT", Style );
		Filter:SetPoint( "RIGHT", Style );
		UIDropDownMenu_JustifyText( Filter, "LEFT" );
		UIDropDownMenu_SetAnchor( Filter, 0, 0, "TOPRIGHT", Filter, "BOTTOMRIGHT" );
		Filter.initialize = NS.QuestsFilterInitialize;
		_G[ Filter:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
		Filter:EnableMouse( true );
		Filter:SetScript( "OnEnter", NS.ControlOnEnter );
		Filter:SetScript( "OnLeave", GameTooltip_Hide );
		Filter.tooltipText = L.QUESTS_FILTER_DESC;
		local Label = Filter:CreateFontString( "$parentLabel", "ARTWORK", "GameFontHighlight" );
		Label:SetPoint( "BOTTOMLEFT", Filter, "TOPLEFT", 18, -1 );
		Label:SetText( L.QUESTS_FILTER );

		Container:SetHeight( Container:GetHeight() + Filter:GetHeight() + 18 );
	end
	FrameLast = Container;
end


_MiniBlobs.RegisterCallback( NS, "MiniBlobs_Quality" );
_MiniBlobs.RegisterCallback( NS, "MiniBlobs_TypeEnabled" );
_MiniBlobs.RegisterCallback( NS, "MiniBlobs_TypeAlpha" );
_MiniBlobs.RegisterCallback( NS, "MiniBlobs_TypeStyle" );
_MiniBlobs.RegisterCallback( NS, "MiniBlobs_QuestsFilter" );

InterfaceOptions_AddCategory( NS );