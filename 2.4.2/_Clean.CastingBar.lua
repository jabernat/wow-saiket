--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.CastingBar.lua - Reposition the spell casting progress bar.         *
  *                                                                            *
  * + Removes the casting bar's border and unnecessary highlights and flashes. *
  * + Spans the bar between the left and right action button grids.            *
  * + Allows spell names of any width to be shown in the bar's label.          *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.CastingBar = me;




--[[****************************************************************************
  * Function: _Clean.CastingBar.HideArtwork                                    *
  * Description: This version does not have a border, has no progress spark,   *
  *   and does not flash when done casting.                                    *
  ****************************************************************************]]
local Border = CastingBarFrameBorder;
local Flash = CastingBarFrameFlash;
local Spark = CastingBarFrameSpark;
function me.HideArtwork ()
	Border:Hide();
	Flash:Hide();
	Spark:Hide();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Position the bar between the left and right action bar grids
	CastingBarFrame:ClearAllPoints();
	CastingBarFrame:SetPoint( "TOPRIGHT", MultiBarBottomRight,
		"TOPLEFT", -10, -10 );
	CastingBarFrame:SetPoint( "BOTTOMLEFT", ActionButton12,
		"BOTTOMRIGHT", 10, 10 );

	CastingBarFrameText:ClearAllPoints();
	CastingBarFrameText:SetPoint( "CENTER", CastingBarFrame );
	CastingBarFrameText:SetWidth( 0 ); -- Allow variable width
	CastingBarFrameText:SetFontObject( GameFontHighlightLarge );

	-- Hooks
	UIPARENT_MANAGED_FRAME_POSITIONS[ "CastingBarFrame" ] = nil;
	CastingBarFrame:HookScript( "OnEvent", me.HideArtwork );
	CastingBarFrame:HookScript( "OnUpdate", me.HideArtwork );
end
