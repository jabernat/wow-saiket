--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.lua - Tools panel for _NPCScan and _NPCScan.Overlay.        *
  ****************************************************************************]]


local ADDON_NAME, NS = ...;
_NPCScan.Tools = NS;
NS.Callbacks = LibStub( "CallbackHandler-1.0" ):New( NS );

local Panel = _NPCScan.ToolsPanel; -- Blank panel created by _NPCScan
NS.Panel = Panel;
Panel.Controls = CreateFrame( "Frame", nil, Panel );
Panel.Up = CreateFrame( "Button", "_NPCScanToolsTableUp", Panel.Controls );
Panel.Down = CreateFrame( "Button", "_NPCScanToolsTableDown", Panel.Controls );
Panel.Container = CreateFrame( "Frame", nil, Panel );
Panel.Edit = CreateFrame( "EditBox", "_NPCScanToolsEdit", Panel, "InputBoxTemplate" );
Panel.Keys = CreateFrame( "Frame", nil, Panel );




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
	local function RowOnClick ( Row, Button )
		if ( Button == "RightButton" ) then -- Select text for copying.
			Panel.Edit:SetElement( GetMouseoverRegion( Row:GetElements() ) );
		else
			Panel.Edit:SetElement();
			if ( not Panel.Table:SetSelection( Row ) ) then
				Panel.Table:SetSelection(); -- Clear selection if row already selected.
			end
		end
	end
	--- Adds extra functionality to new table rows.
	local function RowHook ( Row, ... )
		Row:SetScript( "OnClick", RowOnClick );
		return Row, ...;
	end
	local CreateRow;
	--- Hooks row methods when a new row is created.
	local function OnCreateRow ( Table, ... )
		return RowHook( CreateRow( Table, ... ) );
	end
	--- Enables context sensitive actions based on which row is selected.
	local function OnSelect ( self )
		return NS.Callbacks:Fire( "OnSelectNPC", NS:GetSelectedNPC() );
	end
	--- Creates the data table and fills it when first shown.
	function Panel:OnShow ()
		self:SetScript( "OnShow", nil );
		self.OnShow = nil;

		self.Table = LibStub( "LibTextTable-1.1" ).New( nil, self.Container );
		self.Table:SetAllPoints();
		self.Table.OnSelect = OnSelect;

		self.Table:SetHeader(
			NS.L.NPC_ID, NS.L.NPC_NAME, NS.L.WORLDMAP_ID, NS.L.WORLDMAP_LEVEL, NS.L.WORLDMAP_NAME );
		self.Table:SetSortHandlers( true, true, true, true, true );
		self.Table:SetSortColumn( 1 ); -- Default to NpcID
		self.Table.CreateRow, CreateRow = OnCreateRow, self.Table.CreateRow;
		self.Edit:SetFontObject( self.Table.ElementFont );

		local NpcIDs = {};
		for WorldMapID, WorldMap in pairs( NS.NPCData.Sightings ) do
			for Floor, NPCs in pairs( WorldMap ) do
				for NpcID in pairs( NPCs ) do
					NpcIDs[ NpcID ] = true;
					self.Table:AddRow( nil,
						NpcID, NS.NPCData.Names[ NpcID ],
						WorldMapID, Floor,
						GetMapNameByID( WorldMapID ) or "" );
				end
			end
		end
		-- Add entries for mapless NPCs
		for NpcID, Name in pairs( NS.NPCData.Names ) do
			if ( not NpcIDs[ NpcID ] ) then
				self.Table:AddRow( nil, NpcID, Name, 0, 0, "" );
			end
		end
	end
end
--- Initialize once data files and controls load.
function Panel:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == ADDON_NAME ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		-- Fix Wowhead's invalid map floors
		local MapIDBackup = GetCurrentMapAreaID();
		local MapIDs = {};
		for MapID in pairs( NS.NPCData.Sightings ) do
			MapIDs[ #MapIDs + 1 ] = MapID;
		end
		for _, MapID in ipairs( MapIDs ) do
			local FloorNPCs = NS.NPCData.Sightings[ MapID ][ 0 ];
			if ( FloorNPCs ) then
				SetMapByID( MapID );
				if ( GetNumDungeonMapLevels() >= 1 ) then
					-- Floor 0 is invalid; Wowhead intends points for parent map instead
					assert( ZoomOut(), "Multi-level worldmap has no parent worldmap." );
					local MapIDNew, FloorNew = GetCurrentMapAreaID(), GetCurrentMapDungeonLevel();

					-- Merge old floor into new one
					if ( not NS.NPCData.Sightings[ MapIDNew ] ) then
						NS.NPCData.Sightings[ MapIDNew ] = {};
					end
					if ( not NS.NPCData.Sightings[ MapIDNew ][ FloorNew ] ) then
						NS.NPCData.Sightings[ MapIDNew ][ FloorNew ] = {};
					end
					local FloorNPCsNew = NS.NPCData.Sightings[ MapIDNew ][ FloorNew ];
					for NpcID, Points in pairs( FloorNPCs ) do
						FloorNPCsNew[ NpcID ] = ( FloorNPCsNew[ NpcID ] or "" )..Points;
					end

					NS.NPCData.Sightings[ MapID ][ 0 ] = nil;
					if ( next( NS.NPCData.Sightings[ MapID ] ) == nil ) then -- Old map is now empty
						NS.NPCData.Sightings[ MapID ] = nil;
					end
				end
			end
		end
		SetMapByID( MapIDBackup );

		self:SetScript( "OnShow", self.OnShow );
		if ( self:IsVisible() ) then
			self:OnShow();
		end
	end
end


--- Registers keys when shown out of combat.
function Panel.Keys:OnShow ()
	SetOverrideBindingClick( self, false, "UP", Panel.Up:GetName() );
	SetOverrideBindingClick( self, false, "DOWN", Panel.Down:GetName() );
end
Panel.Keys.OnHide = ClearOverrideBindings;
Panel.Keys.PLAYER_REGEN_DISABLED = Panel.Keys.Hide;
Panel.Keys.PLAYER_REGEN_ENABLED = Panel.Keys.Show;
--- Scroll selection up.
function Panel.Up:OnClick ()
	local Row = Panel.Table:GetSelection();
	if ( not Row or not Panel.Table:SetSelectionByIndex( Row:GetID() - 1 ) ) then
		Panel.Table:SetSelectionByIndex( #Panel.Table.Rows );
	end
end
--- Scroll selection down.
function Panel.Down:OnClick ()
	local Row = Panel.Table:GetSelection();
	if ( not Row or not Panel.Table:SetSelectionByIndex( Row:GetID() + 1 ) ) then
		Panel.Table:SetSelectionByIndex( 1 );
	end
end


--- Mimic region Element with this editbox to copy text contents.
function Panel.Edit:SetElement ( Element )
	if ( not Element ) then
		return self:Hide();
	end
	self:SetParent( Element:GetParent() );
	self:SetAllPoints( Element );
	self:SetText( Element:GetText() or "" );
	self:SetJustifyH( Element:GetJustifyH() );
	self:Show();
	self:HighlightText();
end


--- Register context sensitive GUI Control to update when selection changes.
function NS:AddControl ( Control )
	local Controls = Panel.Controls;
	Control:SetParent( Controls );
	Control:SetPoint( "BOTTOMLEFT", #Controls == 0 and Panel.Down or Controls[ #Controls ], "BOTTOMRIGHT", 2, 0 );
	Controls:SetHeight( math.max( Controls:GetHeight(), Control:GetHeight() ) );
	table.insert( Controls, Control );
end
--- @return Data for selected NPC entry if one is selected.
function NS:GetSelectedNPC ()
	if ( Panel.Table ) then
		local Row = Panel.Table:GetSelection();
		if ( Row ) then
			return select( 2, Row:GetData() );
		end
	end
end




Panel:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
Panel:RegisterEvent( "ADDON_LOADED" );

local Title = Panel:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
Title:SetPoint( "TOPLEFT", 16, -16 );
Title:SetText( Panel.name );
local SubText = Panel:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
SubText:SetPoint( "TOPLEFT", Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( NS.L.DESC );

-- Control panel for selected NPC
Panel.Controls:SetPoint( "BOTTOMLEFT", 16, 16 );
Panel.Controls:SetPoint( "RIGHT", -16, 0 );
Panel.Controls:SetHeight( 1e-3 );

local function SetupArrowButton ( Button, Direction )
	Button:SetSize( 10, 10 );
	Button:SetHitRectInsets( 2, 2, 2, 2 );
	Button:SetNormalTexture( [[Interface\MainMenuBar\UI-MainMenu-Scroll]]..Direction..[[Button-Up]] );
	Button:GetNormalTexture():SetTexCoord( 0.2, 0.8, 0.2, 0.8 );
	Button:SetPushedTexture( [[Interface\MainMenuBar\UI-MainMenu-Scroll]]..Direction..[[Button-Down]] );
	Button:GetPushedTexture():SetTexCoord( 0.2, 0.8, 0.2, 0.8 );
	Button:SetHighlightTexture( [[Interface\MainMenuBar\UI-MainMenu-Scroll]]..Direction..[[Button-Highlight]] );
	Button:GetHighlightTexture():SetTexCoord( 0.2, 0.8, 0.2, 0.8 );
	Button:SetScript( "OnClick", Button.OnClick );
	return Button;
end
SetupArrowButton( Panel.Down, "Down" ):SetPoint( "BOTTOMLEFT", -4, 0 );
SetupArrowButton( Panel.Up, "Up" ):SetPoint( "BOTTOMLEFT", Panel.Down, "TOPLEFT" );

Panel.Container:SetPoint( "TOPLEFT", SubText, -2, -28 );
Panel.Container:SetPoint( "BOTTOMRIGHT", Panel.Controls, "TOPRIGHT", 0, 8 );
Panel.Container:SetBackdrop( { bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]; } );

local Edit = Panel.Edit;
Edit:Hide();
Edit:SetScript( "OnEnterPressed", Edit.ClearFocus );
Edit:SetScript( "OnEscapePressed", Edit.ClearFocus );
Edit:SetScript( "OnEditFocusLost", Edit.Hide );

local Keys = Panel.Keys;
Keys:Hide();
Keys:SetScript( "OnShow", Keys.OnShow );
Keys:SetScript( "OnHide", Keys.OnHide );
Keys:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
Keys:RegisterEvent( "PLAYER_REGEN_DISABLED" );
Keys:RegisterEvent( "PLAYER_REGEN_ENABLED" );
if ( not InCombatLockdown() ) then
	Keys:PLAYER_REGEN_ENABLED();
end