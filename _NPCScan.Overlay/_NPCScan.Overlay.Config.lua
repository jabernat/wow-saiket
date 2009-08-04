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
  * Function: _NPCScan.Overlay.Config:ModuleOnClick                            *
  ****************************************************************************]]
function me:ModuleOnClick ( Enable )
	local Enable = self:GetChecked() == 1;

	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	Overlay[ Enable and "ModuleEnable" or "ModuleDisable" ]( self.Name );
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
