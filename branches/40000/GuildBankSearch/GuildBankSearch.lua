--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * GuildBankSearch.lua - Adds a search filter to the guild bank.              *
  ****************************************************************************]]


local me = select( 2, ... );
GuildBankSearch = me;
local L = me.L;

me.Frame = CreateFrame( "Frame", "GuildBankSearchFrame", GuildBankFrame );
me.Frame.UpdateRate = 0.5;
me.Frame.NextUpdate = 0;
me.Frame.NeedUpdate = false;

me.ToggleButton = CreateFrame( "Button", nil, GuildBankFrame, "UIPanelButtonTemplate" );

me.Clear = CreateFrame( "Button", nil, me.Frame, "UIPanelButtonTemplate" );
me.Name = CreateFrame( "EditBox", "$parentName", me.Frame, "InputBoxTemplate" );
me.Text = CreateFrame( "EditBox", "$parentText", me.Frame, "InputBoxTemplate" );
me.Quality = CreateFrame( "Frame", "$parentQuality", me.Frame, "UIDropDownMenuTemplate" );
me.ItemLevelMin = CreateFrame( "EditBox", "$parentItemLevelMin", me.Frame, "InputBoxTemplate" );
me.ItemLevelMax = CreateFrame( "EditBox", "$parentItemLevelMax", me.Frame, "InputBoxTemplate" );
me.ReqLevelMin = CreateFrame( "EditBox", "$parentReqLevelMin", me.Frame, "InputBoxTemplate" );
me.ReqLevelMax = CreateFrame( "EditBox", "$parentReqLevelMax", me.Frame, "InputBoxTemplate" );

me.CategorySection = CreateFrame( "Frame", "$parentCategory", me.Frame, "OptionsBoxTemplate" );
me.Type = CreateFrame( "Frame", "$parentType", me.CategorySection, "UIDropDownMenuTemplate" );
me.SubType = CreateFrame( "Frame", "$parentSubType", me.CategorySection, "UIDropDownMenuTemplate" );
me.Slot = CreateFrame( "Frame", "$parentSlot", me.CategorySection, "UIDropDownMenuTemplate" );


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
me.Filter = Filter;

me.Qualities = {};
me.Types = { GetAuctionItemClasses() };
me.SubTypes = {};
me.Slots = {}; -- Sorted list of inventory types that can be searched for
me.SlotGroups = { -- Categories paired with the inventory types that can match them (can be multiple)
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

me.ButtonMismatchAlpha = 0.25;
me.LogMismatchColor = { r = 0.25; g = 0.25; b = 0.25; };
me.Buttons = {}; -- Cache of all item buttons in bank view




--- Updates filter when name parameter changes.
function me.Name:OnTextChanged ()
	local Text = self:GetText();
	Filter.Name = Text ~= "" and Text:lower() or nil;
	me.FilterUpdate();
end
--- Updates filter when text parameter changes.
function me.Text:OnTextChanged ()
	local Text = self:GetText();
	Filter.Text = Text ~= "" and Text:lower() or nil;
	me.FilterUpdate();
end
--- @return An iterator to list all qualities.
function me.Quality.IterateOptions ()
	return ipairs( me.Qualities );
end

--- Updates the subtype dropdown when a type is chosen.
function me.Type:OnSelect ( Dropdown, Type )
	if ( Filter.Type ~= Type ) then
		me.SubType.OnSelect( nil, me.SubType ); -- Remove subtype filter
		if ( not Type ) then
			UIDropDownMenu_DisableDropDown( me.SubType );
		else
			UIDropDownMenu_EnableDropDown( me.SubType );
		end
		me.DropdownOnSelect( self, Dropdown, Type );
	end
end
--- @return An iterator to list all types.
function me.Type.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = me.Types[ Index ];
		return Label, Label;
	end;
end
--- @return An iterator to list all sub-types.
function me.SubType.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Label = me.SubTypes[ Filter.Type ][ Index ];
		return Label, Label;
	end;
end
--- @return An iterator to list all gear slots.
function me.Slot.IterateOptions ()
	local Index = 0;
	return function ()
		Index = Index + 1;
		local Slot = me.Slots[ Index ];
		return Slot, _G[ Slot ];
	end;
end

--- Generic handler to update the filter when one of the level edit boxes changes.
function me:LevelEditBoxOnTextChanged ()
	local NewLevel = self:GetText() ~= "" and self:GetNumber() or nil;
	if ( NewLevel ~= Filter[ self.Parameter ] ) then
		Filter[ self.Parameter ] = NewLevel;
		me.FilterUpdate();
	end
end
--- Generic handler to update the filter when a dropdown's value changes.
function me:DropdownOnSelect ( Dropdown, Value )
	if ( Value ~= Filter[ Dropdown.Parameter ] ) then
		UIDropDownMenu_SetText( Dropdown, self and self.value or L.ALL );
		Filter[ Dropdown.Parameter ] = Value;
		me.FilterUpdate();
	end
end
--- Generic handler to construct dropdown menus using their custom iterators.
function me:DropdownInitialize ()
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
function me.FilterClear ()
	CloseDropDownMenus(); -- Close dropdown if open

	me.Name:SetText( "" );
	me.Text:SetText( "" );
	me.Quality.OnSelect( nil, me.Quality );
	me.ItemLevelMin:SetText( "" );
	me.ItemLevelMax:SetText( "" );
	me.ReqLevelMin:SetText( "" );
	me.ReqLevelMax:SetText( "" );

	-- Item category fields
	me.Type.OnSelect( nil, me.Type ); -- Also clears SubType
	me.Slot.OnSelect( nil, me.Slot );
end

--- Requests an update to the bank or log display.
-- @param Force  Executes the update on the next frame, ignoring throttling.
function me.FilterUpdate ( Force )
	me.Frame.NeedUpdate = true;
	if ( Force ) then
		me.Frame.NextUpdate = 0;
	end
end
--- @return True if any filter parameters are set.
function me.IsFilterDefined ()
	return next( Filter ) ~= nil;
end

do
	local Tooltip = CreateFrame( "GameTooltip", "$parentTooltip", me.Frame );
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
			Tooltip:SetOwner( me.Frame, "ANCHOR_NONE" );
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
			return me.SlotGroups[ SlotGroup ][ select( 9, ... ) ];
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
	function me.MatchItem ( ItemLink )
		if ( ItemLink ) then
			return MatchItemInfo( GetItemInfo( ItemLink ) );
		end
	end
end

--- Restores an unfiltered view of the bank and log.
function me.FilterSuspend ()
	for Index, Button in ipairs( me.Buttons ) do
		Button:SetAlpha( 1 );
	end
	if ( GuildBankFrame.mode == "log" ) then
		GuildBankFrame_UpdateLog();
	end
end
do
	local GetGuildBankItemLink = GetGuildBankItemLink;
	--- Applies or refreshes the current filter to the bank or log view.
	function me.FilterResume ()
		if ( not me.IsFilterDefined() ) then
			return me.FilterSuspend();
		end

		if ( GuildBankFrame.mode == "bank" ) then
			local Tab = GetCurrentGuildBankTab();
			if ( Tab <= GetNumGuildBankTabs() ) then
				for Index, Button in ipairs( me.Buttons ) do
					Button:SetAlpha( me.MatchItem( GetGuildBankItemLink( Tab, Index ) )
						and 1 or me.ButtonMismatchAlpha );
				end
			end
		elseif ( GuildBankFrame.mode == "log" ) then
			GuildBankFrame_UpdateLog();
		end
	end
end




--- Hook to enable the filter depending on which bank view is displayed.
function me.GuildBankFrameTabOnClick ()
	if ( GuildBankFrame.mode == "log" or GuildBankFrame.mode == "bank" ) then
		me.ToggleButton:Enable();
	else
		me.Frame:Hide();
		me.ToggleButton:Disable();
	end
end
--- Hook to update the filter display when the bank view type changes.
function me.GuildBankFrameUpdate ()
	me.FilterUpdate( true );
end
do
	local AddMessageBackup = GuildBankMessageFrame.AddMessage;
	--- Hook that modifies added messages when a filter is active.
	function me:GuildBankMessageFrameAddMessage ( Message, ... )
		if ( GuildBankFrame.mode == "log"
			and me.Frame:IsShown() and me.IsFilterDefined()
			and not me.MatchItem( Message:match( "|H(item:[^|]+)|h" ) )
		) then
			local Color = me.LogMismatchColor;
			-- Remove all color codes
			return AddMessageBackup( self,
				Message:gsub( "|cff%x%x%x%x%x%x", "" ):gsub( "|r", "" ),
				Color.r, Color.g, Color.b, select( 4, ... ) );
		end
		return AddMessageBackup( self, Message, ... );
	end
end
do
	local InsertLinkBackup = ChatEdit_InsertLink;
	--- Hook to add linked items to the name filter edit box.
	function me.ChatEditInsertLink ( Link, ... )
		if ( InsertLinkBackup( Link, ... ) ) then
			return true;
		elseif ( Link and me.Name:IsVisible() ) then
			local Name = GetItemInfo( Link );
			if ( Name ) then
				me.Name:SetText( Name );
				return true;
			end
		end
		return false;
	end
end




--- Makes room for the filter pane and refreshes the filter when shown.
function me.Frame:OnShow ()
	PlaySound( "igCharacterInfoOpen" );
	me.ToggleButton:SetButtonState( "PUSHED", true );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", me.Frame, "TOPRIGHT", -8, -16 );

	me.FilterUpdate( true );
end
--- Undoes changes to bank window and clears any filter display when hidden.
function me.Frame:OnHide ()
	PlaySound( "igCharacterInfoClose" );
	me.ToggleButton:SetButtonState( "NORMAL" );
	GuildBankTab1:ClearAllPoints();
	GuildBankTab1:SetPoint( "TOPLEFT", GuildBankFrame, "TOPRIGHT", -1, -32 );
	me.FilterSuspend();
end
--- Throttles filter display updates.
function me.Frame:OnUpdate ( Elapsed )
	self.NextUpdate = self.NextUpdate - Elapsed;
	if ( self.NeedUpdate and self.NextUpdate <= 0 ) then
		self.NeedUpdate, self.NextUpdate = false, self.UpdateRate;

		me.FilterResume();
	end
end
--- Forces a display update when bank contents change.
function me.Frame:OnEvent ()
	me.FilterUpdate( true );
end

--- Shows or hides the filter pane.
function me.Toggle ()
	if ( me.Frame:IsShown() ) then
		me.Frame:Hide();
	else
		me.Frame:Show();
	end
end




-- Fill in quality labels
for Index = 0, #ITEM_QUALITY_COLORS do
	me.Qualities[ Index ] = ITEM_QUALITY_COLORS[ Index ].hex
		.._G[ "ITEM_QUALITY"..Index.."_DESC" ]..FONT_COLOR_CODE_CLOSE;
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
	local Column = floor( ( Index - 1 ) / NUM_SLOTS_PER_GUILDBANK_GROUP ) + 1;
	local Slot = ( Index - 1 ) % NUM_SLOTS_PER_GUILDBANK_GROUP + 1;
	me.Buttons[ Index ] = _G[ "GuildBankColumn"..Column.."Button"..Slot ];
end


-- Set up filter button
me.ToggleButton:SetSize( 100, 21 );
me.ToggleButton:SetPoint( "TOPRIGHT", -11, -40 );
me.ToggleButton:SetText( L.FILTER );
me.ToggleButton:SetScript( "OnClick", me.Toggle );


-- Set up filter pane
local Frame = me.Frame;
Frame:Hide();
Frame:SetSize( 187, 389 );
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
Top:SetSize( 256, 256 );
Top:SetPoint( "TOPLEFT" );
local Bottom = Frame:CreateTexture( nil, "BACKGROUND" );
Bottom:SetTexture( [[Interface\AuctionFrame\AuctionHouseDressUpFrame-Bottom]] );
Bottom:SetSize( 256, 256 );
Bottom:SetPoint( "TOPLEFT", Top, "BOTTOMLEFT" );
local Corner = Frame:CreateTexture( nil, "BACKGROUND" );
Corner:SetTexture( [[Interface\AuctionFrame\AuctionHouseDressUpFrame-Corner]] );
Corner:SetSize( 32, 32 );
Corner:SetPoint( "TOPRIGHT", -5, -5 );


-- Close button
CreateFrame( "Button", nil, Frame, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 1, 0 );

local Clear = me.Clear;
Clear:SetSize( 45, 18 );
Clear:SetPoint( "TOPRIGHT", -31, -8 );
Clear:SetText( L.CLEAR );
Clear:SetScript( "OnClick", me.FilterClear );


-- Filter controls
--- Sets up a dropdown filter control.
-- @param Parameter  Key in the Filter table.
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
--- Sets up a numeric editbox as a level filter control.
-- @param Parameter  Key in the Filter table.
local function InitializeLevelEditBox ( self, Parameter, Label )
	self:SetSize( 25, 16 );
	self:SetNumeric( true );
	self:SetMaxLetters( 3 );
	self:SetAutoFocus( false );
	self:SetScript( "OnTextChanged", me.LevelEditBoxOnTextChanged );
	self.Parameter = Parameter;
	self.Label = self:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
	self.Label:SetText( Label );
	return self;
end

local Name = me.Name;
Name:SetHeight( 16 );
Name:SetAutoFocus( false );
Name:SetPoint( "TOP", Clear, "BOTTOM", 0, -20 );
Name:SetPoint( "LEFT", 16, 0 );
Name:SetPoint( "RIGHT", -16, 0 );
Name:SetScript( "OnTextChanged", Name.OnTextChanged );
local Label = Name:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
Label:SetPoint( "BOTTOMLEFT", Name, "TOPLEFT", 1, 0 );
Label:SetText( L.NAME );

local Text = me.Text;
Text:SetHeight( 16 );
Text:SetAutoFocus( false );
Text:SetPoint( "TOP", Name, "BOTTOM", 0, -12 );
Text:SetPoint( "LEFT", Name );
Text:SetPoint( "RIGHT", Name );
Text:SetScript( "OnTextChanged", Text.OnTextChanged );
local Label = Text:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" );
Label:SetPoint( "BOTTOMLEFT", Text, "TOPLEFT", 1, 0 );
Label:SetText( L.TEXT );

InitializeDropdown( me.Quality, "Quality", L.QUALITY ):SetPoint( "TOP", Text, "BOTTOM", 0, -12 );

-- Item level range
local ItemLevelMin = InitializeLevelEditBox( me.ItemLevelMin, "ItemLevelMin", L.ITEM_LEVEL );
ItemLevelMin:SetPoint( "TOP", me.Quality, "BOTTOM", 0, -16 );
ItemLevelMin:SetPoint( "LEFT", 16, 0 );
local ItemLevelMax = InitializeLevelEditBox( me.ItemLevelMax, "ItemLevelMax", L.LEVELRANGE_SEPARATOR );
ItemLevelMax.Label:SetPoint( "LEFT", ItemLevelMin, "RIGHT", 2, 0 );
ItemLevelMax:SetPoint( "LEFT", ItemLevelMax.Label, "RIGHT", 8, 0 );
ItemLevelMin.Label:SetPoint( "CENTER", ItemLevelMax.Label ); -- Center above dash between edit boxes
ItemLevelMin.Label:SetPoint( "BOTTOM", ItemLevelMin, "TOP" );

-- Required level range
local ReqLevelMax = InitializeLevelEditBox( me.ReqLevelMax, "ReqLevelMax", L.REQUIRED_LEVEL );
ReqLevelMax:SetPoint( "TOP", me.ItemLevelMin );
ReqLevelMax:SetPoint( "RIGHT", -24, 0 );
local ReqLevelMin = InitializeLevelEditBox( me.ReqLevelMin, "ReqLevelMin", L.LEVELRANGE_SEPARATOR );
ReqLevelMin.Label:SetPoint( "RIGHT", ReqLevelMax, "LEFT", -8, 0 );
ReqLevelMin:SetPoint( "RIGHT", ReqLevelMin.Label, "LEFT", -2, 0 );
ReqLevelMax.Label:SetPoint( "CENTER", ReqLevelMin.Label );
ReqLevelMax.Label:SetPoint( "BOTTOM", ReqLevelMax, "TOP" );

-- Item category section
local CategorySection = me.CategorySection;
_G[ CategorySection:GetName().."Title" ]:SetText( L.ITEM_CATEGORY );
CategorySection:SetPoint( "TOP", ItemLevelMin, "BOTTOM", 0, -38 );
CategorySection:SetPoint( "LEFT", 8, 0 );
CategorySection:SetPoint( "BOTTOMRIGHT", -16, 16 );

InitializeDropdown( me.Type, "Type", L.TYPE ):SetPoint( "TOP", 0, -16 );
InitializeDropdown( me.SubType, "SubType", L.SUB_TYPE ):SetPoint( "TOP", me.Type, "BOTTOM", 0, -6 );
InitializeDropdown( me.Slot, "Slot", L.SLOT ):SetPoint( "TOP", me.SubType, "BOTTOM", 0, -16 );


-- Hooks
hooksecurefunc( "GuildBankFrameTab_OnClick", me.GuildBankFrameTabOnClick );
hooksecurefunc( "GuildBankFrame_Update", me.GuildBankFrameUpdate );
GuildBankMessageFrame.AddMessage = me.GuildBankMessageFrameAddMessage;
ChatEdit_InsertLink = me.ChatEditInsertLink;

me.FilterClear();
wipe( Filter ); -- FilterClear won't fire edit box OnTextChanged handlers, so clear manually.
me.FilterUpdate( true );