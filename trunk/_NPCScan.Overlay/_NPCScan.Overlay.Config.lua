--[[****************************************************************************
  * _NPCScan by Saiket                                                         *
  * _NPCScan.Overlay.Config.lua - Adds a configuration pane to enable and      *
  *   disable display modules like the WorldMap and BattlefieldMinimap.        *
  ****************************************************************************]]


local Overlay = _NPCScan.Overlay;
local L = _NPCScanLocalization.OVERLAY;
local me = CreateFrame( "Frame" );
Overlay.Config = me;

me.Modules = {};




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:ModuleCheckboxSetEnabled                 *
  ****************************************************************************]]
function me:ModuleCheckboxSetEnabled ( Enable )
	( Enable and BlizzardOptionsPanel_CheckButton_Enable or BlizzardOptionsPanel_CheckButton_Disable )( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:ModuleSliderSetEnabled                   *
  ****************************************************************************]]
function me:ModuleSliderSetEnabled ( Enable )
	( Enable and BlizzardOptionsPanel_Slider_Enable or BlizzardOptionsPanel_Slider_Disable )( self );
end


--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:ModuleEnabledOnClick                     *
  ****************************************************************************]]
function me:ModuleEnabledOnClick ()
	local Enable = self:GetChecked() == 1;

	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	Overlay[ Enable and "ModuleEnable" or "ModuleDisable" ]( self:GetParent().Name );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:ModuleAlphaOnValueChanged                *
  ****************************************************************************]]
function me:ModuleAlphaOnValueChanged ( Value )
	Overlay.ModuleSetAlpha( self:GetParent().Name, Value );
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config.ModuleRegister                           *
  ****************************************************************************]]
do
	local LastFrame;
	function me.ModuleRegister ( Name, Text )
		local Frame = CreateFrame( "Frame", "_NPCScanOverlayModule"..Name, me, "OptionsBoxTemplate" );
		Frame.Name = Name;
		me.Modules[ Name ] = Frame;

		_G[ Frame:GetName().."Title" ]:SetText( Text );
		Frame:SetPoint( "RIGHT", -8, 0 );
		if ( LastFrame ) then
			Frame:SetPoint( "TOPLEFT", LastFrame, "BOTTOMLEFT", 0, -16 );
		else
			Frame:SetPoint( "TOPLEFT", me.SubText, "BOTTOMLEFT", -2, -16 );
		end
		LastFrame = Frame;

		local Enabled = CreateFrame( "CheckButton", "$parentEnabled", Frame, "UICheckButtonTemplate" );
		Frame.Enabled = Enabled;
		Enabled:SetPoint( "TOPLEFT", 6, -6 );
		Enabled:SetWidth( 26 );
		Enabled:SetHeight( 26 );
		Enabled:SetScript( "OnClick", me.ModuleEnabledOnClick );
		local Label = _G[ Enabled:GetName().."Text" ];
		Label:SetText( L.CONFIG_ENABLE );
		Enabled:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );
		Enabled.SetEnabled = me.ModuleCheckboxSetEnabled;

		local Alpha = CreateFrame( "Slider", "$parentAlpha", Frame, "OptionsSliderTemplate" );
		Frame.Alpha = Alpha;
		Alpha:SetPoint( "TOP", 0, -16 );
		Alpha:SetPoint( "RIGHT", -8, 0 );
		Alpha:SetPoint( "LEFT", Label, "RIGHT", 16, 0 );
		Alpha:SetMinMaxValues( 0, 1 );
		Alpha:SetScript( "OnValueChanged", me.ModuleAlphaOnValueChanged );
		Alpha.SetEnabled = me.ModuleSliderSetEnabled;
		tinsert( Frame, Alpha );
		local AlphaName = Alpha:GetName();
		_G[ AlphaName.."Text" ]:SetText( L.CONFIG_ALPHA );
		_G[ AlphaName.."Low" ]:Hide();
		_G[ AlphaName.."High" ]:Hide();

		Frame:SetHeight( Alpha:GetHeight() + 16 + 4 );
		return Frame;
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:TableSetHeader                           *
  ****************************************************************************]]
do
	local function Recurse ( NewValue, Count, CurrentValue, ... )
		if ( Count == 0 ) then
			return NewValue;
		else
			return CurrentValue, Recurse( NewValue, Count - 1, ... );
		end
	end
	local function Append ( NewValue, ... ) -- Appends a value to a vararg list
		return Recurse( NewValue, select( "#", ... ), ... );
	end

	local SetHeaderBackup;
	function me:TableSetHeader ( ... )
		return SetHeaderBackup( self, Append( L.CONFIG_ZONE, ... ) );
	end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:TableAddRow                              *
  ****************************************************************************]]
	local AddRowBackup;
	function me:TableAddRow ( ... )
		local Map = Overlay.NPCMaps[ select( 4, ... ) ]; -- Arg 4 is NpcID
		if ( Map ) then
			return AddRowBackup( self, Append( Overlay.GetZoneName( Map ), ... ) );
		else
			return AddRowBackup( self, ... );
		end
	end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:TableOnShow                              *
  * Description: Hooks _NPCScan's "Search" table to add a zone column.         *
  ****************************************************************************]]
	local OnShowBackup = _NPCScan.Config.Search.OnShow;
	function me:TableOnShow ()
		self:SetScript( "OnShow", OnShowBackup );
		me.TableOnShow = nil;

		if ( not self.Table ) then
			self.Table = LibStub( "LibTextTable-1.0" ).New( nil, self.TableContainer );
			self.Table:SetAllPoints();
		end

		SetHeaderBackup = self.Table.SetHeader;
		AddRowBackup = self.Table.AddRow;
		self.Table.SetHeader = me.TableSetHeader;
		self.Table.AddRow = me.TableAddRow;

		OnShowBackup( self );
	end
end




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Config:default                                  *
  ****************************************************************************]]
function me:default ()
	Overlay.Synchronize();
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


	_NPCScan.Config.Search:SetScript( "OnShow", me.TableOnShow );
end
