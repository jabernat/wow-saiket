--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * GuildBankSearch.lua - Adds a search filter to the guild bank.              *
  ****************************************************************************]]


local L = GuildBankSearchLocalization;
local GBS = CreateFrame( "Frame", "GuildBankSearch", GuildBankFrame );

GBS.NamePattern = false;
GBS.Quality = false;
GBS.Type = false;
GBS.SubType = false;
GBS.Slot = false;
GBS.ItemLevelMin = false;
GBS.ItemLevelMax = false;
GBS.ReqLevelMin = false;
GBS.ReqLevelMax = false;

GBS.Types = { GetAuctionItemClasses() };
GBS.SubTypes = {};
for Index, Type in ipairs( GBS.Types ) do
	GBS.SubTypes[ Type ] = { GetAuctionItemSubClasses( Index ) };
end
GBS.SlotGroups = {
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
do
	GBS.Slots = {};
	for InvType in pairs( GBS.SlotGroups ) do
		tinsert( GBS.Slots, InvType );
	end
	sort( GBS.Slots, function ( Type1, Type2 ) return _G[ Type1 ] < _G[ Type2 ]; end );
end

do
	GBS.Buttons = {};
	for Index = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
		GBS.Buttons[ Index ] = _G[ "GuildBankColumn"..( floor( ( Index - 1 ) /NUM_SLOTS_PER_GUILDBANK_GROUP ) + 1 )
			.."Button"..( mod( Index - 1, NUM_SLOTS_PER_GUILDBANK_GROUP ) + 1 ) ];
	end
end

do
	local FilterButton = CreateFrame( "Button", nil, GuildBankFrame, "UIPanelButtonTemplate" );
	GBS.FilterButton = FilterButton;
	FilterButton:SetWidth( 100 );
	FilterButton:SetHeight( 21 );
	FilterButton:SetPoint( "TOPRIGHT", -11, -40 );
	FilterButton:SetText( L.FILTER );
	FilterButton:SetScript( "OnClick", function () GBS.Toggle() end );
end
do
	GBS:Hide();
	GBS:SetWidth( 187 );
	GBS:SetHeight( 389 );
	GBS:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -2, -28 );
	GBS:EnableMouse( true );
	GBS:SetToplevel( true );

	local Top = GBS:CreateTexture( nil, "BACKGROUND" );
	Top:SetTexture( "Interface\\AuctionFrame\\AuctionHouseDressUpFrame-Top" );
	Top:SetWidth( 256 );
	Top:SetHeight( 256 );
	Top:SetPoint( "TOPLEFT" );

	local Bottom = GBS:CreateTexture( nil, "BACKGROUND" );
	Bottom:SetTexture( "Interface\\AuctionFrame\\AuctionHouseDressUpFrame-Bottom" );
	Bottom:SetWidth( 256 );
	Bottom:SetHeight( 256 );
	Bottom:SetPoint( "TOPLEFT", Top, "BOTTOMLEFT" );

	local Pane = CreateFrame( "Frame", nil, GBS );
	GBS.Pane = Pane;
	Pane:SetPoint( "TOPLEFT", GBS, 8, -16 );
	Pane:SetPoint( "BOTTOMRIGHT", GBS, -16, 8 );

	local Label = Pane:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
	Label:SetPoint( "TOPLEFT", -4, 6 );
	Label:SetText( L.TITLE );

	local CloseButton = CreateFrame( "Button", nil, Pane, "UIPanelCloseButton" );
	Pane.CloseButton = CloseButton;
	CloseButton:SetPoint( "CENTER", GBS, "TOPRIGHT", -15, -16 );
	CloseButton:SetScript( "OnClick", function ( self ) self:GetParent():GetParent():Hide(); end );
	local Background = CloseButton:CreateTexture( nil, "BACKGROUND" );
	Background:SetTexture( "Interface\\AuctionFrame\\AuctionHouseDressUpFrame-Corner" );
	Background:SetWidth( 32 );
	Background:SetHeight( 32 );
	Background:SetPoint( "TOPRIGHT", GBS, -5, -5 );

	local ClearButton = CreateFrame( "Button", nil, Pane, "UIPanelButtonTemplate" );
	Pane.ClearButton = ClearButton;
	ClearButton:SetWidth( 45 );
	ClearButton:SetHeight( 18 );
	ClearButton:SetPoint( "TOPRIGHT", -15, 8 );
	ClearButton:SetText( L.CLEAR );
	ClearButton:SetScript( "OnClick", function () GBS.ClearFilter(); end );

	local NameEditBox = CreateFrame( "EditBox", "GBSNameEditBox", Pane, "InputBoxTemplate" );
	Pane.NameEditBox = NameEditBox;
	function NameEditBox.OnTextChanged ( self )
		local Text = self:GetText();
		GBS.NamePattern = #Text ~= 0 and Text or false;
		GBS.Filter();
	end
	NameEditBox:SetHeight( 16 );
	NameEditBox:SetAutoFocus( false );
	NameEditBox:SetPoint( "TOP", ClearButton, "BOTTOM", 0, -20 );
	NameEditBox:SetPoint( "LEFT", 8, 0 );
	NameEditBox:SetPoint( "RIGHT", -8, 0 );
	NameEditBox:SetScript( "OnTextChanged", NameEditBox.OnTextChanged );
	Label = NameEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOMLEFT", NameEditBox, "TOPLEFT", 3, -2 );
	Label:SetText( L.NAME );

	local QualityMenu = CreateFrame( "Frame", "GBSQualityMenu", Pane, "UIDropDownMenuTemplate" );
	Pane.QualityMenu = QualityMenu;
	function QualityMenu.OnSelect ()
		if this.arg1 ~= GBS.Quality then
			UIDropDownMenu_SetSelectedValue( QualityMenu, this.value );
			GBS.Quality = this.arg1;
			GBS.Filter();
		end
	end
	function QualityMenu.Initialize ()
		local Info = UIDropDownMenu_CreateInfo();
		Info.text = L.ALL;
		Info.value = -1;
		Info.arg1 = false;
		Info.func = QualityMenu.OnSelect;
		UIDropDownMenu_AddButton( Info );
		for Index = 0, #ITEM_QUALITY_COLORS do
			Info.text = ITEM_QUALITY_COLORS[ Index ].hex.._G[ "ITEM_QUALITY"..Index.."_DESC" ]..FONT_COLOR_CODE_CLOSE;
			Info.value = Index;
			Info.arg1 = Index;
			Info.func = QualityMenu.OnSelect;
			Info.checked = nil;
			UIDropDownMenu_AddButton( Info );
		end
	end
	QualityMenu:EnableMouse( true );
	QualityMenu:SetPoint( "TOP", NameEditBox, "BOTTOM", 0, -12 );
	QualityMenu:SetPoint( "LEFT", -16, 0 );
	QualityMenu:SetPoint( "RIGHT" );
	_G[ QualityMenu:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	UIDropDownMenu_JustifyText( QualityMenu, "LEFT" );
	UIDropDownMenu_Initialize( QualityMenu, QualityMenu.Initialize );
	UIDropDownMenu_SetSelectedValue( QualityMenu, -1 );
	Label = QualityMenu:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetText( L.QUALITY );
	Label:SetPoint( "BOTTOMLEFT", QualityMenu, "TOPLEFT", 24, 0 );

	local ItemLevelMinEditBox = CreateFrame( "EditBox", "GBSItemLevelMinEditBox", Pane, "InputBoxTemplate" );
	Pane.ItemLevelMinEditBox = ItemLevelMinEditBox;
	function ItemLevelMinEditBox.OnTextChanged ( self )
		local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
		if NewLevel ~= GBS.ItemLevelMin then
			GBS.ItemLevelMin = NewLevel;
			GBS.Filter();
		end
	end
	ItemLevelMinEditBox:SetWidth( 25 );
	ItemLevelMinEditBox:SetHeight( 16 );
	ItemLevelMinEditBox:SetNumeric( true );
	ItemLevelMinEditBox:SetMaxLetters( 3 );
	ItemLevelMinEditBox:SetAutoFocus( false );
	ItemLevelMinEditBox:SetPoint( "TOP", QualityMenu, "BOTTOM", 0, -16 );
	ItemLevelMinEditBox:SetPoint( "LEFT", 8, 0 );
	ItemLevelMinEditBox:SetScript( "OnTextChanged", ItemLevelMinEditBox.OnTextChanged );
	Label = ItemLevelMinEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOM", ItemLevelMinEditBox, "TOPRIGHT", 5, 0 );
	Label:SetText( L.ITEM_LEVEL );

	local ItemLevelMaxEditBox = CreateFrame( "EditBox", "GBSItemLevelMaxEditBox", Pane, "InputBoxTemplate" );
	Pane.ItemLevelMaxEditBox = ItemLevelMaxEditBox;
	function ItemLevelMaxEditBox.OnTextChanged ( self )
		local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
		if NewLevel ~= GBS.ItemLevelMax then
			GBS.ItemLevelMax = NewLevel;
			GBS.Filter();
		end
	end
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

	local ReqLevelMaxEditBox = CreateFrame( "EditBox", "GBSReqLevelMaxEditBox", Pane, "InputBoxTemplate" );
	Pane.ReqLevelMaxEditBox = ReqLevelMaxEditBox;
	function ReqLevelMaxEditBox.OnTextChanged ( self )
		local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
		if NewLevel ~= GBS.ReqLevelMax then
			GBS.ReqLevelMax = NewLevel;
			GBS.Filter();
		end
	end
	ReqLevelMaxEditBox:SetWidth( 25 );
	ReqLevelMaxEditBox:SetHeight( 16 );
	ReqLevelMaxEditBox:SetNumeric( true );
	ReqLevelMaxEditBox:SetMaxLetters( 3 );
	ReqLevelMaxEditBox:SetAutoFocus( false );
	ReqLevelMaxEditBox:SetPoint( "TOP", QualityMenu, "BOTTOM", 0, -16 );
	ReqLevelMaxEditBox:SetPoint( "RIGHT", -8, 0 );
	ReqLevelMaxEditBox:SetScript( "OnTextChanged", ReqLevelMaxEditBox.OnTextChanged );
	Label = ReqLevelMaxEditBox:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetPoint( "BOTTOM", ReqLevelMaxEditBox, "TOPLEFT", -8, 0 );
	Label:SetText( L.REQUIRED_LEVEL );

	local ReqLevelMinEditBox = CreateFrame( "EditBox", "GBSReqLevelMinEditBox", Pane, "InputBoxTemplate" );
	Pane.ReqLevelMinEditBox = ReqLevelMinEditBox;
	function ReqLevelMinEditBox.OnTextChanged ( self )
		local NewLevel = #self:GetText() ~= 0 and self:GetNumber() or false;
		if NewLevel ~= GBS.ReqLevelMin then
			GBS.ReqLevelMin = NewLevel;
			GBS.Filter();
		end
	end
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

	local CategorySection = CreateFrame( "Frame", "GBSCategorySection", Pane, "OptionsBoxTemplate" );
	_G[ CategorySection:GetName().."Title" ]:SetText( L.ITEM_CATEGORY );
	CategorySection:SetPoint( "TOP", ItemLevelMinEditBox, "BOTTOM", 0, -38 );
	CategorySection:SetPoint( "LEFT" );
	CategorySection:SetPoint( "BOTTOMRIGHT", 0, 8 );

	local TypeMenu = CreateFrame( "Frame", "GBSTypeMenu", Pane, "UIDropDownMenuTemplate" );
	Pane.TypeMenu = TypeMenu;
	function TypeMenu.OnSelect ()
		if GBS.Type ~= this.arg1 then
			UIDropDownMenu_SetSelectedValue( TypeMenu, this.value );
			GBS.Type = this.arg1;
			UIDropDownMenu_SetSelectedValue( GBS.Pane.SubTypeMenu, -1 );
			GBS.SubType = false;
			if not GBS.Type then
				UIDropDownMenu_DisableDropDown( GBS.Pane.SubTypeMenu );
			else
				UIDropDownMenu_EnableDropDown( GBS.Pane.SubTypeMenu );
			end
			GBS.Filter();
		end
	end
	function TypeMenu.Initialize ()
		local Info = UIDropDownMenu_CreateInfo();
		Info.text = L.ALL;
		Info.value = -1;
		Info.arg1 = false;
		Info.func = TypeMenu.OnSelect;
		UIDropDownMenu_AddButton( Info );
		for Index, Type in ipairs( GBS.Types )  do
			Info.text = Type;
			Info.value = Index;
			Info.arg1 = Type;
			Info.func = TypeMenu.OnSelect;
			Info.checked = nil;
			UIDropDownMenu_AddButton( Info );
		end
	end
	TypeMenu:EnableMouse( true );
	TypeMenu:SetPoint( "TOP", CategorySection, 0, -16 );
	TypeMenu:SetPoint( "LEFT", CategorySection, -8, 0 );
	TypeMenu:SetPoint( "RIGHT", CategorySection, -8, 0 );
	_G[ TypeMenu:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	UIDropDownMenu_JustifyText( TypeMenu, "LEFT" );
	UIDropDownMenu_Initialize( TypeMenu, TypeMenu.Initialize );
	UIDropDownMenu_SetSelectedValue( TypeMenu, -1 );
	Label = TypeMenu:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetText( L.TYPE );
	Label:SetPoint( "BOTTOMLEFT", TypeMenu, "TOPLEFT", 24, 0 );

	local SubTypeMenu = CreateFrame( "Frame", "GBSSubTypeMenu", Pane, "UIDropDownMenuTemplate" );
	Pane.SubTypeMenu = SubTypeMenu;
	function SubTypeMenu.OnSelect ()
		if GBS.SubType ~= this.arg1 then
			UIDropDownMenu_SetSelectedValue( SubTypeMenu, this.value );
			GBS.SubType = this.arg1;
			GBS.Filter();
		end
	end
	function SubTypeMenu.Initialize ()
		local Info = UIDropDownMenu_CreateInfo();
		Info.text = L.ALL;
		Info.value = -1;
		Info.arg1 = false;
		Info.func = SubTypeMenu.OnSelect;
		UIDropDownMenu_AddButton( Info );
		if GBS.Type then
			for Index, SubType in ipairs( GBS.SubTypes[ GBS.Type ] )  do
				Info.text = SubType;
				Info.value = Index;
				Info.arg1 = SubType;
				Info.func = SubTypeMenu.OnSelect;
				Info.checked = nil;
				UIDropDownMenu_AddButton( Info );
			end
		end
	end
	SubTypeMenu:EnableMouse( true );
	SubTypeMenu:SetPoint( "TOP", TypeMenu, "BOTTOM", 0, -6 );
	SubTypeMenu:SetPoint( "LEFT", CategorySection, -8, 0 );
	SubTypeMenu:SetPoint( "RIGHT", CategorySection, -8, 0 );
	_G[ SubTypeMenu:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	UIDropDownMenu_JustifyText( SubTypeMenu, "LEFT" );
	UIDropDownMenu_Initialize( SubTypeMenu, SubTypeMenu.Initialize );
	UIDropDownMenu_SetSelectedValue( SubTypeMenu, -1 );
	Label = SubTypeMenu:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetText( L.SUB_TYPE );
	Label:SetPoint( "BOTTOMLEFT", SubTypeMenu, "TOPLEFT", 24, 0 );

	local SlotMenu = CreateFrame( "Frame", "GBSSlotMenu", Pane, "UIDropDownMenuTemplate" );
	Pane.SlotMenu = SlotMenu;
	function SlotMenu.OnSelect ()
		if GBS.Slot ~= this.arg1 then
			UIDropDownMenu_SetSelectedValue( SlotMenu, this.value );
			GBS.Slot = this.arg1;
			GBS.Filter();
		end
	end
	function SlotMenu.Initialize ()
		local Info = UIDropDownMenu_CreateInfo();
		Info.text = L.ALL;
		Info.value = -1;
		Info.arg1 = false;
		Info.func = SlotMenu.OnSelect;
		UIDropDownMenu_AddButton( Info );
		for Index, Slot in ipairs( GBS.Slots )  do
			Info.text = _G[ Slot ];
			Info.value = Index;
			Info.arg1 = Slot;
			Info.func = SlotMenu.OnSelect;
			Info.checked = nil;
			UIDropDownMenu_AddButton( Info );
		end
	end
	SlotMenu:EnableMouse( true );
	SlotMenu:SetPoint( "TOP", SubTypeMenu, "BOTTOM", 0, -16 );
	SlotMenu:SetPoint( "LEFT", CategorySection, -8, 0 );
	SlotMenu:SetPoint( "RIGHT", CategorySection, -8, 0 );
	_G[ SlotMenu:GetName().."Middle" ]:SetPoint( "RIGHT", -16, 0 );
	UIDropDownMenu_JustifyText( SlotMenu, "LEFT" );
	UIDropDownMenu_Initialize( SlotMenu, SlotMenu.Initialize );
	UIDropDownMenu_SetSelectedValue( SlotMenu, -1 );
	Label = SlotMenu:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	Label:SetText( L.SLOT );
	Label:SetPoint( "BOTTOMLEFT", SlotMenu, "TOPLEFT", 24, 0 );
end

function GBS.Toggle ()
	if GBS:IsShown() then
		GBS:Hide();
	else
		GBS:Show();
	end
end
function GBS.ClearFilter ()
	local Pane = GBS.Pane;
	Pane.NameEditBox:SetText( "" );
	if GBS.Quality then
		UIDropDownMenu_SetSelectedValue( Pane.QualityMenu, -1 );
		GBS.Quality = false;
		GBS.Filter();
	end
	if GBS.Type then
		UIDropDownMenu_SetSelectedValue( Pane.TypeMenu, -1 );
		GBS.Type = false;
		GBS.Filter();
	end
	if GBS.SubType then
		UIDropDownMenu_SetSelectedValue( Pane.SubTypeMenu, -1 );
		GBS.SubType = false;
		GBS.Filter();
	end
	UIDropDownMenu_DisableDropDown( Pane.SubTypeMenu );
	if GBS.Slot then
		UIDropDownMenu_SetSelectedValue( Pane.SlotMenu, -1 );
		GBS.Slot = false;
		GBS.Filter();
	end
	Pane.ItemLevelMinEditBox:SetText( "" );
	Pane.ItemLevelMaxEditBox:SetText( "" );
	Pane.ReqLevelMinEditBox:SetText( "" );
	Pane.ReqLevelMaxEditBox:SetText( "" );
end
hooksecurefunc( "GuildBankFrameTab_OnClick", function ()
	if GuildBankFrame.mode == "log" or GuildBankFrame.mode == "bank" then
		GBS.FilterButton:Enable();
	else
		GBS:Hide();
		GBS.FilterButton:Disable();
	end
end );
hooksecurefunc( "GuildBankFrame_Update", function ( _, Tab )
	GBS.Filter( true );
end );
do
	local AddMessageBackup = GuildBankMessageFrame.AddMessage;
	function GuildBankMessageFrame:AddMessage ( Message, ... )
		if GuildBankFrame.mode == "log" and GBS:IsShown() and GBS.IsFilterDefined() then
			if not GBS.MatchItem( select( 3, Message:find( "|H(item[-:0-9]+)|h" ) ) ) then
				return AddMessageBackup( self, Message:gsub( "|cff[%x%X][%x%X][%x%X][%x%X][%x%X][%x%X]", "" ):gsub( "|r", "" ), 0.25, 0.25, 0.25, select( 4, ... ) );
			end
		end
		return AddMessageBackup( self, Message, ... );
	end
end

local NextUpdate = 0;
GBS:SetScript( "OnShow", function ( self )
	PlaySound( "igCharacterInfoOpen" );
	self.FilterButton:SetButtonState( "PUSHED", true );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", GBS, "TOPRIGHT", -8, -16 );

	self.Filter( true );
end );
GBS:SetScript( "OnHide", function ( self )
	PlaySound( "igCharacterInfoClose" );
	self.FilterButton:SetButtonState( "NORMAL" );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -1, -32 );
	self.HideFilter();
end );
GBS:SetScript( "OnUpdate", function ( self, Elapsed )
	NextUpdate = NextUpdate - Elapsed;
	if self.NeedUpdate and NextUpdate <= 0 then
		self.NeedUpdate = false;
		NextUpdate = 0.5;

		self:ShowFilter();
	end
end );
GBS:SetScript( "OnEvent", function ( self, Event )
	self.Filter( true );
end );
GBS:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" );
GBS:RegisterEvent( "GUILDBANKLOG_UPDATE" );

function GBS.Filter ( Force )
	GBS.NeedUpdate = true;
	if Force then
		NextUpdate = 0;
	end
end
function GBS.IsFilterDefined ()
	return GBS.NamePattern or GBS.Quality or GBS.Type or GBS.SubType or GBS.Slot or GBS.ItemLevelMin or GBS.ItemLevelMax or GBS.ReqLevelMin or GBS.ReqLevelMax;
end
do
	local Name, Link, Rarity, ItemLevel, ReqLevel, Type, SubType, StackCount, Slot;
	function GBS.MatchItem ( ItemLink )
		if not ItemLink then
			return false;
		end
		Name, Link, Rarity, ItemLevel, ReqLevel, Type, SubType, StackCount, Slot = GetItemInfo( ItemLink );
		if GBS.NamePattern and not Name:lower():find( GBS.NamePattern:lower(), 1, true ) then
			return false;
		elseif GBS.Quality and GBS.Quality ~= Rarity then
			return false;
		elseif GBS.Type and GBS.Type ~= Type then
			return false;
		elseif GBS.SubType and GBS.SubType ~= SubType then
			return false;
		elseif GBS.Slot and not GBS.SlotGroups[ GBS.Slot ][ Slot ] then
			return false;
		elseif GBS.ItemLevelMin and GBS.ItemLevelMin > ItemLevel then
			return false;
		elseif GBS.ItemLevelMax and GBS.ItemLevelMax < ItemLevel then
			return false;
		elseif GBS.ReqLevelMin and GBS.ReqLevelMin > ReqLevel then
			return false;
		elseif GBS.ReqLevelMax and GBS.ReqLevelMax < ReqLevel then
			return false;
		end
		return true;
	end
end
function GBS.HideFilter ()
	for Index, Button in ipairs( GBS.Buttons ) do
		Button:SetAlpha( 1 );
	end
	if GuildBankFrame.mode == "log" then
		GuildBankFrame_UpdateLog();
	end
end
function GBS.ShowFilter ()
	if not GBS.IsFilterDefined() then
		return GBS.HideFilter();
	end

	if GuildBankFrame.mode == "bank" then
		local Tab = GetCurrentGuildBankTab();
		if Tab <= GetNumGuildBankTabs() then
			for Index, Button in ipairs( GBS.Buttons ) do
				Button:SetAlpha( GBS.MatchItem( GetGuildBankItemLink( Tab, Index ) ) and 1 or 0.25 );
			end
		end
	elseif GuildBankFrame.mode == "log" then
		GuildBankFrame_UpdateLog();
	end
end

GBS.ClearFilter();
