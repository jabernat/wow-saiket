--[[****************************************************************************
  * _Unghost by Saiket                                                         *
  * _Unghost.lua - Timer to release spirit precisely before logging out so     *
  *   your ghost appears at your corpse rather than a graveyard.               *
  ****************************************************************************]]


_UnghostOptions = {
	ExtraLeadTime = 0.015; -- Seconds
};


_Unghost = {
	IsStarted = false;


--[[****************************************************************************
  * Function: _Unghost.Print                                                   *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
Print = function ( Message, ChatFrame, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage(
		format( _UNGHOST_PRINT_FORMAT, tostring( Message ) ),
		Color.r, Color.g, Color.b, Color.id );
end;
--[[****************************************************************************
  * Function: _Unghost.Error                                                   *
  * Description: Show an error in the middle of the screen and play a sound.   *
  ****************************************************************************]]
Error = function ( Message, Color, Duration )
	if ( not Color ) then
		Color = RED_FONT_COLOR;
	end
	UIErrorsFrame:AddMessage( tostring( Message ),
		Color.r, Color.g, Color.b, 1, Duration or UIERRORS_HOLD_TIME );
	PlaySound( "igQuestFailed" );
end;


--[[****************************************************************************
  * Function: _Unghost.Start                                                   *
  * Description: Begins the unghost procedure.                                 *
  ****************************************************************************]]
Start = function ()
	if ( not StaticPopup_Visible( "DEATH" ) ) then
		_Unghost.Error( _UNGHOST_ERROR_NOTCORPSE );
	elseif ( IsResting() ) then
		_Unghost.Error( _UNGHOST_ERROR_RESTING );
	elseif ( not _Unghost.IsStarted ) then
		-- Unparent the popups so they aren't removed when the interface is hidden
		-- The re-parent inadvertently hides the popups
		for Index = 1, STATICPOPUP_NUMDIALOGS do
			-- Stop OnHides from firing
			local Popup = getglobal( "StaticPopup"..Index );
			local PopupData = StaticPopupDialogs[ Popup.which ];
			if ( PopupData ) then
				local OnShow = PopupData.OnShow;
				local OnHide = PopupData.OnHide;
				PopupData.OnShow = nil;
				PopupData.OnHide = nil;
			end
			Popup:SetParent( nil );
			if ( PopupData ) then
				PopupData.OnShow = OnShow;
				PopupData.OnHide = OnHide;
			end
		end

		-- Hide interface for higher FPS
		WorldFrame:Hide();
		UIParent:Hide();

		_UnghostButtonFrame:SetChecked( 1 );
		_Unghost.IsStarted = true;
		Logout();
	end
end;
--[[****************************************************************************
  * Function: _Unghost.Stop                                                    *
  * Description: Ends the unghost procedure.                                   *
  ****************************************************************************]]
Stop = function ()
	if ( _Unghost.IsStarted ) then
		-- Unhide interface
		UIParent:Show();
		WorldFrame:Show();
		-- Restore original parenting
		for Index = 1, STATICPOPUP_NUMDIALOGS do
			getglobal( "StaticPopup"..Index ):SetParent( UIParent );
		end

		_Unghost.IsStarted = false;
		_Unghost.Timer.Stop();
		_UnghostButtonFrame:SetChecked( 0 );
		CancelLogout();
		StaticPopup_Hide( "CAMP" );
	end
end;
--[[****************************************************************************
  * Function: _Unghost.Toggle                                                  *
  * Description: Toggles start and stop for the unghost countdown. Returns     *
  *   true if started and false if disabled.                                   *
  ****************************************************************************]]
Toggle = function ()
	if ( _Unghost.IsStarted ) then
		if ( _UnghostTimerFrame:IsVisible() ) then
			_Unghost.Stop();
			return false;
		end
	else
		_Unghost.Start();
		return true;
	end
end;
--[[****************************************************************************
  * Function: _Unghost.SlashCommand                                            *
  * Description: Handles chat slash commands.                                  *
  ****************************************************************************]]
SlashCommand = function ( Input )
	Input = string.lower( string.trim( Input ) );
	if ( string.len( Input ) == 0 ) then
		_Unghost.Print( _Unghost.Toggle() and _UNGHOST_STARTED or _UNGHOST_STOPPED );
	elseif ( Input == _UNGHOST_OPT_LEAD ) then
		-- Formatted in milliseconds
		_Unghost.Print( string.format( _UNGHOST_LEAD,
			_UnghostOptions.ExtraLeadTime * 1000 ) );
	else
		local HelpIndex, HelpText = 0;
		while true do
			HelpIndex = HelpIndex + 1;
			HelpText = getglobal( "_UNGHOST_HELP"..HelpIndex );
			if ( HelpText ) then
				_Unghost.Print( HelpText );
			else
				break;
			end
		end
	end
end;


--[[****************************************************************************
  * Function: _Unghost.GetLeadTime                                             *
  * Description: Returns the approximate lead time based on various factors.   *
  ****************************************************************************]]
GetLeadTime = function ()
	local Latency = select( 3, GetNetStats() ) / 1000; -- In seconds
	local FrameDelay = 0; --1 / GetFramerate() / 2; -- In seconds; Halved for statistical probability
	return Latency + FrameDelay + _UnghostOptions.ExtraLeadTime;
end;


--[[****************************************************************************
  * Function: _Unghost.OnEvent                                                 *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
OnEvent = function ()
	if ( event == "PLAYER_CAMPING" and _Unghost.IsStarted ) then
		_Unghost.Timer.Start();
	end
end;
--[[****************************************************************************
  * Function: _Unghost.OnLoad                                                  *
  * Description: Global OnLoad handler.                                        *
  ****************************************************************************]]
OnLoad = function ()
	_UnghostFrame:RegisterEvent( "PLAYER_CAMPING" );

	-- Hook CancelLogout; the LOGOUT_CANCEL event does not work
	hooksecurefunc( "CancelLogout", _Unghost.Stop );
end;




--------------------------------------------------------------------------------
-- _Unghost.Button
------------------

	Button = {

--[[****************************************************************************
  * Function: _Unghost.Button.Show                                             *
  * Description: Shows the unghost button with the release spirit popup.       *
  ****************************************************************************]]
Show = function ()
	local Popup = getglobal( StaticPopup_Visible( "DEATH" ) );
	_UnghostButtonFrame:SetParent( Popup );
	_UnghostButtonFrame:SetPoint( "BOTTOMLEFT", Popup, "BOTTOMLEFT", 14, 14 );
	_UnghostButtonFrame:Show();
end;
--[[****************************************************************************
  * Function: _Unghost.Button.Hide                                             *
  * Description: Hides the unghost button with the release spirit popup.       *
  ****************************************************************************]]
Hide = function ()
	_UnghostButtonFrame:Hide();
	_Unghost.Stop();
end;

--[[****************************************************************************
  * Function: _Unghost.Button.OnEnter                                          *
  * Description: Shows the button's tooltip.                                   *
  ****************************************************************************]]
OnEnter = function ()
	GameTooltip:SetOwner( this, "ANCHOR_BOTTOMRIGHT" );
	GameTooltip:ClearLines();
	GameTooltip:SetText( _UNGHOST_UNGHOST );
	GameTooltip:AddLine( _UNGHOST_TOOLTIP,
		HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1 );
	GameTooltip:Show();
end;
--[[****************************************************************************
  * Function: _Unghost.Button.OnLeave                                          *
  * Description: Hides the button's tooltip.                                   *
  ****************************************************************************]]
OnLeave = function ()
	GameTooltip:Hide();
end;
--[[****************************************************************************
  * Function: _Unghost.Button.OnClick                                          *
  * Description: Starts and stops the unghost on click.                        *
  ****************************************************************************]]
OnClick = function ()
	_Unghost.Toggle();
end;
--[[****************************************************************************
  * Function: _Unghost.Button.OnUpdate                                         *
  * Description: Button OnUpdate handler. Reds out the button in town and      *
  *   updates the cooldown model.                                              *
  ****************************************************************************]]
OnUpdate = function ()
	local Color = IsResting() and RED_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
	local Name = this:GetName();

	local Max = StaticPopupDialogs[ "CAMP" ].timeout;
	CooldownFrame_SetTimer( getglobal( Name.."Cooldown" ),
		GetTime() - ( Max - math.max( _Unghost.Timer.LogoutTimeLeft or 0, 0 ) ),
		Max, 1 );

	getglobal( Name.."Icon" ):SetVertexColor( Color.r, Color.g, Color.b );
end;
--[[****************************************************************************
  * Function: _Unghost.Button.OnLoad                                           *
  * Description: Button OnLoad handler.                                        *
  ****************************************************************************]]
OnLoad = function ()
	local Name = this:GetName();
	this:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2");
	getglobal( Name.."Icon" ):SetTexture( "Interface\\Icons\\Ability_Vanish" );

	-- Hook the death popup's show and hide events
	hooksecurefunc( StaticPopupDialogs[ "DEATH" ], "OnShow", _Unghost.Button.Show );
	StaticPopupDialogs[ "DEATH" ].OnHide = _Unghost.Button.Hide;
end;

	}; -- End _Button




--------------------------------------------------------------------------------
-- _Unghost.Timer
-----------------

	Timer = {
		LogoutTimeLeft;

--[[****************************************************************************
  * Function: _Unghost.Timer.Start                                             *
  * Description: Resets and restarts the logout timer. Should be called only   *
  *   when the PLAYER_CAMPING event is received.                               *
  ****************************************************************************]]
Start = function ()
	_Unghost.Timer.LogoutTimeLeft = StaticPopupDialogs[ "CAMP" ].timeout;
	_UnghostTimerFrame:Show();
end;
--[[****************************************************************************
  * Function: _Unghost.Timer.Stop                                              *
  * Description: Stops the logout timer and aborts the unghost.                *
  ****************************************************************************]]
Stop = function ()
	_Unghost.Timer.LogoutTimeLeft = nil;
	_UnghostTimerFrame:Hide();
end;
--[[****************************************************************************
  * Function: _Unghost.Timer.OnUpdate                                          *
  * Description: Monitors the logoff timer.                                    *
  ****************************************************************************]]
OnUpdate = function ()
	_Unghost.Timer.LogoutTimeLeft = _Unghost.Timer.LogoutTimeLeft - arg1;

	if ( _Unghost.Timer.LogoutTimeLeft <= _Unghost.GetLeadTime() ) then
		RepopMe();
		this:Hide();
	end
end;

	}; -- End Timer


}; -- End _Unghost




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

SlashCmdList[ "UNGHOST" ] = _Unghost.SlashCommand;
