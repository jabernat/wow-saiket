--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * GuildBankSearch.lua - Adds a search filter to the guild bank.              *
  ****************************************************************************]]


local L = GuildBankSearchLocalization;
local me = CreateFrame( "Frame", "GuildBankSearch", GuildBankFrame );

local FilterButton = CreateFrame( "Button", nil, GuildBankFrame, "UIPanelButtonTemplate" );
me.FilterButton = FilterButton;
local Pane = CreateFrame( "Frame", nil, me );
me.Pane = Pane;

Pane.ClearButton = CreateFrame( "Button", nil, me, "UIPanelButtonTemplate" );
Pane.NameEditBox = CreateFrame( "EditBox", "GuildBankSearchNameEditBox", me, "InputBoxTemplate" );
Pane.QualityMenu = CreateFrame( "Frame", "GuildBankSearchQualityMenu", me, "UIDropDownMenuTemplate" );
Pane.ItemLevelMinEditBox = CreateFrame( "EditBox", "GuildBankSearchItemLevelMinEditBox", me, "InputBoxTemplate" );
Pane.ItemLevelMaxEditBox = CreateFrame( "EditBox", "GuildBankSearchItemLevelMaxEditBox", me, "InputBoxTemplate" );
Pane.ReqLevelMinEditBox = CreateFrame( "EditBox", "GuildBankSearchReqLevelMinEditBox", me, "InputBoxTemplate" );
Pane.ReqLevelMaxEditBox = CreateFrame( "EditBox", "GuildBankSearchReqLevelMaxEditBox", me, "InputBoxTemplate" );

Pane.CategorySection = CreateFrame( "Frame", "GuildBankSearchCategorySection", Pane, "OptionsBoxTemplate" );
Pane.TypeMenu = CreateFrame( "Frame", "GuildBankSearchTypeMenu", Pane.CategorySection, "UIDropDownMenuTemplate" );
Pane.SubTypeMenu = CreateFrame( "Frame", "GuildBankSearchSubTypeMenu", Pane.CategorySection, "UIDropDownMenuTemplate" );
Pane.SlotMenu = CreateFrame( "Frame", "GuildBankSearchSlotMenu", Pane.CategorySection, "UIDropDownMenuTemplate" );


-- Initially false so Clear() will update all fields to nil
me.NamePattern = false;
me.Quality = false;
me.Type = false;
me.SubType = false;
me.Slot = false;
me.ItemLevelMin = false;
me.ItemLevelMax = false;
me.ReqLevelMin = false;
me.ReqLevelMax = false;

me.Qualities = {};
me.Types = { GetAuctionItemClasses() };
me.SubTypes = {};
me.Slots = {}; -- Sorted list of inventory types that can be searched for
me.SlotGroups = {
	[ "INVTYPE_AMMO" ] = { [ "INVTYPE_AMMO" ] = true; };
	[ "INVTYPE_HEAD" ] = { [ "INVTYPE_HEAD" ] = true; };
	[ "INVTYPE_NECK" ] = { [ "INVTYPE_NECK" ] = true; };
	[ "INVTYPE_SHOULDER" ] = { [ "INVTYPE_SHOULDER" ] = true; };
	[ "INVTYPE_BODY" ] = { [ "INVTYPE_BODY" ] = true; };
	[ "INVTYPE_CHEST" ] = { [ "INVTYPE_CHEST" ] = true; [ "INVTYPE_ROBE" ] = true; };
	[ "INVTYPE_WAIST" ] = { [ "INVTYPE_WAIST" ] = true; };
	[ "INVTYPE_LEGS" ] = { [ "INVTYPE_LEGS" ] = true; };
	[ "INVTYPE_FEET" ] = { [ "INVTYPE_FEET" ] = true; };
	[ "INVTYPE_WRIST" ] = { [ "INVTYPE_WRIST" ] = true; };
	[ "INVTYPE_HAND" ] = { [ "INVTYPE_HAND" ] = true; };
	[ "INVTYPE_FINGER" ] = { [ "INVTYPE_FINGER" ] = true; };
	[ "INVTYPE_TRINKET" ] = { [ "INVTYPE_TRINKET" ] = true; };
	[ "INVTYPE_CLOAK" ] = { [ "INVTYPE_CLOAK" ] = true; };
	[ "ENCHSLOT_WEAPON" ] = { [ "INVTYPE_WEAPON" ] = true; [ "INVTYPE_WEAPONMAINHAND" ] = true; [ "INVTYPE_2HWEAPON" ] = true; [ "INVTYPE_WEAPONOFFHAND" ] = true; [ "INVTYPE_HOLDABLE" ] = true; [ "INVTYPE_SHIELD" ] = true; };
	[ "INVTYPE_RANGED" ] = { [ "INVTYPE_THROWN" ] = true; [ "INVTYPE_RANGEDRIGHT" ] = true; [ "INVTYPE_RANGED" ] = true; };
	[ "INVTYPE_RELIC" ] = { [ "INVTYPE_RELIC" ] = true; };
	[ "INVTYPE_TABARD" ] = { [ "INVTYPE_TABARD" ] = true; };
	[ "INVTYPE_BAG" ] = { [ "INVTYPE_BAG" ] = true; [ "INVTYPE_QUIVER" ] = true; };
};

me.Buttons = {}; -- Cache of all item buttons in bank view
me.NextUpdate = 0;




--[[****************************************************************************
  * Function: GuildBankSearch.FilterButton:OnClick                             *
  * Description: Toggles the filter pane when clicked.                         *
  ****************************************************************************]]
function FilterButton:OnClick ()
	me.Toggle();
end

--[[****************************************************************************
  * Function: GuildBankSearch.Pane.ClearButton:OnClick                         *
  * Description: Clears the filter when clicked.                               *
  ****************************************************************************]]
function Pane.ClearButton:OnClick ()
	Pane.Clear();
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.NameEditBox:OnTextChanged                   *
  * Description: Updates the name filter when the field's contents change.     *
  ****************************************************************************]]
function Pane.NameEditBox:OnTextChanged ()
	local Text = self:GetText();
	me.NamePattern = #Text ~= 0 and Text:lower() or false;
	me.Filter();
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.QualityMenu.IterateOptions                  *
  ****************************************************************************]]
function Pane.QualityMenu.IterateOptions ()
	return ipairs( me.Qualities );
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.ItemLevelMinEditBox:OnTextChanged           *
  * Description: Updates the filter when the min item level changes.           *
  ****************************************************************************]]
function Pane.ItemLevelMinEditBox:OnTextChanged ()
	local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
	if ( NewLevel ~= me.ItemLevelMin ) then
		me.ItemLevelMin = NewLevel;
		me.Filter();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.ItemLevelMinEditBox:OnTextChanged           *
  * Description: Updates the filter when the max item level changes.           *
  ****************************************************************************]]
function Pane.ItemLevelMaxEditBox:OnTextChanged ()
	local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
	if ( NewLevel ~= me.ItemLevelMax ) then
		me.ItemLevelMax = NewLevel;
		me.Filter();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.ReqLevelMinEditBox:OnTextChanged            *
  * Description: Updates the filter when the min required level changes.       *
  ****************************************************************************]]
function Pane.ReqLevelMinEditBox:OnTextChanged ()
	local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
	if ( NewLevel ~= me.ReqLevelMin ) then
		me.ReqLevelMin = NewLevel;
		me.Filter();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.ReqLevelMaxEditBox:OnTextChanged            *
  * Description: Updates the filter when the max required level changes.       *
  ****************************************************************************]]
function Pane.ReqLevelMaxEditBox:OnTextChanged ()
	local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
	if ( NewLevel ~= me.ReqLevelMax ) then
		me.ReqLevelMax = NewLevel;
		me.Filter();
	end
end

--[[****************************************************************************
  * Function: GuildBankSearch.Pane.TypeMenu:OnSelect                           *
  * Description: Updates the subtype dropdown when a type is chosen.           *
  ****************************************************************************]]
function Pane.TypeMenu:OnSelect ( Dropdown, Type )
	if ( me.Type ~= Type ) then
		Pane.SubTypeMenu.OnSelect( nil, Pane.SubTypeMenu ); -- Remove subtype filter
		if ( not Type ) then
			UIDropDownMenu_DisableDropDown( Pane.SubTypeMenu );
		else
			UIDropDownMenu_EnableDropDown( Pane.SubTypeMenu );
		end
		me.DropdownOnSelect( self, Dropdown, Type );
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.TypeMenu.IterateOptions                     *
  ****************************************************************************]]
do
	local Index;
	local function Iterator ()
		Index = Index + 1;
		local Label = me.Types[ Index ];
		return Label, Label;
	end
	function Pane.TypeMenu.IterateOptions ()
		Index = 0;
		return Iterator;
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.SubTypeMenu.IterateOptions                  *
  ****************************************************************************]]
function Pane.SubTypeMenu.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = me.SubTypes[ me.Type ][ Index ];
		return Label, Label;
	end;
end
--[[****************************************************************************
  * Function: GuildBankSearch.Pane.SlotMenu.IterateOptions                     *
  ****************************************************************************]]
function Pane.SlotMenu.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Slot = me.Slots[ Index ];
		return Slot, _G[ Slot ];
	end;
end

--[[****************************************************************************
  * Function: GuildBankSearch:DropdownOnSelect                                 *
  ****************************************************************************]]
function me:DropdownOnSelect ( Dropdown, Value )
	if ( Value ~= me[ Dropdown.Parameter ] ) then
		UIDropDownMenu_SetText( Dropdown, self and self.value or L.ALL );
		me[ Dropdown.Parameter ] = Value;
		me.Filter();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch:DropdownInitialize                               *
  * Description: Constructs a dropdown menu.                                   *
  ****************************************************************************]]
function me:DropdownInitialize ()
	local CurrentValue = me[ self.Parameter ];
	local Info = UIDropDownMenu_CreateInfo();
	Info.arg1 = self;
	Info.text = L.ALL;
	Info.checked = CurrentValue == nil;
	Info.func = self.OnSelect;
	UIDropDownMenu_AddButton( Info );
	for Value, Label in self.IterateOptions() do
		Info.text = Label;
		Info.arg2 = Value;
		Info.checked = CurrentValue == Value;
		Info.func = self.OnSelect;
		UIDropDownMenu_AddButton( Info );
	end
end

--[[****************************************************************************
  * Function: GuildBankSearch.Pane.Clear                                       *
  * Description: Resets all filter parameters to not filter anything.          *
  ****************************************************************************]]
function Pane.Clear ()
	CloseDropDownMenus(); -- Close dropdown if open

	Pane.NameEditBox:SetText( "" );
	Pane.QualityMenu.OnSelect( nil, Pane.QualityMenu );
	Pane.ItemLevelMinEditBox:SetText( "" );
	Pane.ItemLevelMaxEditBox:SetText( "" );
	Pane.ReqLevelMinEditBox:SetText( "" );
	Pane.ReqLevelMaxEditBox:SetText( "" );

	-- Item category fields
	Pane.TypeMenu.OnSelect( nil, Pane.TypeMenu ); -- Also clears SubTypeMenu
	Pane.SlotMenu.OnSelect( nil, Pane.SlotMenu );
end




--[[****************************************************************************
  * Function: GuildBankSearch.Filter                                           *
  * Description: Requests an update to the bank or log display.                *
  ****************************************************************************]]
function me.Filter ( Force )
	me.NeedUpdate = true;
	if ( Force ) then
		me.NextUpdate = 0;
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.IsFilterDefined                                  *
  * Description: Returns true if any filter parameters are set.                *
  ****************************************************************************]]
function me.IsFilterDefined ()
	return me.NamePattern or me.Quality or me.Type or me.SubType or me.Slot or me.ItemLevelMin or me.ItemLevelMax or me.ReqLevelMin or me.ReqLevelMax;
end

--[[****************************************************************************
  * Function: GuildBankSearch.MatchItem                                        *
  * Description: Returns true if the given item link matches the filter.       *
  ****************************************************************************]]
do
	local Name, Link, Rarity, ItemLevel, ReqLevel, Type, SubType, StackCount, Slot;
	function me.MatchItem ( ItemLink )
		if ( not ItemLink ) then
			return false;
		end

		Name, Link, Rarity, ItemLevel, ReqLevel, Type, SubType, StackCount, Slot = GetItemInfo( ItemLink );
		if ( me.NamePattern and not Name:lower():find( me.NamePattern, 1, true ) ) then
			return false;
		elseif ( me.Quality and me.Quality ~= Rarity ) then
			return false;
		elseif ( me.Type and me.Type ~= Type ) then
			return false;
		elseif ( me.SubType and me.SubType ~= SubType ) then
			return false;
		elseif ( me.Slot and not me.SlotGroups[ me.Slot ][ Slot ] ) then
			return false;
		elseif ( me.ItemLevelMin and me.ItemLevelMin > ItemLevel ) then
			return false;
		elseif ( me.ItemLevelMax and me.ItemLevelMax < ItemLevel ) then
			return false;
		elseif ( me.ReqLevelMin and me.ReqLevelMin > ReqLevel ) then
			return false;
		elseif ( me.ReqLevelMax and me.ReqLevelMax < ReqLevel ) then
			return false;
		end
		return true;
	end
end

--[[****************************************************************************
  * Function: GuildBankSearch.HideFilter                                       *
  * Description: Restores an unfiltered view of the bank and log.              *
  ****************************************************************************]]
function me.HideFilter ()
	for Index, Button in ipairs( me.Buttons ) do
		Button:SetAlpha( 1 );
	end
	if ( GuildBankFrame.mode == "log" ) then
		GuildBankFrame_UpdateLog();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.ShowFilter                                       *
  * Description: Applies the current filter to the bank or log view.           *
  ****************************************************************************]]
function me.ShowFilter ()
	if ( not me.IsFilterDefined() ) then
		return me.HideFilter();
	end

	if ( GuildBankFrame.mode == "bank" ) then
		local Tab = GetCurrentGuildBankTab();
		if ( Tab <= GetNumGuildBankTabs() ) then
			for Index, Button in ipairs( me.Buttons ) do
				Button:SetAlpha( me.MatchItem( GetGuildBankItemLink( Tab, Index ) ) and 1 or 0.25 );
			end
		end
	elseif ( GuildBankFrame.mode == "log" ) then
		GuildBankFrame_UpdateLog();
	end
end




--[[****************************************************************************
  * Function: GuildBankSearch.GuildBankFrameTabOnClick                         *
  * Description: Enables the filter depending on which bank view is displayed. *
  ****************************************************************************]]
function me.GuildBankFrameTabOnClick ()
	if ( GuildBankFrame.mode == "log" or GuildBankFrame.mode == "bank" ) then
		FilterButton:Enable();
	else
		me:Hide();
		FilterButton:Disable();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.GuildBankFrameUpdate                             *
  * Description: Updates the filter display when the bank view type changes.   *
  ****************************************************************************]]
function me.GuildBankFrameUpdate ()
	me.Filter( true );
end
--[[****************************************************************************
  * Function: GuildBankSearch:GuildBankMessageFrameAddMessage                  *
  * Description: Hook that modifies added messages when a filter is active.    *
  ****************************************************************************]]
do
	local AddMessageBackup = GuildBankMessageFrame.AddMessage;
	function me:GuildBankMessageFrameAddMessage ( Message, ... )
		if ( GuildBankFrame.mode == "log" and me:IsShown() and me.IsFilterDefined() ) then
			if ( not me.MatchItem( Message:match( "|H(item[-:0-9]+)|h" ) ) ) then
				return AddMessageBackup( self, Message:gsub( "|cff[%x%X][%x%X][%x%X][%x%X][%x%X][%x%X]", "" ):gsub( "|r", "" ), 0.25, 0.25, 0.25, select( 4, ... ) );
			end
		end
		return AddMessageBackup( self, Message, ... );
	end
end




--[[****************************************************************************
  * Function: GuildBankSearch:OnShow                                           *
  * Description: Makes room for the filter pane and refreshes the filter.      *
  ****************************************************************************]]
function me:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
	FilterButton:SetButtonState( "PUSHED", true );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", me, "TOPRIGHT", -8, -16 );

	me.Filter( true );
end
--[[****************************************************************************
  * Function: GuildBankSearch:OnHide                                           *
  * Description: Undoes changes to bank window and clears any filter display.  *
  ****************************************************************************]]
function me:OnHide ()
	PlaySound( "igCharacterInfoClose" );
	FilterButton:SetButtonState( "NORMAL" );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -1, -32 );
	me.HideFilter();
end
--[[****************************************************************************
  * Function: GuildBankSearch:OnUpdate                                         *
  * Description: Refreshes the filter display when necessary.                  *
  ****************************************************************************]]
function me:OnUpdate ( Elapsed )
	me.NextUpdate = me.NextUpdate - Elapsed;
	if ( me.NeedUpdate and me.NextUpdate <= 0 ) then
		me.NeedUpdate = false;
		me.NextUpdate = 0.5;

		me:ShowFilter();
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch:OnEvent                                          *
  * Description: Forces an instant display update when bank contents change.   *
  ****************************************************************************]]
function me:OnEvent ()
	me.Filter( true );
end

--[[****************************************************************************
  * Function: GuildBankSearch.Toggle                                           *
  * Description: Shows or hides the filter pane.                               *
  ****************************************************************************]]
function me.Toggle ()
	if ( me:IsShown() ) then
		me:Hide();
	else
		me:Show();
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Fill in quality labels
	for Index = 0, #ITEM_QUALITY_COLORS do
		me.Qualities[ Index ] = ITEM_QUALITY_COLORS[ Index ].hex.._G[ "ITEM_QUALITY"..Index.."_DESC" ]..FONT_COLOR_CODE_CLOSE;
	end
	-- Fill in and sort subtypes
	for Index, Type in ipairs( me.Types ) do
		me.SubTypes[ Type ] = { GetAuctionItemSubClasses( Index ) };
		sort( me.SubTypes[ Type ] );
	end
	-- Sort types
	sort( me.Types ); -- Note: Use after subtypes are populated so indices don't get mixed up
	-- Fill in and sort slots table
	for InvType in pairs( me.SlotGroups ) do
		tinsert( me.Slots, InvType );
	end
	sort( me.Slots, function ( Type1, Type2 )
		return _G[ Type1 ] < _G[ Type2 ];
	end );

	-- Cache all item buttons
	for Index = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
		me.Buttons[ Index ] = _G[ "GuildBankColumn"..( floor( ( Index - 1 ) / NUM_SLOTS_PER_GUILDBANK_GROUP ) + 1 )
			.."Button"..( ( Index - 1 ) % NUM_SLOTS_PER_GUILDBANK_GROUP + 1 ) ];
	end


	-- Set up filter button
	FilterButton:SetWidth( 100 );
	FilterButton:SetHeight( 21 );
	FilterButton:SetPoint( "TOPRIGHT", -11, -40 );
	FilterButton:SetText( L.FILTER );
	FilterButton:SetScript( "OnClick", FilterButton.OnClick );


	-- Set up filter pane
	me:Hide();
	me:SetWidth( 187 );
	me:SetHeight( 389 );
	me:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -2, -28 );
	me:EnableMouse( true );
	me:SetToplevel( true );

	me:SetScript( "OnShow", me.OnShow );
	me:SetScript( "OnHide", me.OnHide );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" );
	me:RegisterEvent( "GUILDBANKLOG_UPDATE" );


	-- Background textures
	do
		local Top = me:CreateTexture( nil, "BACKGROUND" );
		Top:SetTexture( "Interface\\AuctionFrame\\AuctionHouseDressUpFrame-Top" );
		Top:SetWidth( 256 );
		Top:SetHeight( 256 );
		Top:SetPoint( "TOPLEFT" );
		local Bottom = me:CreateTexture( nil, "BACKGROUND" );
		Bottom:SetTexture( "Interface\\AuctionFrame\\AuctionHouseDressUpFrame-Bottom" );
		Bottom:SetWidth( 256 );
		Bottom:SetHeight( 256 );
		Bottom:SetPoint( "TOPLEFT", Top, "BOTTOMLEFT" );
		local Corner = me:CreateTexture( nil, "BACKGROUND" );
		Corner:SetTexture( "Interface\\AuctionFrame\\AuctionHouseDressUpFrame-Corner" );
		Corner:SetWidth( 32 );
		Corner:SetHeight( 32 );
		Corner:SetPoint( "TOPRIGHT", -5, -5 );
	end

	Pane:SetPoint( "TOPLEFT", me, 8, -16 );
	Pane:SetPoint( "BOTTOMRIGHT", me, -16, 8 );

	local Label = Pane:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
	Label:SetPoint( "TOPLEFT", -4, 6 );
	Label:SetText( L.TITLE );

	-- Close button
	CreateFrame( "Button", nil, me, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 1, 0 );

	local ClearButton = Pane.ClearButton;
	ClearButton:SetWidth( 45 );
	ClearButton:SetHeight( 18 );
	ClearButton:SetPoint( "TOPRIGHT", -31, -8 );
	ClearButton:SetText( L.CLEAR );
	ClearButton:SetScript( "OnClick", ClearButton.OnClick );


	-- Pane controls
	local function InitializeDropdown ( self, Parameter, Label )
		self:SetPoint( "LEFT", -8, 0 );
		self:SetPoint( "RIGHT", -8, 0 );
		_G[ self:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
		UIDropDownMenu_JustifyText( self, "LEFT" );
		if ( not self.OnSelect ) then
			self.OnSelect = me.DropdownOnSelect;
		end
		self.initialize = me.DropdownInitialize;
		self.Parameter = Parameter;
		local Label = self:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
		Label:SetText( Label );
		Label:SetPoint( "BOTTOMLEFT", self, "TOPLEFT", 24, 0 );
	end

	local NameEditBox = Pane.NameEditBox;
	NameEditBox:SetHeight( 16 );
	NameEditBox:SetAutoFocus( false );
	NameEditBox:SetPoint( "TOP", ClearButton, "BOTTOM", 0, -20 );
	NameEditBox:SetPoint( "LEFT", 8, 0 );
	NameEditBox:SetPoint( "RIGHT", -8, 0 );
	NameEditBox:SetScript( "OnTextChanged", NameEditBox.OnTextChanged );
	Label = NameEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOMLEFT", NameEditBox, "TOPLEFT", 1, 0 );
	Label:SetText( L.NAME );

	InitializeDropdown( Pane.QualityMenu, "Quality", L.QUALITY );
	Pane.QualityMenu:SetPoint( "TOP", NameEditBox, "BOTTOM", 0, -12 );

	local ItemLevelMinEditBox = Pane.ItemLevelMinEditBox;
	ItemLevelMinEditBox:SetWidth( 25 );
	ItemLevelMinEditBox:SetHeight( 16 );
	ItemLevelMinEditBox:SetNumeric( true );
	ItemLevelMinEditBox:SetMaxLetters( 3 );
	ItemLevelMinEditBox:SetAutoFocus( false );
	ItemLevelMinEditBox:SetPoint( "TOP", Pane.QualityMenu, "BOTTOM", 0, -16 );
	ItemLevelMinEditBox:SetPoint( "LEFT", 8, 0 );
	ItemLevelMinEditBox:SetScript( "OnTextChanged", ItemLevelMinEditBox.OnTextChanged );
	Label = ItemLevelMinEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOM", ItemLevelMinEditBox, "TOPRIGHT", 5, 0 );
	Label:SetText( L.ITEM_LEVEL );

	local ItemLevelMaxEditBox = Pane.ItemLevelMaxEditBox;
	ItemLevelMaxEditBox:SetWidth( 25 );
	ItemLevelMaxEditBox:SetHeight( 16 );
	ItemLevelMaxEditBox:SetNumeric( true );
	ItemLevelMaxEditBox:SetMaxLetters( 3 );
	ItemLevelMaxEditBox:SetAutoFocus( false );
	ItemLevelMaxEditBox:SetPoint( "LEFT", ItemLevelMinEditBox, "RIGHT", 12, 0 );
	ItemLevelMaxEditBox:SetScript( "OnTextChanged", ItemLevelMaxEditBox.OnTextChanged );
	Label = ItemLevelMaxEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "LEFT", ItemLevelMinEditBox, "RIGHT" );
	Label:SetText( "-" );

	local ReqLevelMaxEditBox = Pane.ReqLevelMaxEditBox;
	ReqLevelMaxEditBox:SetWidth( 25 );
	ReqLevelMaxEditBox:SetHeight( 16 );
	ReqLevelMaxEditBox:SetNumeric( true );
	ReqLevelMaxEditBox:SetMaxLetters( 3 );
	ReqLevelMaxEditBox:SetAutoFocus( false );
	ReqLevelMaxEditBox:SetPoint( "TOP", Pane.QualityMenu, "BOTTOM", 0, -16 );
	ReqLevelMaxEditBox:SetPoint( "RIGHT", -8, 0 );
	ReqLevelMaxEditBox:SetScript( "OnTextChanged", ReqLevelMaxEditBox.OnTextChanged );
	Label = ReqLevelMaxEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOM", ReqLevelMaxEditBox, "TOPLEFT", -8, 0 );
	Label:SetText( L.REQUIRED_LEVEL );

	local ReqLevelMinEditBox = Pane.ReqLevelMinEditBox;
	ReqLevelMinEditBox:SetWidth( 25 );
	ReqLevelMinEditBox:SetHeight( 16 );
	ReqLevelMinEditBox:SetNumeric( true );
	ReqLevelMinEditBox:SetMaxLetters( 3 );
	ReqLevelMinEditBox:SetAutoFocus( false );
	ReqLevelMinEditBox:SetPoint( "RIGHT", ReqLevelMaxEditBox, "LEFT", -12, 0 );
	ReqLevelMinEditBox:SetScript( "OnTextChanged", ReqLevelMinEditBox.OnTextChanged );
	Label = ReqLevelMinEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "RIGHT", ReqLevelMaxEditBox, "LEFT", -6, 0 );
	Label:SetText( "-" );


	-- Item category section
	local CategorySection = Pane.CategorySection;
	_G[ CategorySection:GetName().."Title" ]:SetText( L.ITEM_CATEGORY );
	CategorySection:SetPoint( "TOP", ItemLevelMinEditBox, "BOTTOM", 0, -38 );
	CategorySection:SetPoint( "LEFT" );
	CategorySection:SetPoint( "BOTTOMRIGHT", 0, 8 );

	InitializeDropdown( Pane.TypeMenu, "Type", L.TYPE );
	Pane.TypeMenu:SetPoint( "TOP", 0, -16 );

	InitializeDropdown( Pane.SubTypeMenu, "SubType", L.SUB_TYPE );
	Pane.SubTypeMenu:SetPoint( "TOP", Pane.TypeMenu, "BOTTOM", 0, -6 );

	InitializeDropdown( Pane.SlotMenu, "Slot", L.SLOT );
	Pane.SlotMenu:SetPoint( "TOP", Pane.SubTypeMenu, "BOTTOM", 0, -16 );


	-- Hooks
	hooksecurefunc( "GuildBankFrameTab_OnClick", me.GuildBankFrameTabOnClick );
	hooksecurefunc( "GuildBankFrame_Update", me.GuildBankFrameUpdate );
	GuildBankMessageFrame.AddMessage = me.GuildBankMessageFrameAddMessage;

	Pane.Clear();
end
