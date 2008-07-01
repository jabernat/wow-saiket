--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.BugSack.lua - Modifies the BugSack addon.                           *
  *                                                                            *
  * + Repositions the minimap icon.                                            *
  ****************************************************************************]]


local L;
local _Clean = _Clean;
local me = {};
_Clean.BugSack = me;




--[[****************************************************************************
  * Function: _Clean.BugSack.OnError                                           *
  * Description: Plays a custom error sound.                                   *
  ****************************************************************************]]
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
			Frame:SetAlpha( 0.5 );
			_Clean.AddLockedButton( Frame );
		else -- Errors
			Frame:SetAlpha( 1.0 );
			_Clean.RemoveLockedButton( Frame );
		end
	end
end


--[[****************************************************************************
  * Function: _Clean.BugSack.UpdateMinimapButton                               *
  * Description: Skins the minimap icon.                                       *
  ****************************************************************************]]
function me.UpdateMinimapButton ()
	local Frame = BugSackFu.minimapFrame;

	if ( Frame ) then
		_Clean.ClearAllPoints( Frame );
		_Clean.SetPoint( Frame, "TOPRIGHT", Minimap );
		_Clean.RunProtectedMethod( Frame, "SetWidth", 16 );
		_Clean.RunProtectedMethod( Frame, "SetHeight", 16 );
		_Clean.SetAllPoints( BugSackFu.minimapIcon, Frame );
		_Clean.RunProtectedMethod( _G[ Frame:GetName().."Overlay" ], "Hide" );

		me.OnTextUpdate();
		Frame.SetPoint = _Clean.NilFunction;

		return true;
	end
end


--[[****************************************************************************
  * Function: _Clean.BugSack.OnLoad                                            *
  * Description: Makes modifications just after the addon is loaded.           *
  ****************************************************************************]]
function me.OnLoad ()
	if ( not me.UpdateMinimapButton() ) then
		-- NOTE(Hack to update on first frame. No idea when the minimap button is actually created during loading.)
		CreateFrame( "Frame" ):SetScript( "OnUpdate",
			function ( self )
				if ( me.UpdateMinimapButton() ) then
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
	_Clean.RunProtectedMethod( BugSackFrame, "EnableMouse", true );

	_Clean.SetPoint( BugSackFrameScroll, "TOPLEFT", BugSackErrorText, "BOTTOMLEFT", 12, -8 );
	_Clean.RunProtectedMethod( BugSackFrameScroll, "SetHeight", 370 );
	BugSackFrameScrollText:SetFontObject( _Clean.MonospaceNumberFont );
	BugSackFrameScrollText:SetFont( BugSackFrameScrollText:GetFont(), 12 );

	-- Reposition buttons
	_Clean.RunProtectedMethod( BugSackFrameButton, "Hide" );
	local LastButton =
		CreateFrame( "Button", nil, BugSackFrame, "UIPanelCloseButton" );
	LastButton:SetPoint( "TOPRIGHT", 4, 4 );

	local function InitButton ( Button, Label )
		Button:SetText( Label );
		_Clean.RunProtectedMethod( Button, "SetWidth", 24 );
		_Clean.RunProtectedMethod( Button, "SetHeight", 18 );
		_Clean.ClearAllPoints( Button );
		_Clean.SetPoint( Button, "RIGHT", LastButton, "LEFT", -8, 0 );
		LastButton = Button;
	end
	InitButton( BugSackLastButton, ">>" );
	InitButton( BugSackNextButton, ">" );
	InitButton( BugSackPrevButton, "<" );
	InitButton( BugSackFirstButton, "<<" );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	_Clean.RegisterAddOnInitializer( "BugSack", me.OnLoad );
end
