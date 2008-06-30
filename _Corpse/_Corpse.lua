--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.lua - Shows information about moused-over corpses.                 *
  ****************************************************************************]]


local L = _CorpseLocalization;
local me = CreateFrame( "Frame", "_Corpse" );

local ShowHookFrame = CreateFrame( "Frame" );
me.ShowHookFrame = ShowHookFrame;

local Enemies = {}; -- Name-indexed hash of connection status
	                  -- Values: false = Unknown, 0 = Offline, 1 = Online
me.Enemies = Enemies;

me.Enabled = false;

me.AddFriendLast = nil; -- Saved in case added friend is hostile(ambiguous case)
me.RemoveFriendLast = nil; -- Saved so system message can be hidden
me.InviteUnitLast = nil; -- Saved in case invited enemy is online(ambiguous case)
-- Following used when friends list is full
me.RemoveFriendSwapLast = nil;
me.AddFriendSwapLast = nil;

me.UIErrorsFrameOnEventBackup = UIErrorsFrame_OnEvent;
me.ChatFrameMessageEventHandlerBackup = ChatFrame_MessageEventHandler;


-- Commonly used functions
local select = select;




--[[****************************************************************************
  * Function: _Corpse.GetFriendIndex                                           *
  * Description: Gets friend index of a given player, or nil if not a friend.  *
  ****************************************************************************]]
do
	local GetNumFriends = GetNumFriends;
	local GetFriendInfo = GetFriendInfo;
	function me.GetFriendIndex ( Name )
		for Index = 1, GetNumFriends() do
			if ( GetFriendInfo( Index ) == Name ) then
				return Index;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.GetCorpseName                                            *
  * Description: Gets the name from a corpse's tooltip, or nil of no corpse.   *
  ****************************************************************************]]
function me.GetCorpseName ()
	if ( GameTooltip:IsVisible() and GameTooltip:NumLines() <= 2 ) then
		local Text = GameTooltipTextLeft1:GetText();
		if ( Text ) then
			Text = select( 3, Text:find( L.CORPSE_PATTERN ) );
			if ( Text ) then
				return L.SERVER_DELIMITER:split( Text );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.BuildCorpseTooltip                                       *
  * Description: Adds info from friends list to the current corpse tooltip.    *
  *   Adds info to fontstrings directly; avoids using ClearLines to keep other *
  *   tooltip addons from thinking the tooltip is being reset.                 *
  ****************************************************************************]]
function me.BuildCorpseTooltip ( Hostile, Name, Level, Class, Location, ConnectedStatus, Status )
	if ( Hostile == nil ) then
		return;
	end
	if ( ConnectedStatus == nil ) then -- Returned from GetFriendInfo
		ConnectedStatus = 0; -- Offline represented differently
	end

	-- Build first line
	local Text = L.CORPSE_FORMAT:format( Name );
	local Color = FACTION_BAR_COLORS[ Hostile and 2 or 6 ];
	GameTooltipTextLeft1:SetTextColor( Color.r, Color.g, Color.b );
	local Right = GameTooltipTextRight1;
	if ( Status and #Status > 0 ) then -- AFK or DND
		Color = NORMAL_FONT_COLOR;
		Right:SetText( Status );
		Right:SetTextColor( Color.r, Color.g, Color.b );
		Right:Show()
	else
		Right:Hide();
	end

	-- Add second status line
	if ( ConnectedStatus ) then -- Connected status is known
		if ( ConnectedStatus == 0 ) then
			Text = L.OFFLINE;
			Color = GRAY_FONT_COLOR;
		else -- Online
			if ( Class ) then -- Show details
				if ( Level ) then
					Text = L.LEVEL_CLASS_PATTERN:format( Level, Class );
				else
					Text = Class;
				end
			else -- Plain online
				Text = L.ONLINE;
			end
			Color = HIGHLIGHT_FONT_COLOR;
		end
		if ( GameTooltip:NumLines() < 2 ) then
			GameTooltip:AddLine( Text, Color.r, Color.g, Color.g );
		else -- Line already shown
			local Left = GameTooltipTextLeft2;
			Left:SetText( Text );
			Left:SetTextColor( Color.r, Color.g, Color.g );
			Left:Show();
			GameTooltipTextRight2:Hide();
		end
	end

	GameTooltip:Show();
end




--[[****************************************************************************
  * Function: _Corpse.SafelyUnregisterChatMsgSystem                            *
  * Description: Unregisters for system chat message events when not expecting *
  *   any more.                                                                *
  ****************************************************************************]]
function me.SafelyUnregisterChatMsgSystem ()
	if ( not me.Enabled
		and not (
			me.AddFriendLast or me.RemoveFriendLast
			or me.InviteUnitLast
			or me.AddFriendSwapLast or me.RemoveFriendSwapLast )
	) then
		me:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	end
end
--[[****************************************************************************
  * Function: _Corpse.ReregisterChatMsgSystem                                  *
  * Description: Reregisters for system chat messages to make sure _Corpse     *
  *   gets those events last.                                                  *
  ****************************************************************************]]
function me.ReregisterChatMsgSystem ()
	if ( me:IsEventRegistered( "CHAT_MSG_SYSTEM" ) ) then
		me:UnregisterEvent( "CHAT_MSG_SYSTEM" );
		me:RegisterEvent( "CHAT_MSG_SYSTEM" );
	end
end




--[[****************************************************************************
  * Function: _Corpse.InviteUnit                                               *
  * Description: Invites and saves the name of a player.                       *
  ****************************************************************************]]
function me.InviteUnit ( Name )
	if ( me.Enabled and not me.InviteUnitLast ) then
		me.InviteUnitLast = Name;
		-- Make sure _Corpse gets events last
		if ( me:IsEventRegistered( "UI_ERROR_MESSAGE" ) ) then
			me:UnregisterEvent( "UI_ERROR_MESSAGE" );
			me:RegisterEvent( "UI_ERROR_MESSAGE" );
		end
		me.ReregisterChatMsgSystem();
		InviteUnit( Name );
		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.AddFriend                                                *
  * Description: Adds a friend and saves the name.                             *
  ****************************************************************************]]
function me.AddFriend ( Name )
	if ( me.Enabled and not ( me.AddFriendLast or me.AddFriendSwapLast ) ) then
		me.AddFriendLast = Name;
		me.ReregisterChatMsgSystem();

		if ( GetNumFriends() >= MAX_IGNORE ) then
			me.RemoveFriendSwap( ( GetFriendInfo( MAX_IGNORE ) ) );
		end
		AddFriend( Name );
		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.RemoveFriend                                             *
  * Description: Removes the last added friend and saves the name.             *
  ****************************************************************************]]
function me.RemoveFriend ()
	me.RemoveFriendLast = me.AddFriendLast;
	me.AddFriendLast = nil;
	me.ReregisterChatMsgSystem();
	RemoveFriend( me.RemoveFriendLast );
end
--[[****************************************************************************
  * Function: _Corpse.AddFriendSwap                                            *
  * Description: Adds the last removed friend that was swapped to make room.   *
  ****************************************************************************]]
function me.AddFriendSwap ()
	if ( me.RemoveFriendSwapLast and not me.AddFriendSwapLast ) then
		me.AddFriendSwapLast = me.RemoveFriendSwapLast;
		me.RemoveFriendSwapLast = nil;
		me.ReregisterChatMsgSystem();

		AddFriend( me.AddFriendSwapLast );
		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.RemoveFriendSwap                                         *
  * Description: Removes a real friend to make room for a temporary friend.    *
  ****************************************************************************]]
function me.RemoveFriendSwap ( Name )
	me.RemoveFriendSwapLast = Name;
	--me.ReregisterChatMsgSystem(); -- Always called before RemoveFriendSwap
	RemoveFriend( Name );
end




--[[****************************************************************************
  * Function: _Corpse.UIErrorsFrameOnEvent                                     *
  * Description: Blocks error messages from trying to invite enemies to group. *
  ****************************************************************************]]
function me.UIErrorsFrameOnEvent ( Event, Message, ... )
	if ( not ( me.InviteUnitLast and Event == "UI_ERROR_MESSAGE" and Message == L.ENEMY_ONLINE ) ) then
		-- Not caused by _Corpse, okay to display error
		return me.UIErrorsFrameOnEventBackup( Event, Message, ... );
	end
end
--[[****************************************************************************
  * Function: _Corpse.ChatFrameMessageEventHandler                             *
  * Description: Blocks automated invite and remove messages.                  *
  ****************************************************************************]]
function me.ChatFrameMessageEventHandler ( Event, ... )
	if ( Event == "CHAT_MSG_SYSTEM" ) then
		local Message = arg1;
		local Name;

		if ( me.AddFriendLast or me.AddFriendSwapLast ) then
			if ( Message == L.FRIEND_IS_ENEMY ) then
				return;
			else
				Name = select( 3, Message:find( L.FRIEND_ADDED_PATTERN ) );
				if ( Name and ( Name == me.AddFriendLast or Name == me.AddFriendSwapLast ) ) then
					return;
				end
			end
		end
		if ( me.InviteUnitLast ) then
			Name = select( 3, Message:find( L.ENEMY_OFFLINE_PATTERN ) );
			if ( Name and Name == me.InviteUnitLast ) then
				return;
			end
		end
		if ( me.RemoveFriendLast or me.RemoveFriendSwapLast ) then
			Name = select( 3, Message:find( L.FRIEND_REMOVED_PATTERN ) );
			if ( Name and ( Name == me.RemoveFriendLast or Name == me.RemoveFriendSwapLast ) ) then
				return;
			end
		end
	end

	-- Not caused by _Corpse, okay to display message
	return me.ChatFrameMessageEventHandlerBackup( Event, ... );
end




--[[****************************************************************************
  * Function: _Corpse:CHAT_MSG_SYSTEM                                          *
  ****************************************************************************]]
function me:CHAT_MSG_SYSTEM ( _, Message )
	if ( me.AddFriendLast or me.AddFriendSwapLast ) then
		if ( Message == L.FRIEND_IS_ENEMY ) then
			-- Add failed (Ambiguous); horde
			Enemies[ me.AddFriendLast ] = false;
			if ( me.AddFriendLast == me.GetCorpseName() ) then -- Tooltip still up
				me.BuildCorpseTooltip( true, me.AddFriendLast, nil, nil, nil, false );
			end
			me.InviteUnit( me.AddFriendLast );
			me.AddFriendLast = nil;
			me.SafelyUnregisterChatMsgSystem();
			return;
		else
			local Name = select( 3, Message:find( L.FRIEND_ADDED_PATTERN ) );
			if ( Name ) then
				-- Added successfully
				if ( Name == me.AddFriendLast ) then
					if ( Name == me.GetCorpseName() ) then -- Tooltip still up
						me.BuildCorpseTooltip( false, GetFriendInfo( me.GetFriendIndex( Name ) ) );
					end
					me.RemoveFriend(); -- Remove temporary friend
					me.AddFriendSwap(); -- Add swapped friend back onto list
					me.SafelyUnregisterChatMsgSystem();
				elseif ( Name == me.AddFriendSwapLast ) then
					me.AddFriendSwapLast = nil;
					me.SafelyUnregisterChatMsgSystem();
				end
				return;
			end
		end
	end

	if ( me.InviteUnitLast ) then
		local Name = select( 3, Message:find( L.ENEMY_OFFLINE_PATTERN ) );
		if ( Name ) then
			if ( Name == me.InviteUnitLast ) then
				-- Horde player is offline
				if ( Enemies[ Name ] ~= 0 ) then
					Enemies[ Name ] = 0;
					if ( Name == me.GetCorpseName() ) then -- Tooltip still up
						me.BuildCorpseTooltip( true, Name, nil, nil, nil, 0 );
					end
				end
				me.InviteUnitLast = nil;
				me.SafelyUnregisterChatMsgSystem();
			end
			return;
		end
	end

	if ( me.RemoveFriendLast ) then
		local Name = select( 3, Message:find( L.FRIEND_REMOVED_PATTERN ) );
		if ( Name ) then
			if ( Name == me.RemoveFriendLast ) then
				-- Temporary friend removed successfully
				me.RemoveFriendLast = nil;
				me.SafelyUnregisterChatMsgSystem();
			end
			return;
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse:UI_ERROR_MESSAGE                                         *
  ****************************************************************************]]
function me:UI_ERROR_MESSAGE ( _, Message )
	if ( me.InviteUnitLast and Message == L.ENEMY_ONLINE ) then
		-- Horde player is online (Ambiguous)
		if ( Enemies[ me.InviteUnitLast ] ~= 1 ) then -- Changed
			Enemies[ me.InviteUnitLast ] = 1;
			if ( me.InviteUnitLast == me.GetCorpseName() ) then -- Tooltip still up
				me.BuildCorpseTooltip( true, me.InviteUnitLast, nil, nil, nil, 1 );
			end
		end
		me.InviteUnitLast = nil;
		if ( not me.Enabled ) then
			me:UnregisterEvent( "UI_ERROR_MESSAGE" );
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse:FRIENDLIST_UPDATE                                        *
  * Description: Called when cached friendlist data is updated.                *
  ****************************************************************************]]
function me:FRIENDLIST_UPDATE ()
	local Name = me.GetCorpseName();
	if ( Name ) then
		local Index = me.GetFriendIndex( Name );
		if ( Index ) then
			me.BuildCorpseTooltip( false, GetFriendInfo( Index ) );
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse:PLAYER_ENTERING_WORLD                                    *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	local Type = select( 2, IsInInstance() );
	if ( Type == "pvp" ) then -- In battleground
		me.Battlegrounds.Enable();
	elseif ( Type == "arena" ) then
		me.Disable();
	else
		me.Enable();
	end
end
--[[****************************************************************************
  * Function: _Corpse:OnEvent                                                  *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( me[ Event ] ) == "function" ) then
			me[ Event ]( me, Event, ... );
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse:OnUpdate                                                 *
  * Description: Global update handler.                                        *
  ****************************************************************************]]
function me:OnUpdate ()
	local Name = me.GetCorpseName();
	if ( Name ) then -- Found corpse tooltip

		local PlayerName = UnitName( "player" );
		if ( Name == PlayerName ) then -- Our own corpse
			me.BuildCorpseTooltip( false, PlayerName,
				UnitLevel( "player" ), UnitClass( "player" ), GetRealZoneText(), 1,
				( UnitIsAFK( "player" ) and L.AFK ) or ( UnitIsDND( "player" ) and L.DND ) );
		elseif ( Enemies[ Name ] ~= nil ) then
			me.BuildCorpseTooltip( true, Name, nil, nil, nil, Enemies[ Name ] );
			me.InviteUnit( Name );
		else
			local Index = me.GetFriendIndex( Name );
			if ( Index ) then -- Player already a friend
				ShowFriends();
				-- Build tooltip with possibly old data
				me.BuildCorpseTooltip( false, GetFriendInfo( Index ) );
			else
				me.AddFriend( Name );
			end
		end
	end

	me:Hide();
end


--[[****************************************************************************
  * Function: _Corpse:ShowHookOnShow                                           *
  * Description: Hook called when GameTooltip updates.                         *
  ****************************************************************************]]
function me:ShowHookOnShow ()
	-- Tooltip was cleared; read it before next draw
	me:Show();
end
--[[****************************************************************************
  * Function: _Corpse.ShowHookUpdate                                           *
  * Description: Resets _Corpse's hook to react to updates in the tooltip      *
  *   found in GameTooltip.  Use if an addon completely replaces the default   *
  *   tooltip.                                                                 *
  ****************************************************************************]]
function me.ShowHookUpdate ()
	ShowHookFrame:SetParent( GameTooltip );
end




--[[****************************************************************************
  * Function: _Corpse.Enable                                                   *
  * Description: Enables events and hooks.                                     *
  ****************************************************************************]]
function me.Enable ()
	if ( not me.Enabled ) then
		me.Enabled = true;

		me.Battlegrounds.Disable();
		me:Hide();
		me:SetScript( "OnUpdate", me.OnUpdate );

		me:RegisterEvent( "CHAT_MSG_SYSTEM" );
		me:RegisterEvent( "UI_ERROR_MESSAGE" );
		me:RegisterEvent( "FRIENDLIST_UPDATE" );

		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.Disable                                                  *
  * Description: Disables events and hooks.                                    *
  ****************************************************************************]]
function me.Disable ()
	if ( me.Enabled ) then
		me.Enabled = false;

		me:Hide();
		me:SetScript( "OnUpdate", nil );

		me:UnregisterEvent( "FRIENDLIST_UPDATE" );
		if ( not me.InviteUnitLast ) then
			me:UnregisterEvent( "UI_ERROR_MESSAGE" );
			me.SafelyUnregisterChatMsgSystem();
		end

		return true;
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );

	ShowHookFrame:SetScript( "OnShow", me.ShowHookOnShow );
	me.ShowHookUpdate();

	UIErrorsFrame_OnEvent = me.UIErrorsFrameOnEvent;
	ChatFrame_MessageEventHandler = me.ChatFrameMessageEventHandler;
end
