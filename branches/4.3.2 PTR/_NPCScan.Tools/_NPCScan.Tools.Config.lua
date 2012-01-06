--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Config.lua - Adds a configuration pane to manage the        *
  *   Overlay module.                                                          *
  ****************************************************************************]]


local Tools = select( 2, ... );
local L = Tools.L;
local NS = CreateFrame( "Frame" );
Tools.Config = NS;

NS.Controls = CreateFrame( "Frame", nil, NS );
NS.TableContainer = CreateFrame( "Frame", nil, NS );
NS.EditBox = CreateFrame( "EditBox", "_NPCScanToolsConfigEditBox", nil, "InputBoxTemplate" );




do
	--- @return The first region in ... that is under the cursor.
	local function GetMouseoverRegion ( ... )
		for Index = 1, select( "#", ... ) do
			local Region = select( Index, ... );
			if ( Region:IsMouseOver() ) then
				return Region;
			end
		end
	end
	--- Adds additional click actions to table rows.
	function NS:TableRowOnClick ( Button )
		if ( Button == "RightButton" ) then -- Select text for copying.
			NS.EditBox:SetElement( GetMouseoverRegion( self:GetRegions() ) );
		else -- Clear selection if row already selected.
			NS.EditBox:SetElement();
			local Table = self:GetParent().Table;
			if ( not Table:SetSelection( self ) ) then
				Table:SetSelection();
			end
		end
	end
end
do
	local function AddHooks( Row, ... )
		Row:SetScript( "OnClick", NS.TableRowOnClick );
		return Row, ...;
	end
	local CreateRowBackup;
	--- Hooks row methods when a new row is created.
	function NS:TableCreateRow ( ... )
		return AddHooks( CreateRowBackup( self, ... ) );
	end
	--- Enables context sensitive actions based on which row is selected.
	local function OnSelect ( self, NpcID, ... )
		for Index, Control in ipairs( NS.Controls ) do
			if ( Control.OnSelect ) then
				Control:OnSelect( NpcID, ... );
			end
		end
	end
	--- Creates the data table and fills it when first shown.
	function NS:OnShow ()
		self:SetScript( "OnShow", nil );
		NS.OnShow = nil;

		NS.Table = LibStub( "LibTextTable-1.1" ).New( nil, NS.TableContainer );
		NS.Table:SetAllPoints();
		NS.Table.OnSelect = OnSelect;

		NS.Table:SetHeader( L.CONFIG_MAPID, L.CONFIG_ID, L.CONFIG_NAME, L.CONFIG_DISPLAYID );
		NS.Table:SetSortHandlers( true, true, true, true );
		NS.Table:SetSortColumn( 1 ); -- Default to MapID
		CreateRowBackup = NS.Table.CreateRow;
		NS.Table.CreateRow = NS.TableCreateRow;

		NS.EditBox:SetFontObject( NS.Table.ElementFont );

		for NpcID, Name in pairs( Tools.NPCNames ) do
			local MapID = Tools.NPCMapIDs[ NpcID ];
			NS.Table:AddRow( NpcID,
				tostring( GetMapNameByID( MapID ) or MapID or "" ),
				NpcID, Name,
				Tools.NPCDisplayIDs[ NpcID ] or 0 );
		end
	end
end


--- Mimic region Element with this editbox to copy text contents.
function NS.EditBox:SetElement ( Element )
	if ( Element ) then
		self:SetParent( Element:GetParent() );
		self:SetAllPoints( Element );
		self:SetText( Element:GetText() or "" );
		self:Show();
		self:SetFocus();
		self:HighlightText();
	else
		self:Hide();
	end
end
--- Removes the mimic editbox if its target gets hidden.
function NS.EditBox:OnHide ()
	self:ClearFocus();
	self:SetText( "" );
	self:Hide(); -- Hide when parent is hidden
end


--- Register context sensitive GUI Control to update when selection changes.
function NS.Controls:Add ( Control )
	Control:SetParent( self );
	if ( #self == 0 ) then
		Control:SetPoint( "BOTTOMLEFT" );
	else
		Control:SetPoint( "LEFT", self[ #self ], "RIGHT" );
	end

	self[ #self + 1 ] = Control;
	if ( Control.OnSelect ) then
		local Selection = NS.Table and NS.Table:GetSelection();
		if ( Selection ) then
			Control:OnSelect( Selection:GetData() );
		else
			Control:OnSelect();
		end
	end
end




NS.name = L.CONFIG_TITLE;
NS.parent = _NPCScan.Config.name;
NS:Hide();
NS:SetScript( "OnShow", NS.OnShow );

-- Pane title
local Title = NS:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( L.CONFIG_TITLE );
local SubText = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.CONFIG_DESC );


-- Control panel for selected NPC
NS.Controls:SetPoint( "BOTTOMLEFT", 16, 16 );
NS.Controls:SetPoint( "RIGHT", -16, 0 );
NS.Controls:SetHeight( 24 );


-- Place table
NS.TableContainer:SetPoint( "TOPLEFT", SubText, -2, -28 );
NS.TableContainer:SetPoint( "BOTTOMRIGHT", NS.Controls, "TOPRIGHT" );
NS.TableContainer:SetBackdrop( { bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]; } );

NS.EditBox:Hide();
NS.EditBox:SetScript( "OnHide", NS.EditBox.OnHide );
NS.EditBox:SetScript( "OnEnterPressed", NS.EditBox.OnHide );
NS.EditBox:SetScript( "OnEscapePressed", NS.EditBox.OnHide );


InterfaceOptions_AddCategory( NS );