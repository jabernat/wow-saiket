--[[****************************************************************************
  * _Vendor by Saiket                                                          *
  * _Vendor.lua - Buys items for free just before servers restart.             *
  ****************************************************************************]]


_VendorOptions = {
	PriceCheck = true; -- Whether to validate costs of items as added
	ExtraLeadTime = 0;
};




local L = _VendorLocalization;
local me = CreateFrame( "Frame", "_Vendor" );

me.Tooltip = CreateFrame( "GameTooltip", "_VendorTooltip" );
me.MerchantItemButtonOnModifiedClickBackup = MerchantItemButton_OnModifiedClick;

local SlashSubCommands = {}; -- Hash of name (caps) to handler
me.SlashSubCommands = SlashSubCommands;

local ItemInfo = {};
me.ItemInfo = ItemInfo;

local Items = {}; -- Hash of item names to quantities
me.Items = Items;




--[[****************************************************************************
  * Function: _Vendor.Print                                                    *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
function me.Print ( Message, ChatFrame, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( L.MESSAGE_FORMAT:format( Message ),
		Color.r, Color.g, Color.b, Color.id );
end
--[[****************************************************************************
  * Function: _Vendor.Error                                                    *
  * Description: Displays an error message, and optionally plays a sound.      *
  ****************************************************************************]]
function me.Error ( Message, Color, MuteSound )
	if ( not Color ) then
		Color = RED_FONT_COLOR;
	end
	UIErrorsFrame:AddMessage( L.ERROR_FORMAT:format( Message ),
		Color.r, Color.g, Color.b, UIERRORS_HOLD_TIME );
	me.Print( Message, nil, Color );
	if ( not MuteSound ) then
		PlaySound( "igQuestFailed" );
	end
end




--[[****************************************************************************
  * Function: _Vendor.GetLeadTime                                              *
  * Description: Returns the approximate lead time based on various factors.   *
  ****************************************************************************]]
function me.GetLeadTime ()
	local Latency = ( select( 3, GetNetStats() ) / 1000 ) / 2; -- One-way latency in seconds
	return Latency + _VendorOptions.ExtraLeadTime;
end


--[[****************************************************************************
  * Function: _Vendor.IsMerchantOpen                                           *
  * Description: Returns true if a merchant window is open.                    *
  ****************************************************************************]]
function me.IsMerchantOpen ()
	return MerchantFrame:IsShown() and UnitExists( "NPC" );
end
--[[****************************************************************************
  * Function: _Vendor.CanAffordItem                                            *
  * Description: Returns true if the player can afford buying the item.        *
  ****************************************************************************]]
do
	local GetItemCount = GetItemCount;
	local pairs = pairs;
	function me.CanAffordItem ( Name, Quantity )
		if ( _VendorOptions.PriceCheck ) then
			-- Total up other expected costs
			local TotalMoney, TotalHonorPoints, TotalArenaPoints, TokenTotals = 0, 0, 0, {};
			local Info;
			for ItemName, ItemQuantity in pairs( Items ) do
				if ( Name ~= ItemName ) then
					Info = ItemInfo[ ItemName ];
					if ( Info.Money ) then
						TotalMoney = TotalMoney + Info.Money * ItemQuantity;
					end
					if ( Info.HonorPoints ) then
						TotalHonorPoints = TotalHonorPoints + Info.HonorPoints * ItemQuantity;
					end
					if ( Info.ArenaPoints ) then
						TotalArenaPoints = TotalArenaPoints + Info.ArenaPoints * ItemQuantity;
					end
					if ( Info.Tokens ) then
						for TokenID, TokenCount in pairs( Info.Tokens ) do
							TokenTotals[ TokenID ] = ( TokenTotals[ TokenID ] or 0 ) + TokenCount * ItemQuantity;
						end
					end
				end
			end

			-- Add cost of new item and compare
			Info = ItemInfo[ Name ];
			if ( ( Info.Money and TotalMoney + Info.Money * Quantity > GetMoney() )
				or ( Info.HonorPoints and TotalHonorPoints + Info.HonorPoints * Quantity > GetHonorCurrency() )
				or ( Info.ArenaPoints and TotalArenaPoints + Info.ArenaPoints * Quantity > GetArenaCurrency() )
			) then
				return;
			end
			if ( Info.Tokens ) then
				for TokenID, TokenCount in pairs( Info.Tokens ) do
					if ( ( TokenTotals[ TokenID ] or 0 ) + TokenCount * Quantity > GetItemCount( TokenID ) ) then
						return;
					end
				end
			end
			return true;
		
		else -- No validation
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Vendor.CacheItemInfo                                            *
  * Description: Saves cost info about an item to the cache.                   *
  ****************************************************************************]]
do
	local GetMerchantItemInfo = GetMerchantItemInfo;
	local GetMerchantItemCostItem = GetMerchantItemCostItem;
	local select = select;
	local tonumber = tonumber;
	function me.CacheItemInfo ( Index )
		local Name, _, Money, Quantity, _, _, ExtendedCost = GetMerchantItemInfo( Index );
		if ( not Name ) then -- Unknown item
			me.Error( L.ERROR_ITEM_NOT_CACHED );
			return;
		elseif ( not ExtendedCost ) then -- Item can't be scammed
			me.Error( L.ERROR_ITEM_NOT_SCAMMABLE );
			return;
		end

		local HonorPoints, ArenaPoints, TokenTypeCount = GetMerchantItemCostInfo( Index );
		if ( Money == 0 ) then
			Money = nil;
		end
		if ( HonorPoints == 0 ) then
			HonorPoints = nil;
		end
		if ( ArenaPoints == 0 ) then
			ArenaPoints = nil;
		end

		local Tokens;
		if ( TokenTypeCount > 0 ) then
			local Link;
			Tokens = {};
			for TokenIndex = 1, TokenTypeCount do
				me.Tooltip:ClearLines();
				me.Tooltip:SetMerchantCostItem( Index, TokenIndex );

				Tokens[ tonumber( select( 3, select( 2, me.Tooltip:GetItem() ):find( "|Hitem:([0-9]+):" ) ) ) ]
					= select( 2, GetMerchantItemCostItem( Index, TokenIndex ) );
			end
		end

		ItemInfo[ Name:upper() ] = {
			Money = Money;
			HonorPoints = HonorPoints;
			ArenaPoints = ArenaPoints;
			Tokens = Tokens;
			StackSize = select( 8, GetItemInfo( GetMerchantItemLink( Index ) ) ) / Quantity;
		};
		return true;
	end
end


--[[****************************************************************************
  * Function: _Vendor.Add                                                      *
  * Description: Adds an item to the queue of things to buy.                   *
  ****************************************************************************]]
function me.Add ( Name, Quantity )
	if ( not Quantity ) then
		Quantity = 1;
	elseif ( Quantity <= 0 ) then
		me.Error( L.ERROR_BAD_QUANTITY );
		return;
	end
	Name = Name:upper();

	if ( ItemInfo[ Name ] ) then -- Recognized item
		if ( me.CanAffordItem( Name, Quantity ) ) then
			Items[ Name ] = Quantity;
			return true;
		else
			me.Error( L.ERROR_ITEM_TOO_EXPENSIVE );
		end

	elseif ( Name ~= "" and me.IsMerchantOpen() ) then
		-- Search vendor for given item
		local Found = false;
		for Index = 1, GetMerchantNumItems() do
			if ( Name == ( GetMerchantItemInfo( Index ) or "" ):upper() ) then -- Found
				Found = true;

				if ( me.CacheItemInfo( Index ) ) then -- Scammable
					if ( me.CanAffordItem( Name, Quantity ) ) then
						Items[ Name ] = Quantity;
						return true;
					else
						me.Error( L.ERROR_ITEM_TOO_EXPENSIVE );
					end
				end
				break;
			end
		end

		if ( not Found ) then
			me.Error( L.ERROR_ITEM_NOT_FOUND );
		end

	else -- Cannot search for item's info
		me.Error( L.ERROR_NO_VENDOR );
	end
end
--[[****************************************************************************
  * Function: _Vendor.RemoveAll                                                *
  * Description: Removes all items from the queue of things to buy.            *
  ****************************************************************************]]
function me.RemoveAll ()
	if ( next( Items ) ) then
		for Name in pairs( Items ) do
			Items[ Name ] = nil;
		end
		return true;
	else
		me.Error( L.ERROR_NO_ITEMS );
	end
end
--[[****************************************************************************
  * Function: _Vendor.Remove                                                   *
  * Description: Removes an item to the queue of things to buy.                *
  ****************************************************************************]]
function me.Remove ( Name )
	Name = Name:upper();
	if ( Items[ Name ] ) then
		Items[ Name ] = nil;
		return true;
	else
		me.Error( L.ERROR_ITEM_NOT_ADDED );
	end
end
--[[****************************************************************************
  * Function: _Vendor.Buy                                                      *
  * Description: Scans the current vendor and buys all given items.            *
  ****************************************************************************]]
do
	local GetMerchantItemInfo = GetMerchantItemInfo;
	local BuyMerchantItem = BuyMerchantItem;
	local min = min;
	function me.Buy ()
		if ( next( Items ) ) then -- At least one
			if ( me.IsMerchantOpen() ) then
				local Name, StackCount;
				for Index = 1, GetMerchantNumItems() do
					Name = ( GetMerchantItemInfo( Index ) or "" ):upper();
					Count = Items[ Name ];

					if ( Count ) then -- Buy at least one
						-- Buy in stacks if possible
						StackCount = ItemInfo[ Name ].StackSize;
						while ( Count > 0 ) do
							BuyMerchantItem( Index, min( Count, StackCount ) );
							Count = Count - StackCount;
						end
						Items[ Name ] = 0; -- Clear without modifying hash table mid-loop
					end
				end

				me.RemoveAll(); -- Clear out zeroed items
			else
				me.Error( L.ERROR_NO_VENDOR );
			end
		end
	end
end




--[[****************************************************************************
  * Function: _Vendor.SlashSubCommands[ L.SLASH_ADD ]                          *
  ****************************************************************************]]
SlashSubCommands[ L.SLASH_ADD ] = function ( Args )
	local Quantity, Name = select( 3, Args:find( L.SLASH_ADD_PATTERN ) );
	if ( not Name ) then
		me.Error( L.ERROR_ADD_SYNTAX_FORMAT:format( Args ) );
	else
		Quantity = Quantity ~= "" and tonumber( Quantity ) or 1;
		if ( me.Add( Name, Quantity ) ) then
			me.Print( L.MESSAGE_ADD_FORMAT:format( Name, Quantity ) );
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Vendor.SlashSubCommands[ L.SLASH_REMOVE ]                       *
  ****************************************************************************]]
SlashSubCommands[ L.SLASH_REMOVE ] = function ( Args )
	if ( Args == "" ) then
		if ( me.RemoveAll() ) then
			me.Print( L.MESSAGE_REMOVEALL );
			return true;
		end

	else
		local Name = select( 3, Args:find( L.SLASH_REMOVE_PATTERN ) );
		if ( not Name ) then
			me.Error( L.ERROR_REMOVE_SYNTAX_FORMAT:format( Args ) );
		elseif ( me.Remove( Name ) ) then
			me.Print( L.MESSAGE_REMOVE_FORMAT:format( Name ) );
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Vendor.SlashSubCommands[ L.SLASH_LIST ]                         *
  ****************************************************************************]]
do
	local CostElements = {}; -- Recycled
	local GetItemIcon = GetItemIcon;
	local tconcat = table.concat;
	local pairs = pairs;
	local tinsert = tinsert;
	SlashSubCommands[ L.SLASH_LIST ] = function ( Args )
		-- Count items to be bought
		local TotalCount = 0;
		for _, Count in pairs( Items ) do
			TotalCount = TotalCount + Count;
		end

		if ( TotalCount == 0 ) then
			me.Print( L.MESSAGE_LIST_NONE );
		else
			me.Print( L.MESSAGE_LIST_FORMAT:format( TotalCount ) );

			-- Print out listing
			local Info;
			for Name, Count in pairs( Items ) do
				-- Form cost string
				Info = ItemInfo[ Name ];
				if ( Info.Money ) then
					tinsert( CostElements, L.SLASH_LISTELEMENT_COST_FORMAT:format( 0, ( "%.02f" ):format( Info.Money * Count / COPPER_PER_GOLD ),
						"Interface\\Icons\\INV_Misc_Coin_01" ) );
				end
				if ( Info.HonorPoints ) then
					tinsert( CostElements, L.SLASH_LISTELEMENT_COST_FORMAT:format( 0, Info.HonorPoints * Count,
						"Interface\\PVPFrame\\PVP-Currency-"..( UnitFactionGroup( "player" ) or "Alliance" ) ) );
				end
				if ( Info.ArenaPoints ) then
					tinsert( CostElements, L.SLASH_LISTELEMENT_COST_FORMAT:format( 0, Info.ArenaPoints * Count,
						"Interface\\PVPFrame\\PVP-ArenaPoints-Icon" ) );
				end
				if ( Info.Tokens ) then
					for TokenID, TokenCount in pairs( Info.Tokens ) do
						tinsert( CostElements, L.SLASH_LISTELEMENT_COST_FORMAT:format( TokenID, TokenCount * Count, GetItemIcon( TokenID ) ) );
					end
				end
				me.Print( L.MESSAGE_LISTELEMENT_FORMAT:format( Name, Count, tconcat( CostElements, L.SLASH_LISTELEMENT_COST_SEPARATOR ) ) );

				for Index in ipairs( CostElements ) do
					CostElements[ Index ] = nil;
				end
			end
		end
		return true;
	end
end
--[[****************************************************************************
  * Function: _Vendor.SlashSubCommands[ L.SLASH_PRICECHECK ]                   *
  ****************************************************************************]]
SlashSubCommands[ L.SLASH_PRICECHECK ] = function ( Args )
	_VendorOptions.PriceCheck = not _VendorOptions.PriceCheck;
	me.Print( _VendorOptions.PriceCheck and L.MESSAGE_PRICECHECK_ON or L.MESSAGE_PRICECHECK_OFF );
	return true;
end
SlashSubCommands[ L.SLASH_PRICECHECK2 ] = SlashSubCommands[ L.SLASH_PRICECHECK ];
--[[****************************************************************************
  * Function: _Vendor.SlashCommand                                             *
  * Description: Slash command chat handler for the _Vendor functions.         *
  ****************************************************************************]]
function me.SlashCommand ( Input )
	local Command, Args = select( 3, Input:trim():find( L.SLASH_PATTERN ) );
	Command = SlashSubCommands[ Command:upper() ];

	if ( Command ) then
		Command( Args );
	else
		-- Print help
		local HelpIndex, HelpText = 0;
		while ( true ) do
			HelpIndex = HelpIndex + 1;
			HelpText = rawget( L, "HELP"..HelpIndex );
			if ( HelpText ) then
				me.Print( HelpText );
			else
				break;
			end
		end
	end
end


--[[****************************************************************************
  * Function: _Vendor.MerchantItemButtonOnModifiedClick                        *
  * Description: Hook for clicking on vendor items.                            *
  ****************************************************************************]]
function me.MerchantItemButtonOnModifiedClick ( ... )
	if ( ... == "LeftButton" and IsAltKeyDown() and IsControlKeyDown() ) then
		local Name = GetMerchantItemInfo( this:GetID() );

		if ( Name ) then
			local Count = Items[ Name:upper() ];
			if ( IsShiftKeyDown() ) then -- Decrement
				Count = ( Count or 1 ) - 1;
				if ( Count >= 1 ) then
					if ( me.Add( Name, Count ) ) then
						me.Print( L.MESSAGE_DECREMENT_FORMAT:format( Name, Count ) );
					end
				elseif ( me.Remove( Name ) ) then
					me.Print( L.MESSAGE_REMOVE_FORMAT:format( Name ) );
				end
			else -- Increment
				Count = ( Count or 0 ) + 1;
				if ( me.Add( Name, Count ) ) then
					me.Print( L[ Count == 1 and "MESSAGE_ADD_FORMAT" or "MESSAGE_INCREMENT_FORMAT" ]:format( Name, Count ) );
				end
			end
		else
			me.Error( L.ERROR_ITEM_NOT_CACHED );
		end

	else
		return me.MerchantItemButtonOnModifiedClickBackup( ... );
	end
end




--[[****************************************************************************
  * Function: _Vendor:OnEvent                                                  *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
function me:OnEvent ( Event, Message )
	if ( Event == "CHAT_MSG_SYSTEM" ) then
		local Time = L.ALERT_TIMES[ select( 3, Message:find( L.SHUTDOWN_PATTERN ) ) or select( 3, Message:find( L.RESTART_PATTERN ) ) ];

		if ( Time ) then
			if ( next( Items ) ) then -- At least one item
				local Start, End = Message:find( SERVER_MESSAGE_PREFIX, 1, true );
				if ( Start ) then
					Message = Message:sub( 1, Start - 1 )..Message:sub( End + 1, -1 );
				end
				me.Error( Message:trim(), NORMAL_FONT_COLOR );
			end

			me.TimeLeft = Time - me.GetLeadTime();
			me:Show();
		end
	end
end
--[[****************************************************************************
  * Function: _Vendor:OnUpdate                                                 *
  * Description: Update handler that counts the final 15 seconds.              *
  ****************************************************************************]]
function me:OnUpdate ( Elapsed )
	me.TimeLeft = me.TimeLeft - Elapsed;

	if ( me.TimeLeft <= me.GetLeadTime() ) then
		me.Buy();
		me:Hide();
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "CHAT_MSG_SYSTEM" );

	me:Hide();

	me.Tooltip:SetOwner( WorldFrame, "ANCHOR_NONE" );
	-- Allow blank template to dynamically add new lines based on these
	me.Tooltip:AddFontStrings(
		me.Tooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
		me.Tooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

	MerchantItemButton_OnModifiedClick = me.MerchantItemButtonOnModifiedClick;
	SlashCmdList[ "VENDOR" ] = me.SlashCommand;
end
