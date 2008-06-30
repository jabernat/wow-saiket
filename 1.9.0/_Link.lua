--[[****************************************************************************
  * _Link by Saiket                                                            *
  *                                                                            *
  * _Link.lua - Common functions.                                              *
  ****************************************************************************]]


_Link = {
	Enchants = {};
	Subtypes = {};

	SampleItemID = 3577; -- Do all testing with "[Gold Bar]"
	MaxEnchantID = 8192;
	MaxSubtypeID = 8192;

	SetItemRefBackup = SetItemRef;
	PickupContainerItemBackup = PickupContainerItem;
	PickupInventoryItemBackup = PickupInventoryItem;


--[[****************************************************************************
  * Function: _Link.NilFunction                                                *
  * Description: Recycled generic function placeholder.                        *
  ****************************************************************************]]
NilFunction = function () end;
--[[****************************************************************************
  * Function: _Link.Print                                                      *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
Print = function ( Message, ChatFrame, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( Message, Color.r, Color.g, Color.b, Color.id );
end;


--[[****************************************************************************
  * Function: _Link.GetTooltipStatsString                                      *
  * Description: Return a string representing the item tooltip's stats or nil  *
  *   if there are none.                                                       *
  ****************************************************************************]]
GetTooltipStatsString = function ( Tooltip )
	local LineCount = Tooltip:NumLines();
	if ( LineCount > 1 ) then -- At least one stat was added
		local Stats = getglobal( Tooltip:GetName().."TextLeft2" ):GetText();
		for Line = 3, LineCount do
			Stats = Stats.."\n"..getglobal( Tooltip:GetName().."TextLeft"..Line ):GetText();
		end
		return Stats;
	end
end;
--[[****************************************************************************
  * Function: _Link.ScanEnchants                                               *
  * Description: Scan each enchant ID to find possible enhancements. This      *
  *   operation may lock the screen up for a bit while processing.             *
  ****************************************************************************]]
ScanEnchants = function ()
	if ( not GetItemInfo( _Link.SampleItemID ) ) then
		return;
	end
	_LinkEnchants = {};
	RegisterForSave( "_LinkEnchants" );

	for EnchantID = 0, _Link.MaxEnchantID do
		_LinkFrameTooltip:SetHyperlink( string.format( "item:%d:%d:0:0", _Link.SampleItemID, EnchantID ) );
		_LinkEnchants[ EnchantID ] = _Link.GetTooltipStatsString( _LinkFrameTooltip );
	end
	_LinkFrameTooltip:Hide();
end;
--[[****************************************************************************
  * Function: _Link.ScanSubtypes                                               *
  * Description: Scan each subtype ID to find possible enhancements. This      *
  *   operation may lock the screen up for a bit while processing.             *
  ****************************************************************************]]
ScanSubtypes = function ()
	local Name = GetItemInfo( _Link.SampleItemID );
	if ( not Name ) then
		return;
	end
	_LinkSubtypes = {};
	RegisterForSave( "_LinkSubtypes" );

	for SubtypeID = 0, _Link.MaxSubtypeID do
		_LinkFrameTooltip:SetHyperlink( string.format( "item:%d:0:%d:0", _Link.SampleItemID, SubtypeID ) );
		local Stats = _Link.GetTooltipStatsString( _LinkFrameTooltip );

		local FullName = _LinkFrameTooltipTextLeft1:GetText();
		local Start, End = string.find( FullName, Name, 1, true );
		local Pre, Post = string.sub( FullName, 1, Start - 1 ), string.sub( FullName, End + 1, -1 );
		if ( string.len( Pre ) == 0 ) then
			Pre = nil;
		end
		if ( string.len( Post ) == 0 ) then
			Post = nil;
		end

		if ( Stats or Pre or Post ) then
			_LinkSubtypes[ SubtypeID ] = {
				Stats = Stats;
				Pre = Pre;
				Post = Post;
			};
		end
	end
	_LinkFrameTooltip:Hide();
end;


--[[****************************************************************************
  * Function: _Link.GetLinkParts                                               *
  * Description: TODO()                                                        *
  ****************************************************************************]]
GetLinkParts = function ( FullLink )
	local Name, _, Link, ID, Name = string.find( FullLink, "^|c%x+|H(item:(%d+):[%d:]+)|h%[([^%]]*)%]|h|r$" );
	if ( not Name ) then
		return;
	end

	local RealName = GetItemInfo( ID + 0 ) or Name;

	local Start, End = string.find( Name, RealName, 1, true );
	if ( Start ) then
		return Link, RealName, string.sub( Name, 1, Start - 1 ), string.sub( Name, End + 1, -1 );
	end
end;


--[[****************************************************************************
  * Function: _Link.SetItemRef                                                 *
  * Description: TODO()                                                        *
  ****************************************************************************]]
SetItemRef = function ( ... )
	if ( _LinkFrame:IsVisible() and string.sub( arg[ 1 ], 1, 4 ) == "item" and IsAltKeyDown() ) then
		local Link, _, Pre, Post = _Link.GetLinkParts( arg[ 2 ] );
		_Link.Item.SetLink( _LinkFrame, Link );
		_LinkFrameTagPre:SetText( Pre );
		_LinkFrameTagPost:SetText( Post );
	else
		_Link.SetItemRefBackup( unpack( arg ) );
	end
end;
--[[****************************************************************************
  * Function: _Link.PickupContainerItem                                        *
  * Description: TODO()                                                        *
  ****************************************************************************]]
PickupContainerItem = function ( ... )
	if ( _LinkFrame:IsVisible() and IsAltKeyDown() ) then
		_Link.Item.SetLink( _LinkFrame, _Link.GetLinkParts( GetContainerItemLink( arg[ 1 ], arg[ 2 ] ) ) );
	else
		_Link.PickupContainerItemBackup( unpack( arg ) );
	end
end;
--[[****************************************************************************
  * Function: _Link.PickupInventoryItem                                        *
  * Description: TODO()                                                        *
  ****************************************************************************]]
PickupInventoryItem = function ( ... )
	if ( _LinkFrame:IsVisible() and IsAltKeyDown() ) then
		_Link.Item.SetLink( _LinkFrame, _Link.GetLinkParts( GetInventoryItemLink( "player", arg[ 1 ] ) ) );
	else
		_Link.PickupInventoryItemBackup( unpack( arg ) );
	end
end;


--[[****************************************************************************
  * Function: _Link.Toggle                                                     *
  * Description: TODO()                                                        *
  ****************************************************************************]]
Toggle = function ( Show )
	if ( Show == nil ) then
		Show = not _LinkFrame:IsVisible();
	end

	if ( Show ) then
		_LinkFrame:Show();
	else
		_LinkFrame:Hide();
	end
end;




--------------------------------------------------------------------------------
-- _Link.Preview
----------------

	Preview = {
		Text;

--[[****************************************************************************
  * Function: _Link.Preview.Update                                             *
  * Description: TODO()                                                        *
  ****************************************************************************]]
Update = function ( Frame )
	local FrameName = Frame:GetName();
	local Link = _Link.Item.GetLink( Frame );
	local Name, _, Rarity = GetItemInfo( ( { string.find( Link, "^item:(%d+):" ) } )[ 3 ] + 0 );

	if ( Name ) then
		_Link.Preview.Text = string.format( "%s|H%s|h[%s%s%s]|h"..FONT_COLOR_CODE_CLOSE,
			ITEM_QUALITY_COLORS[ Rarity ].hex,
			Link,
			getglobal( FrameName.."TagPre" ):GetText(),
			Name,
			getglobal( FrameName.."TagPost" ):GetText() );
	else
		_Link.Preview.Text = nil;
	end

	getglobal( FrameName.."Preview" ):AddMessage( _Link.Preview.Text or " " );
end;

--[[****************************************************************************
  * Function: _Link.Preview.OnHyperlinkClick                                   *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnHyperlinkClick = function ()
	SetItemRef( arg1, arg2, arg3 );
end;

	}; -- End _Link.Preview


--------------------------------------------------------------------------------
-- _Link.EditBox
----------------

	EditBox = {

--[[****************************************************************************
  * Function: _Link.EditBox.OnEscapePressed                                    *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnEscapePressed = function ()
	this:ClearFocus();
end;

	}; -- End _Link.EditBox


--------------------------------------------------------------------------------
-- _Link.Item
-------------

	Item = {

--[[****************************************************************************
  * Function: _Link.Item.GetLink                                               *
  * Description: TODO()                                                        *
  ****************************************************************************]]
GetLink = function ( Frame )
	local NamePrefix = Frame:GetName().."ItemPart";
	local Link = "item";

	for Part = 1, 4 do
		Link = Link..":"..getglobal( NamePrefix..Part ):GetNumber();
	end
	return Link;
end;
--[[****************************************************************************
  * Function: _Link.Item.SetLink                                               *
  * Description: TODO()                                                        *
  ****************************************************************************]]
SetLink = function ( Frame, Link )
	local NamePrefix = Frame:GetName().."ItemPart";
	local Parts = { string.find( Link, "^item:(%d+):(%d+):(%d+):(%d+)$" ) };
	if ( table.getn( Parts ) == 0 ) then
		-- Invalid link; default to no item
		Parts = { 0, 0, 0, 0, 0, 0 };
	end

	-- Temporarily disable auto-updating
	_Link.Item.OnTextChangedBackup = _Link.Item.OnTextChanged;
	_Link.Item.OnTextChanged = _Link.NilFunction;
	for Part = 1, 4 do
		getglobal( NamePrefix..Part ):SetNumber( Parts[ Part + 2 ] );
	end
	_Link.Item.OnTextChanged = _Link.Item.OnTextChangedBackup;

	_Link.Item.Validate( Frame );
	_Link.Preview.Update( Frame );
end;
--[[****************************************************************************
  * Function: _Link.Item.SetPartValid                                          *
  * Description: TODO()                                                        *
  ****************************************************************************]]
SetPartValid = function ( Part, Valid )
	local Color = Valid and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR;
	Part:SetTextColor( Color.r, Color.g, Color.b );
end;
--[[****************************************************************************
  * Function: _Link.Item.Validate                                              *
  * Description: TODO()                                                        *
  ****************************************************************************]]
Validate = function ( Frame )
	local Color = HIGHLIGHT_FONT_COLOR;
	if ( not GetItemInfo( _Link.Item.GetLink( Frame ) ) ) then
		Color = RED_FONT_COLOR;
	end
	getglobal( Frame:GetName().."ItemPart1" ):SetTextColor( Color.r, Color.g, Color.b );
end;

--[[****************************************************************************
  * Function: _Link.Item.OnTextChanged                                         *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnTextChanged = function ()
	local Frame = this:GetParent();

	this:SetNumber( this:GetNumber() );
	_Link.Item.Validate( Frame );
	_Link.Preview.Update( Frame );

	local Tooltip = getglobal( Frame:GetName().."Tooltip" );
	local Link = _Link.Item.GetLink( Frame );
	if ( GetItemInfo( Link ) ) then
		Tooltip:SetOwner( Frame, "ANCHOR_TOPLEFT", 2, -8 );
		Tooltip:SetHyperlink( Link );
	else
		Tooltip:Hide();
	end
end;

	}; -- End _Link.Item


--------------------------------------------------------------------------------
-- _Link.Tag
------------

	Tag = {

--[[****************************************************************************
  * Function: _Link.Tag.OnTextChanged                                          *
  * Description: TODO()                                                        *
  ****************************************************************************]]
OnTextChanged = function ()
	this:SetText( string.gsub( this:GetText(), "[%[%]]", "" ) )
	_Link.Preview.Update( this:GetParent() );
end;

	}; -- End _Link.Tag

}; -- End _Link




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

SetItemRef = _Link.SetItemRef;
PickupContainerItem = _Link.PickupContainerItem;
PickupInventoryItem = _Link.PickupInventoryItem;
