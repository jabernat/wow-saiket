--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.BlizzardAuctionUI.lua - Modifies the Blizzard_AuctionUI addon.       *
  *                                                                            *
  * + When the auction frame is open, <Alt+Click> on items will seach for      *
  *   them.                                                                    *
  * + The default auction length is set to 24 hours.                           *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {};
_Misc.BlizzardAuctionUI = me;




--[[****************************************************************************
  * Function: _Misc.BlizzardAuctionUI.SearchFromLink                           *
  * Description: Searches the AH for the item referenced in the given link,    *
  *   and return true if a search was initiated.                               *
  ****************************************************************************]]
function me.SearchFromLink ( Item )
	if ( Item and AuctionFrameBrowse:IsVisible() ) then
		-- Search the item link for its name
		Item = Item:match( "%[(.*)%]" );

		if ( Item ) then
			BrowseName:SetText( Item );
			BrowseName:SetFocus();
			BrowseName:HighlightText();

			AuctionFrameBrowse_Search();
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.BlizzardAuctionUI.SetItemRef                               *
  * Description: Adds and searches for alt+clicked items.                      *
  ****************************************************************************]]
function me.SetItemRef ( Link, Text, Button, ... )
	if ( not (
		IsModifiedClick( "_MISC_AUCTION_QUERY" )
		and Link:sub( 1, 4 ) == "item"
		and me.SearchFromLink( Text )
	) ) then
		return me.SetItemRefBackup( Link, Text, Button, ... );
	end
end
--[[****************************************************************************
  * Function: _Misc.BlizzardAuctionUI.ContainerFrameItemButtonOnModifiedClick  *
  * Description: Adds and searches for alt+clicked items.                      *
  ****************************************************************************]]
function me.ContainerFrameItemButtonOnModifiedClick ( Button )
	if ( IsModifiedClick( "_MISC_AUCTION_QUERY" ) ) then
		if ( AuctionFrameBrowse:IsVisible() ) then
			me.SearchFromLink( GetContainerItemLink( this:GetParent():GetID(), this:GetID() ) );
		elseif ( AuctionFrameAuctions:IsVisible() and not CursorHasItem() ) then
			PickupContainerItem( this:GetParent():GetID(), this:GetID() );
			ClickAuctionSellItemButton();
			ClearCursor();
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Misc.RegisterAddOnInitializer( "Blizzard_AuctionUI", function ()
		me.SetItemRefBackup = SetItemRef;
		SetItemRef = me.SetItemRef;
	
		hooksecurefunc( "ChatEdit_InsertLink", me.SearchFromLink );
		hooksecurefunc( "ContainerFrameItemButton_OnModifiedClick", me.ContainerFrameItemButtonOnModifiedClick );
	
		-- Set the default aution length to long
		AuctionsRadioButton_OnClick( AuctionsLongAuctionButton );
	end );
end
