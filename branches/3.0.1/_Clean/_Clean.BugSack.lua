--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BugSack.lua - Modifies the BugSack addon.                           *
  *                                                                            *
  * + Repositions the minimap icon.                                            *
  * + Reskins the error viewer.                                                *
  ****************************************************************************]]


local L;
local _Clean = _Clean;
local me = {};
_Clean.BugSack = me;




--[[****************************************************************************
  * Function: _Clean.BugSack.OnError                                           *
  * Description: Plays a custom error sound.                                   *
  ****************************************************************************]]
-- NOTE(Just add the sound to LibSharedMedia and use a sane hook if it's even needed.)
function me:OnError ( err )
	PlaySoundFile( "Interface\\AddOns\\_Clean\\Skin\\ErrorSound.mp3" );
	local Profile = self.db.profile;

	if ( Profile.auto ) then
		self:ShowFrame( "current" );
	end

	local firstError = nil;
	local num = 0;
	for k, v in pairs( err ) do
		num = num + 1;
		if ( not firstError ) then
			firstError = k;
		end
	end
	if ( Profile.chatframe and Profile.showmsg and num == 1 ) then
		self:Print( self:FormatError( firstError ) );
	elseif ( Profile.chatframe ) then
		if ( num > 1 ) then
			self:Print( L[ "%d errors have been recorded." ]:format( num ) );
		else
			self:Print( L[ "An error has been recorded." ] );
		end
	end

	if ( self:IsEventRegistered( "BugGrabber_BugGrabbed" )
		and BugSackFu and type( BugSackFu.IsActive ) == "function"
		and BugSackFu:IsActive()
	) then
		BugSackFu:UpdateDisplay();
	end
end
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Skins the minimap, or returns false if not found yet.
	local function UpdateMinimapButton ()
		local Frame = BugSackFu.minimapFrame;

		if ( Frame ) then
			Frame:ClearAllPoints();
			Frame:SetPoint( "TOPRIGHT", Minimap );
			Frame:SetWidth( 16 );
			Frame:SetHeight( 16 );
			BugSackFu.minimapIcon:SetAllPoints( Frame );
			_G[ Frame:GetName().."Overlay" ]:Hide();

			local Background = _Clean.Colors.Background;
			local Highlight = _Clean.Colors.Highlight;
			BugSackFu.minimapIcon:SetGradientAlpha( "VERTICAL", Highlight.r, Highlight.g, Highlight.b, Highlight.a, Background.r, Background.g, Background.b, Background.a );

			me.OnTextUpdate();
			Frame.SetPoint = _Clean.NilFunction;

			return true;
		end
	end

	_Clean.RegisterAddOnInitializer( "BugSack", function ()
		if ( not UpdateMinimapButton() ) then
			-- NOTE(Hack to update on first frame. No idea when the minimap button is actually created during loading.)
			CreateFrame( "Frame" ):SetScript( "OnUpdate", function ( self )
				if ( UpdateMinimapButton() ) then
					self:SetScript( "OnUpdate", nil );
				end
			end );
		end

		L = AceLibrary( "AceLocale-2.2" ):new( "BugSack" );
		BugSack.OnError = me.OnError;
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
