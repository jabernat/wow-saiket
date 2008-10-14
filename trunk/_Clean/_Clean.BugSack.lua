--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BugSack.lua - Modifies the BugSack addon.                           *
  *                                                                            *
  * + Repositions the minimap icon.                                            *
  * + Reskins the error viewer.                                                *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.BugSack = me;




--[[****************************************************************************
  * Function: _Clean.BugSack.OnTextUpdate                                      *
  * Description: Keeps the button disabled and transparent when empty.         *
  ****************************************************************************]]
function me.OnTextUpdate ()
	local Frame = BugSackFu.minimapFrame;

	if ( Frame ) then
		if ( #BugSack:GetErrors( "session" ) == 0 ) then -- Clean
			Frame:SetAlpha( 0.75 );
			_Clean.AddLockedButton( Frame );
		else -- Errors
			Frame:SetAlpha( 1.0 );
			_Clean.RemoveLockedButton( Frame );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.BugSack.UpdateMinimapButton                               *
  * Description: Skins the minimap button when it is created.                  *
  ****************************************************************************]]
function me.UpdateMinimapButton ( self )
	local Frame = self.minimapFrame;

	Frame:ClearAllPoints();
	Frame:SetPoint( "TOPRIGHT", Minimap );
	Frame:SetWidth( 16 );
	Frame:SetHeight( 16 );
	self.minimapIcon:SetAllPoints( Frame );
	_G[ Frame:GetName().."Overlay" ]:Hide();

	local Background = _Clean.Colors.Background;
	local Highlight = _Clean.Colors.Highlight;
	self.minimapIcon:SetGradientAlpha( "VERTICAL", Highlight.r, Highlight.g, Highlight.b, Highlight.a, Background.r, Background.g, Background.b, Background.a );

	me.OnTextUpdate();
	Frame.SetPoint = _Clean.NilFunction;
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "BugSack", function ()
		hooksecurefunc( BugSackFu, "Show", me.UpdateMinimapButton );
		hooksecurefunc( BugSackFu, "OnTextUpdate", me.OnTextUpdate );


		-- Reskin error frame
		BugSackFrame:SetMovable( true );
		BugSackFrame:SetUserPlaced( true );
		BugSackFrame:SetClampedToScreen( true );
		BugSackFrame:CreateTitleRegion():SetAllPoints();
		BugSackFrame:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder";
			tile = true; tileSize = 32; edgeSize = 32;
			insets = { left = 7; right = 5; top = 3; bottom = 6; };
		} );
		BugSackFrame:SetBackdropBorderColor( 0.5, 0.5, 0.5 );
		BugSackFrame:EnableMouse( true );

		BugSackFrameScroll:SetPoint( "TOPLEFT", BugSackErrorText, "BOTTOMLEFT", 12, -8 );
		BugSackFrameScroll:SetHeight( 370 );
		BugSackFrameScrollText:SetFontObject( _Clean.MonospaceNumberFont );
		BugSackFrameScrollText:SetFont( BugSackFrameScrollText:GetFont(), 12 );

		-- Reposition buttons
		BugSackFrameButton:Hide();
		local LastButton = CreateFrame( "Button", nil, BugSackFrame, "UIPanelCloseButton" );
		LastButton:SetPoint( "TOPRIGHT", 4, 4 );

		local function InitButton ( Button, Label )
			Button:SetText( Label );
			Button:SetWidth( 24 );
			Button:SetHeight( 18 );
			Button:ClearAllPoints();
			Button:SetPoint( "RIGHT", LastButton, "LEFT", -8, 0 );
			LastButton = Button;
		end
		InitButton( BugSackLastButton, ">>" );
		InitButton( BugSackNextButton, ">" );
		InitButton( BugSackPrevButton, "<" );
		InitButton( BugSackFirstButton, "<<" );
	end );
end
