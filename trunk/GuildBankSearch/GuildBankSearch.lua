--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * GuildBankSearch.lua - Adds a search filter to the guild bank.              *
  ****************************************************************************]]


local NS = select( 2, ... );
GuildBankSearch = NS;
local L = NS.L;

NS.Frame = CreateFrame( "Frame", "GuildBankSearchFrame", GuildBankFrame );
NS.Frame.UpdateRate = 0.5;
NS.Frame.NextUpdate = 0;
NS.Frame.NeedUpdate = false;

NS.ToggleButton = CreateFrame( "Button", nil, GuildBankFrame, "UIPanelButtonTemplate" );

NS.Clear = CreateFrame( "Button", nil, NS.Frame, "UIPanelButtonTemplate" );
NS.Name = CreateFrame( "EditBox", "$parentName", NS.Frame, "InputBoxTemplate" );
NS.Text = CreateFrame( "EditBox", "$parentText", NS.Frame, "InputBoxTemplate" );
NS.Quality = CreateFrame( "Frame", "$parentQuality", NS.Frame, "UIDropDownMenuTemplate" );
NS.ItemLevelMin = CreateFrame( "EditBox", "$parentItemLevelMin", NS.Frame, "InputBoxTemplate" );
NS.ItemLevelMax = CreateFrame( "EditBox", "$parentItemLevelMax", NS.Frame, "InputBoxTemplate" );
NS.ReqLevelMin = CreateFrame( "EditBox", "$parentReqLevelMin", NS.Frame, "InputBoxTemplate" );
NS.ReqLevelMax = CreateFrame( "EditBox", "$parentReqLevelMax", NS.Frame, "InputBoxTemplate" );

NS.CategorySection = CreateFrame( "Frame", "$parentCategory", NS.Frame, "OptionsBoxTemplate" );
NS.Type = CreateFrame( "Frame", "$parentType", NS.CategorySection, "UIDropDownMenuTemplate" );
NS.SubType = CreateFrame( "Frame", "$parentSubType", NS.CategorySection, "UIDropDownMenuTemplate" );
NS.Slot = CreateFrame( "Frame", "$parentSlot", NS.CategorySection, "UIDropDownMenuTemplate" );


--- Filter parameter table, where filter is active if any keys exist.
-- Initially false so FilterClear() will update all fields to nil.
local Filter = {
	Name = false;
	Text = false;
	Quality = false;
	Type = false;
	SubType = false;
	Slot = false;
	ItemLevelMin = false;
	ItemLevelMax = false;
	ReqLevelMin = false;
	ReqLevelMax = false;
};
NS.Filter = Filter;

NS.Qualities = {};
NS.Types = { GetAuctionItemClasses() };
NS.SubTypes = {};
NS.Slots = {}; -- Sorted list of inventory types that can be searched for
NS.SlotGroups = { -- Categories paired with the inventory types that can match them (can be multiple)
	[ "ENCHSLOT_WEAPON" ] = { -- Localized as generic "Weapon"
		[ "INVTYPE_2HWEAPON" ] = true;
		[ "INVTYPE_HOLDABLE" ] = true;
		[ "INVTYPE_SHIELD" ] = true;
		[ "INVTYPE_WEAPON" ] = true;
		[ "INVTYPE_WEAPONMAINHAND" ] = true;
		[ "INVTYPE_WEAPONOFFHAND" ] = true;
	};
	[ "INVTYPE_AMMO" ] = { [ "INVTYPE_AMMO" ] = true; };
	[ "INVTYPE_BAG" ] = {
		[ "INVTYPE_BAG" ] = true;
		[ "INVTYPE_QUIVER" ] = true;
	};
	[ "INVTYPE_BODY" ] = { [ "INVTYPE_BODY" ] = true; };
	[ "INVTYPE_CHEST" ] = {
		[ "INVTYPE_CHEST" ] = true;
		[ "INVTYPE_ROBE" ] = true;
	};
	[ "INVTYPE_CLOAK" ] = { [ "INVTYPE_CLOAK" ] = true; };
	[ "INVTYPE_FEET" ] = { [ "INVTYPE_FEET" ] = true; };
	[ "INVTYPE_FINGER" ] = { [ "INVTYPE_FINGER" ] = true; };
	[ "INVTYPE_HAND" ] = { [ "INVTYPE_HAND" ] = true; };
	[ "INVTYPE_HEAD" ] = { [ "INVTYPE_HEAD" ] = true; };
	[ "INVTYPE_LEGS" ] = { [ "INVTYPE_LEGS" ] = true; };
	[ "INVTYPE_NECK" ] = { [ "INVTYPE_NECK" ] = true; };
	[ "INVTYPE_RANGED" ] = {
		[ "INVTYPE_RANGED" ] = true;
		[ "INVTYPE_RANGEDRIGHT" ] = true;
		[ "INVTYPE_THROWN" ] = true;
	};
	[ "INVTYPE_RELIC" ] = { [ "INVTYPE_RELIC" ] = true; };
	[ "INVTYPE_SHOULDER" ] = { [ "INVTYPE_SHOULDER" ] = true; };
	[ "INVTYPE_TABARD" ] = { [ "INVTYPE_TABARD" ] = true; };
	[ "INVTYPE_TRINKET" ] = { [ "INVTYPE_TRINKET" ] = true; };
	[ "INVTYPE_WAIST" ] = { [ "INVTYPE_WAIST" ] = true; };
	[ "INVTYPE_WRIST" ] = { [ "INVTYPE_WRIST" ] = true; };
};

NS.ButtonMismatchAlpha = 0.25;
NS.LogMismatchColor = { r = 0.25; g = 0.25; b = 0.25; };
NS.Buttons = {}; -- Cache of all item buttons in bank view




--- Updates filter when name parameter changes.
function NS.Name:OnTextChanged ()
	local Text = self:GetText();
	Filter.Name = Text ~= "" and Text:lower() or nil;
	NS.FilterUpdate();
end
--- Updates filter when text parameter changes.
function NS.Text:OnTextChanged ()
	local Text = self:GetText();
	Filter.Text = Text ~= "" and Text:lower() or nil;
	NS.FilterUpdate();
end
--- @return An iterator to list all qualities.
function NS.Quality.IterateOptions ()
	return ipairs( NS.Qualities );
end

--- Updates the subtype dropdown when a type is chosen.
function NS.Type:OnSelect ( Dropdown, Type )
	if ( Filter.Type ~= Type ) then
		NS.SubType.OnSelect( nil, NS.SubType ); -- Remove subtype filter
		if ( not Type ) then
			UIDropDownMenu_DisableDropDown( NS.SubType );
		else
			UIDropDownMenu_EnableDropDown( NS.SubType );
		end
		NS.DropdownOnSelect( self, Dropdown, Type );
	end
end
--- @return An iterator to list all types.
function NS.Type.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = NS.Types[ Index ];
		return Label, Label;
	end;
end
--- @return An iterator to list all sub-types.
function NS.SubType.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = NS.SubTypes[ Filter.Type ][ Index ];
		return Label, Label;
	end;
end
--- @return An iterator to list all gear slots.
function NS.Slot.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Slot = NS.Slots[ Index ];
		return Slot, _G[ Slot ];
	end;
end

--- Generic handler to update the filter when one of the level edit boxes changes.
function NS:LevelEditBoxOnTextChanged ()
	local NewLevel = self:GetText() ~= "" and self:GetNumber() or nil;
	if ( NewLevel ~= Filter[ self.Parameter ] ) then
		Filter[ self.Parameter ] = NewLevel;
		NS.FilterUpdate();
	end
end
--- Generic handler to update the filter when a dropdown's value changes.
function NS:DropdownOnSelect ( Dropdown, Value )
	if ( Value ~= Filter[ Dropdown.Parameter ] ) then
		UIDropDownMenu_SetText( Dropdown, self and self.value or L.ALL );
		Filter[ Dropdown.Parameter ] = Value;
		NS.FilterUpdate();
	end
end
--- Generic handler to construct dropdown menus using their custom iterators.
function NS:DropdownInitialize ()
	local CurrentValue = Filter[ self.Parameter ];
	local Info = UIDropDownMenu_CreateInfo();
	Info.arg1 = self; -- Arg2 left nil for unfiltered
	Info.text = L.ALL;
	Info.checked = CurrentValue == nil;
	Info.func = self.OnSelect;
	UIDropDownMenu_AddButton( Info );
	for Value, Label in self.IterateOptions() do
		Info.arg2, Info.text = Value, Label;
		Info.checked = CurrentValue == Value;
		UIDropDownMenu_AddButton( Info );
	end
end




--- Resets all filter parameters to not filter anything.
function NS.FilterClear ()
	CloseDropDownMenus(); -- Close dropdown if open

	NS.Name:SetText( "" );
	NS.Text:SetText( "" );
	NS.Quality.OnSelect( nil, NS.Quality );
	NS.ItemLevelMin:SetText( "" );
	NS.ItemLevelMax:SetText( "" );
	NS.ReqLevelMin:SetText( "" );
	NS.ReqLevelMax:SetText( "" );

	-- Item category fields
	NS.Type.OnSelect( nil, NS.Type ); -- Also clears SubType
	NS.Slot.OnSelect( nil, NS.Slot );
end

--- Requests an update to the bank or log display.
-- @param Force  Executes the update on the next frame, ignoring throttling.
function NS.FilterUpdate ( Force )
	NS.Frame.NeedUpdate = true;
	if ( Force ) then
		NS.Frame.NextUpdate = 0;
	end
end
--- @return True if any filter parameters are set.
function NS.IsFilterDefined ()
	return next( Filter ) ~= nil;
end

do
	local Tooltip = CreateFrame( "GameTooltip", "$parentTooltip", NS.Frame );
	-- Add template text lines
	Tooltip:AddFontStrings( Tooltip:CreateFontString(), Tooltip:CreateFontString() );
	local LinesLeft, LinesRight = {}, {};

	local select = select;
	local FilterFunctions = {
		--- Case-insensitive plain text filter by item name.
		Name = function ( NamePattern, Name )
			return Name:lower():find( NamePattern, 1, true );
		end;
		--- Case-insensitive plain text filter by tooltip contents.
		Text = function ( TextPattern, _, ItemLink )
			Tooltip:SetOwner( NS.Frame, "ANCHOR_NONE" );
			Tooltip:SetHyperlink( ItemLink );
			if ( Tooltip:IsShown() ) then
				local NumLines = Tooltip:NumLines();
				-- Cache newly created lines
				for Line = #LinesLeft + 1, NumLines do
					LinesLeft[ Line ] = _G[ Tooltip:GetName().."TextLeft"..Line ];
					LinesRight[ Line ] = _G[ Tooltip:GetName().."TextRight"..Line ];
				end
				-- Search text on visible lines
				for Line = 2, NumLines do -- Skip name (first line)
					if ( LinesLeft[ Line ]:GetText():lower():find( TextPattern, 1, true )
						or ( LinesRight[ Line ]:IsShown()
							and LinesRight[ Line ]:GetText():lower():find( TextPattern, 1, true )
					) ) then
						return true;
					end
				end
			end
		end;
		--- Filter by item quality.
		Quality = function ( QualityFilter, _, _, Quality )
			return QualityFilter == Quality;
		end;
		--- Filter by item type.
		Type = function ( TypeFilter, ... )
			return TypeFilter == select( 6, ... );
		end;
		--- Filter by item sub-type.
		SubType = function ( SubTypeFilter, ... )
			return SubTypeFilter == select( 7, ... );
		end;
		--- Filter by item gear slot.
		Slot = function ( SlotGroup, ... )
			return NS.SlotGroups[ SlotGroup ][ select( 9, ... ) ];
		end;
		--- Filter by item iLvl lower boundary.
		ItemLevelMin = function ( Min, _, _, _, ItemLevel )
			return ItemLevel >= Min;
		end;
		--- Filter by item iLvl upper boundary.
		ItemLevelMax = function ( Max, _, _, _, ItemLevel )
			return ItemLevel <= Max;
		end;
		--- Filter by item required level lower boundary.
		ReqLevelMin = function ( Min, _, _, _, _, ReqLevel )
			return ReqLevel >= Min;
		end;
		--- Filter by item required level upper boundary.
		ReqLevelMax = function ( Max, _, _, _, _, ReqLevel )
			return ReqLevel <= Max;
		end;
	};

	local pairs = pairs;
	--- @return True if item info matches all filter parameters.
	local function MatchItemInfo ( ... )
		for Key, Value in pairs( Filter ) do
			if ( not FilterFunctions[ Key ]( Value, ... ) ) then
				return;
			end
		end
		return true; -- Matched all filters
	end
	local GetItemInfo = GetItemInfo;
	--- Tests an item against the current filter parameters.
	-- @param ItemLink  Link of item to test.
	-- @return True if the given ItemLink matches all filter parameters.
	function NS.MatchItem ( ItemLink )
		if ( ItemLink ) then
			return MatchItemInfo( GetItemInfo( ItemLink ) );
		end
	end
end

--- Restores an unfiltered view of the bank and log.
function NS.FilterSuspend ()
	for Index, Button in ipairs( NS.Buttons ) do
		Button:SetAlpha( 1 );
	end
	if ( GuildBankFrame.mode == "log" ) then
		GuildBankFrame_UpdateLog();
	end
end
do
	local GetGuildBankItemLink = GetGuildBankItemLink;
	--- Applies or refreshes the current filter to the bank or log view.
	function NS.FilterResume ()
		if ( not NS.IsFilterDefined() ) then
			return NS.FilterSuspend();
		end

		if ( GuildBankFrame.mode == "bank" ) then
			local Tab = GetCurrentGuildBankTab();
			if ( Tab <= GetNumGuildBankTabs() ) then
				for Index, Button in ipairs( NS.Buttons ) do
					Button:SetAlpha( NS.MatchItem( GetGuildBankItemLink( Tab, Index ) )
						and 1 or NS.ButtonMismatchAlpha );
				end
			end
		elseif ( GuildBankFrame.mode == "log" ) then
			GuildBankFrame_UpdateLog();
		end
	end
end




--- Hook to enable the filter depending on which bank view is displayed.
function NS.GuildBankFrameTabOnClick ()
	if ( GuildBankFrame.mode == "log" or GuildBankFrame.mode == "bank" ) then
		NS.ToggleButton:Enable();
	else
		NS.Frame:Hide();
		NS.ToggleButton:Disable();
	end
end
--- Hook to update the filter display when the bank view type changes.
function NS.GuildBankFrameUpdate ()
	NS.FilterUpdate( true );
end
do
	local AddMessageBackup = GuildBankMessageFrame.AddMessage;
	--- Hook that modifies added messages when a filter is active.
	function NS:GuildBankMessageFrameAddMessage ( Message, ... )
		if ( GuildBankFrame.mode == "log"
			and NS.Frame:IsShown() and NS.IsFilterDefined()
			and not NS.MatchItem( Message:match( "|H(item:[^|]+)|h" ) )
		) then
			local Color = NS.LogMismatchColor;
			-- Remove all color codes
			return AddMessageBackup( self,
				Message:gsub( "|c%x%x%x%x%x%x%x%x", "" ):gsub( "|r", "" ),
				Color.r, Color.g, Color.b, select( 4, ... ) );
		end
		return AddMessageBackup( self, Message, ... );
	end
end
do
	local InsertLinkBackup = ChatEdit_InsertLink;
	--- Hook to add linked items to the name filter edit box.
	function NS.ChatEditInsertLink ( Link, ... )
		if ( InsertLinkBackup( Link, ... ) ) then
			return true;
		elseif ( Link and NS.Name:IsVisible() ) then
			local Name = GetItemInfo( Link );
			if ( Name ) then
				NS.Name:SetText( Name );
				return true;
			end
		end
		return false;
	end
end




--- Makes room for the filter pane and refreshes the filter when shown.
function NS.Frame:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
	NS.ToggleButton:SetButtonState( "PUSHED", true );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", NS.Frame, "TOPRIGHT", -8, -2 );

	NS.FilterUpdate( true );
end
--- Undoes changes to bank window and clears any filter display when hidden.
function NS.Frame:OnHide ()
	PlaySound( "igCharacterInfoClose" );
	NS.ToggleButton:SetButtonState( "NORMAL" );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -1, -32 );
	NS.FilterSuspend();
end
--- Throttles filter display updates.
function NS.Frame:OnUpdate ( Elapsed )
	self.NextUpdate = self.NextUpdate - Elapsed;
	if ( self.NeedUpdate and self.NextUpdate <= 0 ) then
		self.NeedUpdate, self.NextUpdate = false, self.UpdateRate;

		NS.FilterResume();
	end
end
--- Forces a display update when bank contents change.
function NS.Frame:OnEvent ()
	NS.FilterUpdate( true );
end

--- Shows or hides the filter pane.
function NS.Toggle ()
	if ( NS.Frame:IsShown() ) then
		NS.Frame:Hide();
	else
		NS.Frame:Show();
	end
end




-- Fill in quality labels
for Index = 0, #ITEM_QUALITY_COLORS do
	NS.Qualities[ Index ] = ITEM_QUALITY_COLORS[ Index ].hex
		.._G[ "ITEM_QUALITY"..Index.."_DESC" ]..FONT_COLOR_CODE_CLOSE;
end
-- Fill in and sort subtypes
for Index, Type in ipairs( NS.Types ) do
	NS.SubTypes[ Type ] = { GetAuctionItemSubClasses( Index ) };
	sort( NS.SubTypes[ Type ] );
end
-- Sort types
sort( NS.Types ); -- Note: Use after subtypes are populated so indices don't get mixed up
-- Fill in and sort slots table
for InvType in pairs( NS.SlotGroups ) do
	tinsert( NS.Slots, InvType );
end
sort( NS.Slots, function ( Type1, Type2 )
	return _G[ Type1 ] < _G[ Type2 ];
end );

-- Cache all item buttons
for Index = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
	local Column = floor( ( Index - 1 ) / NUM_SLOTS_PER_GUILDBANK_GROUP ) + 1;
	local Slot = ( Index - 1 ) % NUM_SLOTS_PER_GUILDBANK_GROUP + 1;
	NS.Buttons[ Index ] = _G[ "GuildBankColumn"..Column.."Button"..Slot ];
	NS.Buttons[ Index ].searchOverlay:SetTexture();
end

-- Remove default UI's search functionality
GuildItemSearchBox:Hide();
GuildBankFrame:UnregisterEvent( "INVENTORY_SEARCH_UPDATE" );
for Index = 1, MAX_GUILDBANK_TABS do
	local Tab = _G[ "GuildBankTab"..Index.."Button" ];
	Tab:UnregisterEvent( "INVENTORY_SEARCH_UPDATE" );
	Tab.searchOverlay:SetTexture();
end


-- Set up filter button
NS.ToggleButton:SetSize( 100, 21 );
NS.ToggleButton:SetPoint( "TOPRIGHT", -11, -40 );
NS.ToggleButton:SetText( L.FILTER );
NS.ToggleButton:SetScript( "OnClick", NS.Toggle );


-- Set up filter pane
local Frame = NS.Frame;
Frame:Hide();
Frame:SetSize( 187, 409 );
Frame:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -2, -28 );
Frame:EnableMouse( true );
Frame:SetToplevel( true );

Frame:SetScript( "OnShow", Frame.OnShow );
Frame:SetScript( "OnHide", Frame.OnHide );
Frame:SetScript( "OnUpdate", Frame.OnUpdate );
Frame:SetScript( "OnEvent", Frame.OnEvent );
Frame:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" );
Frame:RegisterEvent( "GUILDBANKLOG_UPDATE" );


-- Artwork
local Label = Frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
Label:SetPoint( "TOPLEFT", 4, -10 );
Label:SetText( L.TITLE );

local Top = Frame:CreateTexture( nil, "BACKGROUND" );
Top:SetTexture( [[Interface\AuctionFrame\AuctionHouseDressUpFrame-Top]] );
Top:SetSize( 256, 276 );
Top:SetPoint( "TOPLEFT" );
local Bottom = Frame:CreateTexture( nil, "BACKGROUND" );
Bottom:SetTexture( [[Interface\AuctionFrame\AuctionHouseDressUpFrame-Bottom]] );
Bottom:SetSize( 256, 256 );
Bottom:SetPoint( "TOPLEFT", Top, "BOTTOMLEFT" );
local Corner = Frame:CreateTexture( nil, "BACKGROUND" );
Corner:SetTexture( [[Interface\AuctionFrame\AuctionHouseDressUpFrame-Corner]] );
Corner:SetSize( 32, 32 );
Corner:SetPoint( "TOPRIGHT", -5, -7 );


-- Close button
CreateFrame( "Button", nil, Frame, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", Corner, 6, 5 );

local Clear = NS.Clear;
Clear:SetSize( 45, 18 );
Clear:SetPoint( "TOPRIGHT", -31, -8 );
Clear:SetText( L.CLEAR );
Clear:SetScript( "OnClick", NS.FilterClear );


-- Filter controls
--- Sets up a dropdown filter control.
-- @param Parameter  Key in the Filter table.
local function InitializeDropdown ( self, Parameter, Label )
	self:SetPoint( "LEFT", -8, 0 );
	self:SetPoint( "RIGHT", -8, 0 );
	_G[ self:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	UIDropDownMenu_JustifyText( self, "LEFT" );
	if ( not self.OnSelect ) then
		self.OnSelect = NS.DropdownOnSelect;
	end
	self.initialize = NS.DropdownInitialize;
	self.Parameter = Parameter;
	self.Label = self:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	self.Label:SetText( Label );
	self.Label:SetPoint( "BOTTOMLEFT", self, "TOPLEFT", 24, 0 );
	return self;
end
--- Sets up a numeric editbox as a level filter control.
-- @param Parameter  Key in the Filter table.
local function InitializeLevelEditBox ( self, Parameter, Label )
	self:SetSize( 25, 16 );
	self:SetNumeric( true );
	self:SetMaxLetters( 3 );
	self:SetAutoFocus( false );
	self:SetScript( "OnTextChanged", NS.LevelEditBoxOnTextChanged );
	self.Parameter = Parameter;
	self.Label = self:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	self.Label:SetText( Label );
	return self;
end

local Name = NS.Name;
Name:SetHeight( 16 );
Name:SetAutoFocus( false );
Name:SetPoint( "TOP", Clear, "BOTTOM", 0, -20 );
Name:SetPoint( "LEFT", 16, 0 );
Name:SetPoint( "RIGHT", -16, 0 );
Name:SetScript( "OnTextChanged", Name.OnTextChanged );
local Label = Name:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
Label:SetPoint( "BOTTOMLEFT", Name, "TOPLEFT", 1, 0 );
Label:SetText( L.NAME );

local Text = NS.Text;
Text:SetHeight( 16 );
Text:SetAutoFocus( false );
Text:SetPoint( "TOP", Name, "BOTTOM", 0, -12 );
Text:SetPoint( "LEFT", Name );
Text:SetPoint( "RIGHT", Name );
Text:SetScript( "OnTextChanged", Text.OnTextChanged );
local Label = Text:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
Label:SetPoint( "BOTTOMLEFT", Text, "TOPLEFT", 1, 0 );
Label:SetText( L.TEXT );

InitializeDropdown( NS.Quality, "Quality", L.QUALITY ):SetPoint( "TOP", Text, "BOTTOM", 0, -12 );

-- Item level range
local ItemLevelMin = InitializeLevelEditBox( NS.ItemLevelMin, "ItemLevelMin", L.ITEM_LEVEL );
ItemLevelMin:SetPoint( "TOP", NS.Quality, "BOTTOM", 0, -16 );
ItemLevelMin:SetPoint( "LEFT", 16, 0 );
local ItemLevelMax = InitializeLevelEditBox( NS.ItemLevelMax, "ItemLevelMax", L.LEVELRANGE_SEPARATOR );
ItemLevelMax.Label:SetPoint( "LEFT", ItemLevelMin, "RIGHT", 2, 0 );
ItemLevelMax:SetPoint( "LEFT", ItemLevelMax.Label, "RIGHT", 8, 0 );
ItemLevelMin.Label:SetPoint( "CENTER", ItemLevelMax.Label ); -- Center above dash between edit boxes
ItemLevelMin.Label:SetPoint( "BOTTOM", ItemLevelMin, "TOP" );

-- Required level range
local ReqLevelMax = InitializeLevelEditBox( NS.ReqLevelMax, "ReqLevelMax", L.REQUIRED_LEVEL );
ReqLevelMax:SetPoint( "TOP", NS.ItemLevelMin );
ReqLevelMax:SetPoint( "RIGHT", -24, 0 );
local ReqLevelMin = InitializeLevelEditBox( NS.ReqLevelMin, "ReqLevelMin", L.LEVELRANGE_SEPARATOR );
ReqLevelMin.Label:SetPoint( "RIGHT", ReqLevelMax, "LEFT", -8, 0 );
ReqLevelMin:SetPoint( "RIGHT", ReqLevelMin.Label, "LEFT", -2, 0 );
ReqLevelMax.Label:SetPoint( "CENTER", ReqLevelMin.Label );
ReqLevelMax.Label:SetPoint( "BOTTOM", ReqLevelMax, "TOP" );

-- Item category section
local CategorySection = NS.CategorySection;
_G[ CategorySection:GetName().."Title" ]:SetText( L.ITEM_CATEGORY );
CategorySection:SetPoint( "TOP", ItemLevelMin, "BOTTOM", 0, -38 );
CategorySection:SetPoint( "LEFT", 8, 0 );
CategorySection:SetPoint( "BOTTOMRIGHT", -16, 16 );
local Background = CategorySection:CreateTexture( nil, "BACKGROUND" );
Background:SetPoint( "TOPLEFT", 4, -4 );
Background:SetPoint( "BOTTOMRIGHT", -4, 4 );
Background:SetTexture( 1, 1, 1, 0.2 );

InitializeDropdown( NS.Type, "Type", L.TYPE ):SetPoint( "TOP", 0, -16 );
InitializeDropdown( NS.SubType, "SubType", L.SUB_TYPE ):SetPoint( "TOP", NS.Type, "BOTTOM", 0, -6 );
InitializeDropdown( NS.Slot, "Slot", L.SLOT ):SetPoint( "TOP", NS.SubType, "BOTTOM", 0, -16 );


-- Hooks
hooksecurefunc( "GuildBankFrameTab_OnClick", NS.GuildBankFrameTabOnClick );
hooksecurefunc( "GuildBankFrame_Update", NS.GuildBankFrameUpdate );
GuildBankMessageFrame.AddMessage = NS.GuildBankMessageFrameAddMessage;
ChatEdit_InsertLink = NS.ChatEditInsertLink;

NS.FilterClear();
wipe( Filter ); -- FilterClear won't fire edit box OnTextChanged handlers, so clear manually.
NS.FilterUpdate( true );