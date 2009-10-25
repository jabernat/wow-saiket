--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * _VirtualPlates.Config.lua - Adds options to the Interface Options menu.    *
  ****************************************************************************]]


local _VirtualPlates = _VirtualPlates;
local L = _VirtualPlatesLocalization;
local me = CreateFrame( "Frame", "_VirtualPlatesConfig" );
_VirtualPlates.Config = me;

me.MinScale = CreateFrame( "Slider", "$parentMinScale", me, "OptionsSliderTemplate" );

local ScaleFactorOptions = CreateFrame( "Frame", "$parentScaleFactorOptions", me, "OptionsBoxTemplate" );
me.ScaleFactor1 = CreateFrame( "Slider", "$parentScaleFactor1", ScaleFactorOptions, "OptionsSliderTemplate" );
me.ScaleFactor2Enabled = CreateFrame( "CheckButton", "$parentScaleFactor2Enabled", ScaleFactorOptions, "InterfaceOptionsCheckButtonTemplate" );
me.ScaleFactor2 = CreateFrame( "Slider", "$parentScaleFactor2", ScaleFactorOptions, "OptionsSliderTemplate" );

me.ScaleFactorMin =  5;
me.ScaleFactorMax = 40;




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
  * Function: _VirtualPlates.Config.ScaleFactor1:OnValueChanged                *
  ****************************************************************************]]
function me.ScaleFactor1:OnValueChanged ( Value )
	me.SliderSetRange( me.ScaleFactor2, Value, me.ScaleFactorMax );
end

--[[****************************************************************************
  * Function: _VirtualPlates.Config.ScaleFactor2Enabled.setFunc                *
  ****************************************************************************]]
function me.ScaleFactor2Enabled.setFunc ( Enable )
	Enable = Enable == "1";

	( Enable and BlizzardOptionsPanel_Slider_Enable or BlizzardOptionsPanel_Slider_Disable )( me.ScaleFactor2 );
	me.ScaleFactor2.Value:SetFontObject( Enable and GameFontNormalSmall or GameFontDisableSmall );

	_VirtualPlates.SetScaleFactor2Enabled( Enable );
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


	SetupSlider( me.MinScale, L.CONFIG_SLIDER_FORMAT ):SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", 2, -24 );
	me.MinScale.Update = _VirtualPlates.SetMinScale;
	_G[ me.MinScale:GetName().."Text" ]:SetText( L.CONFIG_MINSCALE );
	me.MinScale.tooltipText = L.CONFIG_MINSCALE_DESC;
	me.SliderSetRange( me.MinScale, 0, 1 );


	-- Scale factor options section
	ScaleFactorOptions:SetPoint( "TOPLEFT", me.MinScale, "BOTTOMLEFT", -4, -40 );
	ScaleFactorOptions:SetPoint( "BOTTOMRIGHT", -14, 16 );
	_G[ ScaleFactorOptions:GetName().."Title" ]:SetText( L.CONFIG_SCALEFACTOR1 );

	SetupSlider( me.ScaleFactor1, L.CONFIG_SLIDERYARD_FORMAT ):SetPoint( "TOPLEFT", 16, -8 );
	me.ScaleFactor1.Update = _VirtualPlates.SetScaleFactor1;
	me.ScaleFactor1.tooltipText = L.CONFIG_SCALEFACTOR1_DESC;
	me.SliderSetRange( me.ScaleFactor1, me.ScaleFactorMin, me.ScaleFactorMax );

	me.ScaleFactor2Enabled:SetPoint( "TOPLEFT", me.ScaleFactor1, "BOTTOMLEFT", -4, -28 );
	local Label = _G[ me.ScaleFactor2Enabled:GetName().."Text" ];
	Label:SetText( L.CONFIG_SCALEFACTOR2ENABLE );
	me.ScaleFactor2Enabled:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );
	me.ScaleFactor2Enabled.tooltipText = L.CONFIG_SCALEFACTOR2ENABLE_DESC;

	SetupSlider( me.ScaleFactor2, L.CONFIG_SLIDERYARD_FORMAT ):SetPoint( "TOPLEFT", me.ScaleFactor2Enabled, "BOTTOMLEFT", 4, -8 );
	me.ScaleFactor2.Update = _VirtualPlates.SetScaleFactor2;
	_G[ me.ScaleFactor2:GetName().."Text" ]:SetText( L.CONFIG_SCALEFACTOR2 );
	me.ScaleFactor2.tooltipText = L.CONFIG_SCALEFACTOR2_DESC;


	InterfaceOptions_AddCategory( me );
end
