--[[****************************************************************************
  * ItemRackTitles by Saiket                                                   *
  * ItemRackTitles.lua - Swap titles with your gear sets.                      *
  ****************************************************************************]]


local L = ItemRackTitlesLocalization;
local ItemRack = ItemRack;
local me = CreateFrame( "Frame", "ItemRackTitles" );
local Options = {};
me.Options = Options;

me.DebugErrors = false; -- Note: Change "false" to "true" here to enable debug error messages!

local CLEAR_TITLE = -1; -- Clears title when passed to SetCurrentTitle




--[[****************************************************************************
  * Function: ItemRackTitles.InvalidVersionError                               *
  * Description: Prints an error message only once per login.                  *
  ****************************************************************************]]
do
	local Printed = false;
	function me.InvalidVersionError ()
		if ( not Printed ) then
			Printed = true;
			local Color = RED_FONT_COLOR;
			DEFAULT_CHAT_FRAME:AddMessage( L.INVALID_VERSION, Color.r, Color.g, Color.b );
			message( L.INVALID_VERSION );
		end
	end
end
--[[****************************************************************************
  * Function: ItemRackTitles.SafeCall                                          *
  * Description: Runs a function with version mismatch-prone code and replaces *
  *   error messages with a version notice popup.  Returns true on no errors.  *
  * Note: Set ItemRackTitles.DebugErrors flag to throw errors (blocking call!) *
  ****************************************************************************]]
function me.SafeCall ( Function )
	local Success, ErrorMessage = pcall( Function );
	if ( not Success ) then
		if ( me.DebugErrors or IsAddOnLoaded( "_Dev" ) ) then
			error( ErrorMessage ); -- Blocking call!
		else -- Show user friendly upgrade prompt
			me.InvalidVersionError();
		end
	end
	return Success;
end


--[[****************************************************************************
  * Function: ItemRackTitles.IsTitleKnown                                      *
  * Description: Returns true if a title ID is known.                          *
  ****************************************************************************]]
function me.IsTitleKnown ( ID )
	return ID == CLEAR_TITLE or IsTitleKnown( ID ) == 1; -- Note: IsTitleKnown(-1) crashes the client
end
--[[****************************************************************************
  * Function: ItemRackTitles.GetTitleName                                      *
  * Description: Returns the title's name, or a string representing no title.  *
  ****************************************************************************]]
function me.GetTitleName ( ID )
	local Title = GetTitleName( ID );
	return Title and Title:trim() or L.CLEAR_TITLE;
end
--[[****************************************************************************
  * Function: ItemRackTitles.ValidateSets                                      *
  * Description: Removes any unknown titles from saved sets.                   *
  ****************************************************************************]]
function me.ValidateSets ()
	for SetName, Set in pairs( ItemRackUser.Sets ) do
		if ( Set.Title and not me.IsTitleKnown( Set.Title ) ) then
			Set.Title = CLEAR_TITLE;
		end
	end
end
--[[****************************************************************************
  * Function: ItemRackTitles.EquipSet                                          *
  * Description: Hook to change titles on set changes.                         *
  ****************************************************************************]]
function me.EquipSet ( Name )
	local Set = ItemRackUser.Sets[ Name ];
	if ( Set and Set.Title and Set.Title ~= GetCurrentTitle() ) then
		SetCurrentTitle( Set.Title );
	end
end
--[[****************************************************************************
  * Function: ItemRackTitles.SetTooltip                                        *
  * Description: Hook to add titles to set tooltips.                           *
  ****************************************************************************]]
function me.SetTooltip ( Name )
	if ( ItemRackSettings.TinyTooltips ~= "ON" ) then
		local Set = ItemRackUser.Sets[ Name ];
		if ( Set and Set.equip and Set.Title ) then
			local Text, Color = GameTooltipTextRight1, HIGHLIGHT_FONT_COLOR;
			Text:SetFormattedText( L.TOOLTIP_TITLE_FORMAT, me.GetTitleName( Set.Title ) );
			Text:SetTextColor( Color.r, Color.g, Color.b );
			Text:Show();
			GameTooltip:Show();
		end
	end
end


--[[****************************************************************************
  * Function: ItemRackTitles:OnEvent                                           *
  * Description: Watches for ItemRackOptions to load and adds controls.        *
  ****************************************************************************]]
function me:OnEvent ( Event, AddOn )
	if ( Event == "ADDON_LOADED" ) then
		if ( AddOn:lower() == "itemrackoptions" ) then
			me:UnregisterEvent( Event );
			if ( me.SafeCall( Options.OnLoad ) ) then
				Options.OnLoad = nil; -- Garbage collect and cause Options.IsLoaded to return true
			end
		end
	elseif ( Event == "OLD_TITLE_LOST" ) then
		me.ValidateSets();
		Options.UpdateTitleDropdown();
	elseif ( Event == "NEW_TITLE_EARNED" ) then
		Options.UpdateTitleDropdown();
	elseif ( Event == "PLAYER_LOGIN" ) then
		me.ValidateSets();
	end
end




--[[****************************************************************************
  * Function: ItemRackTitles.Options.OnLoad                                    *
  * Description: Makes modifications to the configuration GUI.                 *
  ****************************************************************************]]
function Options.OnLoad ()
	-- Make room for the dropdown menu
	local IconSelect = ItemRackOptSetsIconFrame;
	IconSelect:SetHeight( 152 );
	ItemRackOptSetsIcon1:SetPoint( "TOPLEFT", 8, -6 );

	local Bind = ItemRackOptSetsBindButton;
	Bind:ClearAllPoints();
	Bind:SetPoint( "BOTTOMRIGHT", -12, 8 );
	Bind:SetHeight( 24 );
	local Delete = ItemRackOptSetsDeleteButton;
	Delete:SetPoint( "TOPRIGHT", Bind, "TOPLEFT", -12, 0 );
	Delete:SetHeight( 24 );
	local Save = ItemRackOptSetsSaveButton;
	Save:ClearAllPoints();
	Save:SetPoint( "BOTTOMRIGHT", Bind, "TOPRIGHT", 0, 4 );
	Save:SetHeight( 24 );

	local Helm = ItemRackOptShowHelm;
	Helm:ClearAllPoints();
	Helm:SetPoint( "TOP", Save );
	Helm:SetPoint( "LEFT", Delete, 2, 0 );
	Helm:SetWidth( 14 );
	Helm:SetHeight( 14 );
	local Cloak = ItemRackOptShowCloak;
	Cloak:SetWidth( 14 );
	Cloak:SetHeight( 14 );
	Cloak:SetPoint( "TOPLEFT", Helm, "BOTTOMLEFT", 0, 2 );

	local Hide = ItemRackOptSetsHideCheckButton;
	Hide:ClearAllPoints();
	Hide:SetPoint( "BOTTOMLEFT", 8, 6 );
	Hide:SetWidth( 16 );
	Hide:SetHeight( 16 );
	local Icon = ItemRackOptSetsCurrentSet;
	Icon:ClearAllPoints();
	Icon:SetPoint( "BOTTOMLEFT", Hide, "TOPLEFT", 4, 2 );
	Icon:SetScale( 0.9 );


	-- Add enable checkbox
	local Checkbox = CreateFrame( "CheckButton", "ItemRackTitlesCheckbox", ItemRackOptSubFrame2, "ItemRackOptSimpleCheckButton" );
	Options.Checkbox = Checkbox;
	Checkbox:SetPoint( "TOP", IconSelect, "BOTTOM", 0, 2 );
	Checkbox:SetPoint( "LEFT", 8, 0 );
	Checkbox:SetWidth( 16 );
	Checkbox:SetHeight( 16 );
	Checkbox:SetScript( "OnClick", Options.CheckboxOnClick );
	local Label = ItemRackTitlesCheckboxText;
	Options.Label = Label;
	Label:SetText( L.OPTIONS_ENABLE );
	Label:SetTextColor( 1, 1, 1, 1 );

	-- Add dropdown menu
	local Dropdown = CreateFrame( "Frame", "ItemRackTitlesDropdown", ItemRackOptSubFrame2, "UIDropDownMenuTemplate" );
	Options.Dropdown = Dropdown;
	Dropdown:SetPoint( "TOP", IconSelect, "BOTTOM", 0, 8 );
	Dropdown:SetPoint( "LEFT", Label, "RIGHT", -16, 0 );
	Dropdown:SetPoint( "RIGHT", -10, 0 );
	Dropdown:SetScale( 0.9 );
	Dropdown.initialize = Options.DropdownInitialize;
	UIDropDownMenu_JustifyText( Dropdown, "LEFT" );
	ItemRackTitlesDropdownMiddle:SetPoint( "RIGHT", -16, 0 );
	local Button = ItemRackTitlesDropdownButton;
	Button:SetScript( "OnEnter", function () ItemRack.OnTooltip(); end );
	Button:SetScript( "OnLeave", function () GameTooltip:Hide(); end );
	ItemRackOptSetsIconFrame:SetFrameLevel( Button:GetFrameLevel() + 1 );
	local function AdjustTexture ( Texture )
		-- Shave a bit off the top of the texture
		local Percent = 0.05;
		local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = Texture:GetTexCoord();
		Texture:SetTexCoord( ULx, ( LLy - ULy ) * Percent + ULy, LLx, LLy, URx, ( LRy - URy ) * Percent + URy, LRx, LRy );
	end
	AdjustTexture( ItemRackTitlesDropdownLeft );
	AdjustTexture( ItemRackTitlesDropdownMiddle );
	AdjustTexture( ItemRackTitlesDropdownRight );

	-- Add hooks to save and update the dropdown
	hooksecurefunc( ItemRackOpt, "SaveSet", Options.SaveSet );
	hooksecurefunc( ItemRackOpt, "SelectSetList", Options.LoadSet ); -- On selecting new set
	hooksecurefunc( ItemRackOpt, "LoadSet", Options.LoadSet ); -- Unused, but still functional
	hooksecurefunc( ItemRackOpt, "ChangeEditingSet", Options.LoadSet ); -- On actual set change with options window open
	hooksecurefunc( ItemRackOpt, "OnShow", Options.OnShow ); -- When opened
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.IsLoaded                                  *
  * Description: Returns true if the options menu is loaded and modified.      *
  ****************************************************************************]]
function Options.IsLoaded ()
	return not Options.OnLoad;
end


--[[****************************************************************************
  * Function: ItemRackTitles.Options.SaveSet                                   *
  * Description: Hook to save title data along with the rest of the set.       *
  ****************************************************************************]]
function Options.SaveSet ()
	local Set = Options.GetCurrentSet();
	if ( not Set ) then -- Shouldn't happen here
		me.InvalidVersionError();
	else
		Set.Title = Options.Enabled and Options.Selected or nil;
	end
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.LoadSet                                   *
  * Description: Hook to load title data along with the rest of the set.       *
  ****************************************************************************]]
function Options.LoadSet ()
	Options.ShowSet( Options.GetCurrentSet() );
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.OnShow                                    *
  * Description: Hook to load current title data when opening the GUI.         *
  ****************************************************************************]]
function Options.OnShow ( SetName )
	-- Note: SetName is unused in the original function
	Options.ShowSet( ItemRackUser.Sets[ ItemRackUser.CurrentSet ] );
end


--[[****************************************************************************
  * Function: ItemRackTitles.Options.ShowSet                                   *
  * Description: Displays settings for a set, or defaults if set is nil.       *
  ****************************************************************************]]
function Options.ShowSet ( Set )
	Options.SetEnabled( Set ~= nil and Set.Title ~= nil );
	Options.SetTitle( Set and Set.Title or CLEAR_TITLE );
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.GetCurrentSet                             *
  * Description: Returns the currently displayed set table or nil.             *
  ****************************************************************************]]
function Options.GetCurrentSet ()
	if ( not ItemRackOptSetsName ) then
		me.InvalidVersionError();
	else
		return ItemRackUser.Sets[ ItemRackOptSetsName:GetText() ];
	end
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.SetEnabled                                *
  * Description: Checks/unchecks the enable checkbutton.                       *
  ****************************************************************************]]
function Options.SetEnabled ( Enabled )
	Options.Enabled = Enabled;
	Options.Checkbox:SetChecked( Enabled );
	local Color;
	if ( Enabled ) then
		UIDropDownMenu_EnableDropDown( Options.Dropdown );
		Color = HIGHLIGHT_FONT_COLOR;
	else
		UIDropDownMenu_DisableDropDown( Options.Dropdown );
		Color = GRAY_FONT_COLOR;
		CloseDropDownMenus();
	end
	Options.Label:SetTextColor( Color.r, Color.g, Color.b );
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.SetTitle                                  *
  * Description: Displays the given title in the dropdown.                     *
  ****************************************************************************]]
function Options.SetTitle ( Index )
	Options.Selected = Index;
	UIDropDownMenu_SetText( Options.Dropdown, me.GetTitleName( Index ) );
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.UpdateTitleDropdown                       *
  * Description: Redraws the title dropdown if it's visible and validates it.  *
  ****************************************************************************]]
function Options.UpdateTitleDropdown ()
	if ( Options.IsLoaded() ) then
		if ( UIDropDownMenu_GetCurrentDropDown() == Options.Dropdown and DropDownList1:IsShown() ) then
			-- Redraw the menu while it's already open
			CloseDropDownMenus();
			ToggleDropDownMenu( nil, nil, Options.Dropdown );
		end
		if ( not me.IsTitleKnown( Options.Selected ) ) then
			Options.SetTitle( CLEAR_TITLE );
		end
	end
end


--[[****************************************************************************
  * Function: ItemRackTitles.Options:CheckboxOnClick                           *
  * Description: Toggles enabling the title.                                   *
  ****************************************************************************]]
function Options:CheckboxOnClick ()
	local Checked = self:GetChecked() == 1;
	Options.SetEnabled( Checked );
	PlaySound( Checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options.DropdownInitialize                        *
  * Description: Constructs a sorted list of known titles for the dropdown.    *
  ****************************************************************************]]
do
	local Sorted = {};
	local Lookup = {};
	local GetTitleName = GetTitleName;
	local function SortFunc ( ID1, ID2 )
		return Lookup[ ID1 ] < Lookup[ ID2 ];
	end
	function Options.DropdownInitialize ()
		for Index = 1, GetNumTitles() - 1 do
			if ( IsTitleKnown( Index ) == 1 ) then
				Sorted[ #Sorted + 1 ] = Index;
				-- Cache the string used in comparisons
				Lookup[ Index ] = me.GetTitleName( Index ):lower();
			end
		end
		table.sort( Sorted, SortFunc );
		local Info = UIDropDownMenu_CreateInfo();
		Info.text = me.GetTitleName( CLEAR_TITLE ); -- Add no title option
		Info.arg1 = CLEAR_TITLE;
		Info.checked = CLEAR_TITLE == Options.Selected;
		Info.func = Options.DropdownOnSelect;
		UIDropDownMenu_AddButton( Info );
		for _, Index in ipairs( Sorted ) do
			Info.text = me.GetTitleName( Index );
			Info.arg1 = Index;
			Info.checked = Index == Options.Selected;
			UIDropDownMenu_AddButton( Info );
		end

		wipe( Sorted );
		wipe( Lookup );
	end
end
--[[****************************************************************************
  * Function: ItemRackTitles.Options:DropdownOnSelect                          *
  ****************************************************************************]]
function Options:DropdownOnSelect ( Value )
	Options.SetTitle( Value );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

if ( not ItemRackUser or not ItemRackUser.Sets ) then
	me.InvalidVersionError();
elseif ( me.SafeCall( function ()
	-- Run code prone to version mismatch errors first, and hooks last
	tinsert( ItemRack.TooltipInfo, {
		"ItemRackTitlesCheckbox",
		L.OPTIONS_ENABLE,
		L.OPTIONS_ENABLE_DESC
	} );
	tinsert( ItemRack.TooltipInfo, {
		"ItemRackTitlesDropdownButton",
		L.OPTIONS_DROPDOWN,
		L.OPTIONS_DROPDOWN_DESC
	} );

	hooksecurefunc( ItemRack, "EquipSet", me.EquipSet );
	hooksecurefunc( ItemRack, "SetTooltip", me.SetTooltip );
end ) ) then
	-- Hooking succeeded; assume compatible version
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
	me:RegisterEvent( "PLAYER_LOGIN" );
	me:RegisterEvent( "OLD_TITLE_LOST" );
	me:RegisterEvent( "NEW_TITLE_EARNED" );
end
