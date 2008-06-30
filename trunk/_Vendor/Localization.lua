--[[****************************************************************************
  * _Vendor by Saiket                                                          *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88Vendor|r";
	local Bullet = "    \226\128\162 ";
	local LDQuo, RDQuo = GRAY_FONT_COLOR_CODE.."\226\128\156", "\226\128\157"..FONT_COLOR_CODE_CLOSE;
	local EpicColor = select( 4, GetItemQualityColor( 4 ) );
	local Item      = GRAY_FONT_COLOR_CODE.."[%s]"..FONT_COLOR_CODE_CLOSE; -- [Name]
	local ItemCount = Item.."\195\151%d"; -- [Name]x#

	_VendorLocalization = setmetatable(
		{
			SHUTDOWN_PATTERN = "Shutdown in (.+)$"; -- Ignores SERVER_MESSAGE_PREFIX
			RESTART_PATTERN  =  "Restart in (.+)$"; -- Ignores SERVER_MESSAGE_PREFIX
			ALERT_TIMES = {
				[ "15:00" ] = 60 * 15;
				[ "10:00" ] = 60 * 10;
				[  "5:00" ] = 60 * 5;
				[  "1:00" ] = 60;
				[  "0:15" ] = 15;
			};

			MESSAGE_FORMAT = Title..": %s";
			MESSAGE_ADD_FORMAT = "Added "..ItemCount..".";
			MESSAGE_INCREMENT_FORMAT = "Increased to "..ItemCount..".";
			MESSAGE_DECREMENT_FORMAT = "Reduced to "..ItemCount..".";
			MESSAGE_REMOVEALL = "All items removed.";
			MESSAGE_REMOVE_FORMAT = "Removed "..Item..".";
			MESSAGE_LIST_FORMAT = "Listing - %d |4item:items;:"; -- Total item count
			MESSAGE_LIST_NONE   = "Listing - No items.";
			MESSAGE_LISTELEMENT_FORMAT = Bullet..ItemCount..LIGHTYELLOW_FONT_COLOR_CODE.." (%s)"; -- [Name]x# (Cost)
			MESSAGE_PRICECHECK_ON  = "Price checking "..GREEN_FONT_COLOR_CODE.."enabled"..FONT_COLOR_CODE_CLOSE..".";
			MESSAGE_PRICECHECK_OFF = "Price checking "..RED_FONT_COLOR_CODE.."disabled"..FONT_COLOR_CODE_CLOSE..".";
			MESSAGE_BUY_FORMAT = "Bought "..ItemCount..".";

			ERROR_FORMAT = "%s";
			ERROR_NO_VENDOR = "Vendor window must be open!";
			ERROR_ITEM_NOT_FOUND = "Item not found on this vendor.";
			ERROR_ITEM_NOT_SCAMMABLE = "Item must cost tokens/points.";
			ERROR_ITEM_TOO_EXPENSIVE = "Not enough tokens/points.";
			ERROR_ITEM_NOT_ADDED = "Item not already added.";
			ERROR_NO_ITEMS = "No items to remove.";
			ERROR_BAD_QUANTITY = "Bad quantity of items to buy.";
			ERROR_ADD_SYNTAX_FORMAT = "Could not recognize "..LDQuo.."%s"..RDQuo.." to add."; -- Entire args list
			ERROR_REMOVE_SYNTAX_FORMAT = "Could not recognize "..LDQuo.."%s"..RDQuo.." to remove.";
			ERROR_ITEM_NOT_CACHED = "New item not found in item cache!";

			SLASH_PATTERN = "^(%S*)%s*(.*)$"; -- <Command> <Args>
			SLASH_ADD = "ADD"; -- All uppercase
			SLASH_ADD_PATTERN = "^(%d*).*%[([^]]+)%]"; -- <#> [<ItemName>]
			SLASH_REMOVE = "REMOVE";
			SLASH_REMOVE_PATTERN = "^%[([^]]+)%]"; -- [<ItemName>]
			SLASH_LIST = "LIST";
			SLASH_LISTELEMENT_COST_FORMAT = "|Hitem:%d|h%s |T%s:0|t|h"; -- TokenID, TokenCount, TokenTexture
			SLASH_LISTELEMENT_COST_SEPARATOR = ", ";
			SLASH_PRICECHECK = "PRICECHECK";
			SLASH_PRICECHECK2 = "CHECK";

			HELP1 = "Type "..LDQuo.."/vendor <command>"..RDQuo.." with one of the following <commands>s:";
			HELP2 = Bullet..LDQuo.."/vendor add <#> "..EpicColor.."[Item Link]"..GRAY_FONT_COLOR_CODE..RDQuo
				.." to add the given item link or name in brackets to the buy list.  <#> is optionally the number to buy.";
			HELP3 = Bullet..LDQuo.."/vendor remove "..EpicColor.."[Item Link]"..GRAY_FONT_COLOR_CODE..RDQuo
				.." to remove the given item link or name in brackets from the buy list.";
			HELP4 = Bullet..LDQuo.."/vendor remove"..RDQuo .." to clear the buy list.";
			HELP5 = Bullet..LDQuo.."/vendor list"..RDQuo .." to list items being bought.";
			HELP6 = Bullet..LDQuo.."/vendor check"..RDQuo .." to toggle price checking.";
			HELP7 = Bullet.."Anything else to view this help message.";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );




--------------------------------------------------------------------------------
-- Globals
----------

	SLASH_VENDOR1 = "/vendor";
	SLASH_VENDOR2 = "/vend";
end
