--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * GuildBankSearch.lua - Adds a search filter to the guild bank.              *
  ****************************************************************************]]


local L = GuildBankSearchLocalization;
local me = CreateFrame( "Frame", "GuildBankSearch", GuildBankFrame );

local FilterButton = CreateFrame( "Button", nil, GuildBankFrame, "UIPanelButtonTemplate" );
me.FilterButton = FilterButton;

me.ClearButton = CreateFrame( "Button", nil, me, "UIPanelButtonTemplate" );
me.NameEditBox = CreateFrame( "EditBox", "$parentNameEditBox", me, "InputBoxTemplate" );
me.QualityMenu = CreateFrame( "Frame", "$parentQualityMenu", me, "UIDropDownMenuTemplate" );
me.ItemLevelMinEditBox = CreateFrame( "EditBox", "$parentItemLevelMinEditBox", me, "InputBoxTemplate" );
me.ItemLevelMaxEditBox = CreateFrame( "EditBox", "$parentItemLevelMaxEditBox", me, "InputBoxTemplate" );
me.ReqLevelMinEditBox = CreateFrame( "EditBox", "$parentReqLevelMinEditBox", me, "InputBoxTemplate" );
me.ReqLevelMaxEditBox = CreateFrame( "EditBox", "$parentReqLevelMaxEditBox", me, "InputBoxTemplate" );

me.CategorySection = CreateFrame( "Frame", "$parentCategory", me, "OptionsBoxTemplate" );
me.TypeMenu = CreateFrame( "Frame", "$parentTypeMenu", me.CategorySection, "UIDropDownMenuTemplate" );
me.SubTypeMenu = CreateFrame( "Frame", "$parentSubTypeMenu", me.CategorySection, "UIDropDownMenuTemplate" );
me.SlotMenu = CreateFrame( "Frame", "$parentSlotMenu", me.CategorySection, "UIDropDownMenuTemplate" );


-- Initially false so Clear() will update all fields to nil
me.Name = false;
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
  * Function: GuildBankSearch.ClearButton:OnClick                              *
  * Description: Clears the filter when clicked.                               *
  ****************************************************************************]]
function me.ClearButton:OnClick ()
	me.Clear();
end
--[[****************************************************************************
  * Function: GuildBankSearch.NameEditBox:OnTextChanged                        *
  * Description: Updates the name filter when the field's contents change.     *
  ****************************************************************************]]
function me.NameEditBox:OnTextChanged ()
	local Text = self:GetText();
	me.Name = #Text ~= 0 and Text:lower() or false;
	me.Filter();
end
--[[****************************************************************************
  * Function: GuildBankSearch.QualityMenu.IterateOptions                       *
  ****************************************************************************]]
function me.QualityMenu.IterateOptions ()
	return ipairs( me.Qualities );
end

--[[****************************************************************************
  * Function: GuildBankSearch.TypeMenu:OnSelect                                *
  * Description: Updates the subtype dropdown when a type is chosen.           *
  ****************************************************************************]]
function me.TypeMenu:OnSelect ( Dropdown, Type )
	if ( me.Type ~= Type ) then
		me.SubTypeMenu.OnSelect( nil, me.SubTypeMenu ); -- Remove subtype filter
		if ( not Type ) then
			UIDropDownMenu_DisableDropDown( me.SubTypeMenu );
		else
			UIDropDownMenu_EnableDropDown( me.SubTypeMenu );
		end
		me.DropdownOnSelect( self, Dropdown, Type );
	end
end
--[[****************************************************************************
  * Function: GuildBankSearch.TypeMenu.IterateOptions                          *
  ****************************************************************************]]
function me.TypeMenu.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = me.Types[ Index ];
		return Label, Label;
	end;
end
--[[****************************************************************************
  * Function: GuildBankSearch.SubTypeMenu.IterateOptions                       *
  ****************************************************************************]]
function me.SubTypeMenu.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = me.SubTypes[ me.Type ][ Index ];
		return Label, Label;
	end;
end
--[[****************************************************************************
  * Function: GuildBankSearch.SlotMenu.IterateOptions                          *
  ****************************************************************************]]
function me.SlotMenu.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Slot = me.Slots[ Index ];
		return Slot, _G[ Slot ];
	end;
end

--[[****************************************************************************
  * Function: GuildBankSearch:LevelEditBoxOnTextChanged                        *
  ****************************************************************************]]
function me:LevelEditBoxOnTextChanged ()
	local NewLevel = self:GetText() ~= "" and self:GetNumber() or false;
	if ( NewLevel ~= me[ self.Parameter ] ) then
		me[ self.Parameter ] = NewLevel;
		me.Filter();
	end
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
  * Function: GuildBankSearch.Clear                                            *
  * Description: Resets all filter parameters to not filter anything.          *
  ****************************************************************************]]
function me.Clear ()
	CloseDropDownMenus(); -- Close dropdown if open

	me.NameEditBox:SetText( "" );
	me.QualityMenu.OnSelect( nil, me.QualityMenu );
	me.ItemLevelMinEditBox:SetText( "" );
	me.ItemLevelMaxEditBox:SetText( "" );
	me.ReqLevelMinEditBox:SetText( "" );
	me.ReqLevelMaxEditBox:SetText( "" );

	-- Item category fields
	me.TypeMenu.OnSelect( nil, me.TypeMenu ); -- Also clears SubTypeMenu
	me.SlotMenu.OnSelect( nil, me.SlotMenu );
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
	return me.Name or me.Quality or me.Type or me.SubType or me.Slot or me.ItemLevelMin or me.ItemLevelMax or me.ReqLevelMin or me.ReqLevelMax;
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
		if ( me.Name and not Name:lower():find( me.Name, 1, true ) ) then
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


	-- Artwork
	do
		local Label = me:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
		Label:SetPoint( "TOPLEFT", 4, -10 );
		Label:SetText( L.TITLE );

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


	-- Close button
	CreateFrame( "Button", nil, me, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 1, 0 );

	local ClearButton = me.ClearButton;
	ClearButton:SetWidth( 45 );
	ClearButton:SetHeight( 18 );
	ClearButton:SetPoint( "TOPRIGHT", -31, -8 );
	ClearButton:SetText( L.CLEAR );
	ClearButton:SetScript( "OnClick", ClearButton.OnClick );


	-- Filter controls
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
		self.Label = self:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
		self.Label:SetText( Label );
		self.Label:SetPoint( "BOTTOMLEFT", self, "TOPLEFT", 24, 0 );
		return self;
	end
	local function InitializeLevelEditBox ( self, Parameter, Label )
		self:SetWidth( 25 );
		self:SetHeight( 16 );
		self:SetNumeric( true );
		self:SetMaxLetters( 3 );
		self:SetAutoFocus( false );
		self:SetScript( "OnTextChanged", me.LevelEditBoxOnTextChanged );
		self.Parameter = Parameter;
		self.Label = self:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
		self.Label:SetText( Label );
	end

	local NameEditBox = me.NameEditBox;
	NameEditBox:SetHeight( 16 );
	NameEditBox:SetAutoFocus( false );
	NameEditBox:SetPoint( "TOP", ClearButton, "BOTTOM", 0, -20 );
	NameEditBox:SetPoint( "LEFT", 16, 0 );
	NameEditBox:SetPoint( "RIGHT", -16, 0 );
	NameEditBox:SetScript( "OnTextChanged", NameEditBox.OnTextChanged );
	Label = NameEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOMLEFT", NameEditBox, "TOPLEFT", 1, 0 );
	Label:SetText( L.NAME );

	InitializeDropdown( me.QualityMenu, "Quality", L.QUALITY ):SetPoint( "TOP", NameEditBox, "BOTTOM", 0, -12 );

	-- Item level range
	local Min = me.ItemLevelMinEditBox;
	InitializeLevelEditBox( Min, "ItemLevelMin", L.ITEM_LEVEL );
	Min:SetPoint( "TOP", me.QualityMenu, "BOTTOM", 0, -16 );
	Min:SetPoint( "LEFT", 16, 0 );
	local Max = me.ItemLevelMaxEditBox;
	InitializeLevelEditBox( Max, "ItemLevelMax", L.LEVELRANGE_SEPARATOR );
	Max.Label:SetPoint( "LEFT", Min, "RIGHT", 2, 0 );
	Max:SetPoint( "LEFT", Max.Label, "RIGHT", 8, 0 );
	Min.Label:SetPoint( "CENTER", Max.Label ); -- Center above dash between edit boxes
	Min.Label:SetPoint( "BOTTOM", Min, "TOP" );

	-- Required level range
	Max = me.ReqLevelMaxEditBox;
	InitializeLevelEditBox( Max, "ReqLevelMax", L.REQUIRED_LEVEL );
	Max:SetPoint( "TOP", me.ItemLevelMinEditBox );
	Max:SetPoint( "RIGHT", -24, 0 );
	Min = me.ReqLevelMinEditBox;
	InitializeLevelEditBox( Min, "ReqLevelMin", L.LEVELRANGE_SEPARATOR );
	Min.Label:SetPoint( "RIGHT", Max, "LEFT", -8, 0 );
	Min:SetPoint( "RIGHT", Min.Label, "LEFT", -2, 0 );
	Max.Label:SetPoint( "CENTER", Min.Label );
	Max.Label:SetPoint( "BOTTOM", Max, "TOP" );

	-- Item category section
	local CategorySection = me.CategorySection;
	_G[ CategorySection:GetName().."Title" ]:SetText( L.ITEM_CATEGORY );
	CategorySection:SetPoint( "TOP", me.ItemLevelMinEditBox, "BOTTOM", 0, -38 );
	CategorySection:SetPoint( "LEFT", 8, 0 );
	CategorySection:SetPoint( "BOTTOMRIGHT", -16, 16 );

	InitializeDropdown( me.TypeMenu, "Type", L.TYPE ):SetPoint( "TOP", 0, -16 );
	InitializeDropdown( me.SubTypeMenu, "SubType", L.SUB_TYPE ):SetPoint( "TOP", me.TypeMenu, "BOTTOM", 0, -6 );
	InitializeDropdown( me.SlotMenu, "Slot", L.SLOT ):SetPoint( "TOP", me.SubTypeMenu, "BOTTOM", 0, -16 );


	-- Hooks
	hooksecurefunc( "GuildBankFrameTab_OnClick", me.GuildBankFrameTabOnClick );
	hooksecurefunc( "GuildBankFrame_Update", me.GuildBankFrameUpdate );
	GuildBankMessageFrame.AddMessage = me.GuildBankMessageFrameAddMessage;

	me.Clear();
end
