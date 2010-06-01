--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * _VirtualPlates.Config.lua - Adds options to the Interface Options menu.    *
  ****************************************************************************]]


local _VirtualPlates = _VirtualPlates;
local L = _VirtualPlatesLocalization;
local me = CreateFrame( "Frame", "_VirtualPlatesConfig" );
_VirtualPlates.Config = me;

me.ScaleFactor = CreateFrame( "Slider", "$parentScaleFactor", me, "OptionsSliderTemplate" );

local LimitsOptions = CreateFrame( "Frame", "$parentLimitsOptions", me, "OptionsBoxTemplate" );
me.MinScale = CreateFrame( "Slider", "$parentMinScale", LimitsOptions, "OptionsSliderTemplate" );
me.MaxScaleEnabled = CreateFrame( "CheckButton", "$parentMaxScaleEnabled", LimitsOptions, "InterfaceOptionsCheckButtonTemplate" );
me.MaxScale = CreateFrame( "Slider", "$parentMaxScale", LimitsOptions, "OptionsSliderTemplate" );

me.MaxScaleMax = 10;
me.ScaleFactorMin =  5;
me.ScaleFactorMax = 40;




--[[****************************************************************************
  * Function: _VirtualPlates.Config:SliderSetEnabled                           *
  ****************************************************************************]]
function me:SliderSetEnabled ( Enable )
	( Enable and BlizzardOptionsPanel_Slider_Enable or BlizzardOptionsPanel_Slider_Disable )( self );
	self.Value:SetFontObject( Enable and GameFontNormalSmall or GameFontDisableSmall );
end
--[[****************************************************************************
  * Function: _VirtualPlates.Config:SliderSetRange                             *
  ****************************************************************************]]
function me:SliderSetRange ( Min, Max )
	self:SetMinMaxValues( Min, Max );

	local Name = self:GetName();
	_G[ Name.."Low" ]:SetFormattedText( self.Format, MinLabel or Min );
	_G[ Name.."High" ]:SetFormattedText( self.Format, MaxLabel or Max );
end
--[[****************************************************************************
  * Function: _VirtualPlates.Config:SliderOnValueChanged                       *
  ****************************************************************************]]
function me:SliderOnValueChanged ( Value )
	self.Value:SetFormattedText( self.Format, Value );

	self.Update( Value );
	if ( self.OnValueChanged ) then
		self:OnValueChanged( Value );
	end
end


--[[****************************************************************************
  * Function: _VirtualPlates.Config.MinScale:OnValueChanged                    *
  ****************************************************************************]]
function me.MinScale:OnValueChanged ( Value )
	me.SliderSetRange( me.MaxScale, Value, me.MaxScaleMax );
end
--[[****************************************************************************
  * Function: _VirtualPlates.Config.MaxScaleEnabled.setFunc                    *
  ****************************************************************************]]
function me.MaxScaleEnabled.setFunc ( Enable )
	Enable = Enable == "1";

	me.SliderSetEnabled( me.MaxScale, Enable );
	_VirtualPlates.SetMaxScaleEnabled( Enable );
end




--[[****************************************************************************
  * Function: _VirtualPlates.Config:default                                    *
  ****************************************************************************]]
function me:default ()
	_VirtualPlates.Synchronize();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.CONFIG_TITLE;
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


	local function SetupSlider ( self, Format )
		self.Format = Format;
		self:SetPoint( "RIGHT", -20, 0 );
		self:SetScript( "OnValueChanged", me.SliderOnValueChanged );
		self.Value = self:CreateFontString( nil, nil, "GameFontNormalSmall" );
		self.Value:SetPoint( "TOP", self, "BOTTOM", 0, 4 );
		return self;
	end


	SetupSlider( me.ScaleFactor, L.CONFIG_SLIDERYARD_FORMAT ):SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", 6, -16 );
	me.ScaleFactor.Update = _VirtualPlates.SetScaleFactor;
	_G[ me.ScaleFactor:GetName().."Text" ]:SetText( L.CONFIG_SCALEFACTOR );
	me.ScaleFactor.tooltipText = L.CONFIG_SCALEFACTOR_DESC;
	me.SliderSetRange( me.ScaleFactor, me.ScaleFactorMin, me.ScaleFactorMax );


	-- Size limit options section
	LimitsOptions:SetPoint( "TOPLEFT", me.ScaleFactor, "BOTTOMLEFT", -8, -38 );
	LimitsOptions:SetPoint( "RIGHT", -14, 0 );
	_G[ LimitsOptions:GetName().."Title" ]:SetText( L.CONFIG_LIMITS );

	SetupSlider( me.MinScale, L.CONFIG_SLIDER_FORMAT ):SetPoint( "TOPLEFT", 16, -16 );
	me.MinScale.Update = _VirtualPlates.SetMinScale;
	_G[ me.MinScale:GetName().."Text" ]:SetText( L.CONFIG_MINSCALE );
	me.MinScale.tooltipText = L.CONFIG_MINSCALE_DESC;
	me.SliderSetRange( me.MinScale, 0, 1 );

	me.MaxScaleEnabled:SetPoint( "TOPLEFT", me.MinScale, "BOTTOMLEFT", -4, -28 );
	local Label = _G[ me.MaxScaleEnabled:GetName().."Text" ];
	Label:SetText( L.CONFIG_MAXSCALEENABLED );
	me.MaxScaleEnabled:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );
	me.MaxScaleEnabled.tooltipText = L.CONFIG_MAXSCALEENABLED_DESC;

	SetupSlider( me.MaxScale, L.CONFIG_SLIDER_FORMAT ):SetPoint( "TOPLEFT", me.MaxScaleEnabled, "BOTTOMLEFT", 4, -8 );
	me.MaxScale.Update = _VirtualPlates.SetMaxScale;
	_G[ me.MaxScale:GetName().."Text" ]:SetText( L.CONFIG_MAXSCALE );
	me.MaxScale.tooltipText = L.CONFIG_MAXSCALE_DESC;

	LimitsOptions:SetHeight( me.MinScale:GetHeight() + me.MaxScaleEnabled:GetHeight() + me.MaxScale:GetHeight() + 72 );


	InterfaceOptions_AddCategory( me );
end
