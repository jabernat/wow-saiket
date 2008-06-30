--[[****************************************************************************
  * _Arena by Saiket                                                           *
  * _Arena.List.lua - Lists found classes in a tooltip frame.                  *
  ****************************************************************************]]


local _Arena = _Arena;
local L = _ArenaLocalization;
local me = CreateFrame( "GameTooltip", "_ArenaList", _Arena );
_Arena.List = me;

me.CountText = me:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmallGray" );

local CountColors = {
	LIGHTYELLOW_FONT_COLOR_CODE,
	"|cffff8833", -- Orange
	RED_FONT_COLOR_CODE
};
me.CountColors = CountColors;




--[[****************************************************************************
  * Function: _Arena.List.Update                                               *
  * Description: Recreates the list display with the current scan results.     *
  ****************************************************************************]]
do
	local SpecList = {};
	local ipairs = ipairs;
	local pairs = pairs;
	local tinsert = tinsert;
	local max = max;
	local min = min;
	local unpack = unpack;
	function me.Update ()
		me:SetOwner( _Arena, "ANCHOR_NONE" );
		me:SetPoint( "BOTTOMLEFT", 8, -8 );
		me:ClearLines();
	
		local Count = 0;
		for Class, ClassData in pairs( _Arena.Scan.Results ) do
			local ActualCount = max( ClassData.Count, ClassData.Wells );
			if ( ActualCount > 0 ) then
				Count = Count + ActualCount;
				for Index in ipairs( SpecList ) do
					SpecList[ Index ] = nil;
				end
				for Spec, Found in pairs( ClassData.Specs ) do
					if ( Found ) then
						tinsert( SpecList, L[ Spec ] );
					end
				end
				local SpecString = ( L.LIST_SPEC_SEPARATOR ):join( unpack( SpecList ) );
				local ClassColor = RAID_CLASS_COLORS[ Class ];
				local CountColor = CountColors[ min( ActualCount, #CountColors ) ];
				if ( #SpecString > 0 ) then
					me:AddDoubleLine(
						L.LIST_CLASS_PATTERN:format( CountColor, ActualCount, L[ Class ] ),
						L.LIST_SPEC_PATTERN:format( SpecString ),
						ClassColor.r, ClassColor.g, ClassColor.b,
						GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b );
				else
					me:AddLine(
						L.LIST_CLASS_PATTERN:format( CountColor, ActualCount, L[ Class ] ),
						ClassColor.r, ClassColor.g, ClassColor.b );
				end
			end
		end
		me:Show();
	
		if ( Count > 0 ) then
			me.CountText:SetFormattedText( L.LIST_COUNT_PATTERN, Count );
			_Arena:SetWidth( max( 128, me:GetWidth() ) );
			_Arena:SetHeight( max( 48, me:GetHeight() + 40 ) );
		else
			me.CountText:SetText();
			_Arena:SetWidth( 128 );
			_Arena:SetHeight( 48 );
		end
	
		_Arena.Buttons.Update();
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Allow blank template to dynamically add new lines based on these
	local Left = me:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" );
	local Right = me:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" );
	me:AddFontStrings( Left, Right );
	Left:SetPoint( "TOPLEFT" );

	-- Setup count text
	me.CountText:SetPoint( "TOPLEFT", _Arena, 8, -4 );
end
