--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Standard.lua - Uses the friends list to get corpse info.           *
  ****************************************************************************]]


local L = _CorpseLocalization;
local _Corpse = _Corpse;
local me = CreateFrame( "Frame", nil, _Corpse );
_Corpse.Standard = me;

me.Enemies = {}; -- Name-indexed hash of connection status.  Values: false = Unknown, 0 = Offline, 1 = Online
me.Allies = {};

me.AddFriendLast = nil; -- Saved in case added friend is hostile(ambiguous case)
me.RemoveFriendLast = nil; -- Saved so system message can be hidden
me.InviteUnitLast = nil; -- Saved in case invited enemy is online(ambiguous case)
-- Following used when friends list is full
me.RemoveFriendSwapLast = nil;
me.AddFriendSwapLast = nil;

me.UIErrorsFrameOnEventBackup = UIErrorsFrame:GetScript( "OnEvent" );

local MAX_FRIENDS = 100;




--[[****************************************************************************
  * Function: _Corpse.Standard:CacheFriendInfo                                 *
  * Description: Caches the online status of results from GetFriendInfo, and   *
  *   then updates the corpse tooltip if necessary.                            *
  ****************************************************************************]]
function me:CacheFriendInfo ( ... )
	local Name = ...;
	if ( Name ) then
		local ConnectedStatus = select( 5, ... ) or 0;
		if ( ConnectedStatus == 1 or self.Allies[ Name ] ~= 0 ) then
			-- Info changed
			if ( Name == _Corpse.GetCorpseName() ) then -- Tooltip still up
				_Corpse.BuildCorpseTooltip( false, ... );
			end
		end
		self.Allies[ Name ] = ConnectedStatus;
	end
end




--[[****************************************************************************
  * Function: _Corpse.Standard:InviteUnit                                      *
  * Description: Invites and saves the name of a player.                       *
  ****************************************************************************]]
function me:InviteUnit ( Name )
	if ( _Corpse.IsModuleActive( self ) and not self.InviteUnitLast ) then
		self.InviteUnitLast = Name;
		self:ReregisterEvent( "UI_ERROR_MESSAGE" );
		self:ReregisterEvent( "CHAT_MSG_SYSTEM" );
		InviteUnit( Name );
		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:AddFriend                                       *
  * Description: Adds a friend and saves the name.                             *
  ****************************************************************************]]
function me:AddFriend ( Name )
	if ( not ( self.AddFriendLast or self.AddFriendSwapLast ) ) then
		self.AddFriendLast = Name;
		self:ReregisterEvent( "CHAT_MSG_SYSTEM" );

		if ( GetNumFriends() >= MAX_FRIENDS ) then
			self:RemoveFriendSwap( ( GetFriendInfo( MAX_FRIENDS ) ) );
		end
		AddFriend( Name, true ); -- "Ignore" flag for friend managing addons
		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:RemoveFriend                                    *
  * Description: Removes the last added friend and saves the name.             *
  ****************************************************************************]]
function me:RemoveFriend ()
	self.RemoveFriendLast = self.AddFriendLast;
	self.AddFriendLast = nil;
	self:ReregisterEvent( "CHAT_MSG_SYSTEM" );
	RemoveFriend( self.RemoveFriendLast, true ); -- "Ignore" flag for friend managing addons
end
--[[****************************************************************************
  * Function: _Corpse.Standard:AddFriendSwap                                   *
  * Description: Adds the last removed friend that was swapped to make room.   *
  ****************************************************************************]]
function me:AddFriendSwap ()
	if ( self.RemoveFriendSwapLast and not self.AddFriendSwapLast ) then
		self.AddFriendSwapLast = self.RemoveFriendSwapLast;
		self.RemoveFriendSwapLast = nil;
		self:ReregisterEvent( "CHAT_MSG_SYSTEM" );

		AddFriend( self.AddFriendSwapLast, true ); -- "Ignore" flag for friend managing addons
		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:RemoveFriendSwap                                *
  * Description: Removes a real friend to make room for a temporary friend.    *
  ****************************************************************************]]
function me:RemoveFriendSwap ( Name )
	self.RemoveFriendSwapLast = Name;
	--self:ReregisterEvent( "CHAT_MSG_SYSTEM" ); -- Always called before RemoveFriendSwap
	RemoveFriend( Name, true ); -- "Ignore" flag for friend managing addons
end




--[[****************************************************************************
  * Function: _Corpse.Standard:UIErrorsFrameOnEvent                            *
  * Description: Blocks error messages from trying to invite enemies to group. *
  ****************************************************************************]]
function me:UIErrorsFrameOnEvent ( Event, Message, ... )
	if ( not ( me.InviteUnitLast and Event == "UI_ERROR_MESSAGE" and Message == L.ENEMY_ONLINE ) ) then
		-- Not caused by _Corpse, okay to display error
		return me.UIErrorsFrameOnEventBackup( self, Event, Message, ... );
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:MessageEventHandler                             *
  * Description: Blocks automated invite and remove messages.                  *
  ****************************************************************************]]
function me:MessageEventHandler ( _, Message )
	local Name;

	if ( me.AddFriendLast or me.AddFriendSwapLast ) then
		if ( Message == L.FRIEND_IS_ENEMY ) then
			return true;
		else
			Name = Message:match( L.FRIEND_ADDED_PATTERN );
			if ( Name and ( Name == me.AddFriendLast or Name == me.AddFriendSwapLast ) ) then
				return true;
			end
		end
	end
	if ( me.InviteUnitLast ) then
		Name = Message:match( L.ENEMY_OFFLINE_PATTERN );
		if ( Name and Name == me.InviteUnitLast ) then
			return true;
		end
	end
	if ( me.RemoveFriendLast or me.RemoveFriendSwapLast ) then
		Name = Message:match( L.FRIEND_REMOVED_PATTERN );
		if ( Name and ( Name == me.RemoveFriendLast or Name == me.RemoveFriendSwapLast ) ) then
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:UnregisterChatMsgSystemSafely                   *
  * Description: Unregisters for system chat message events when not expecting *
  *   any more.                                                                *
  ****************************************************************************]]
function me:UnregisterChatMsgSystemSafely ()
	if ( not _Corpse.IsModuleActive( self )
		and not (
			self.AddFriendLast or self.RemoveFriendLast
			or self.InviteUnitLast
			or self.AddFriendSwapLast or self.RemoveFriendSwapLast )
	) then
		self:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:ReregisterEvent                                 *
  * Description: Reregisters an event so _Corpse gets it last.                 *
  ****************************************************************************]]
function me:ReregisterEvent ( Event )
	if ( self:IsEventRegistered( Event ) ) then
		self:UnregisterEvent( Event );
		self:RegisterEvent( Event );
	end
end




--[[****************************************************************************
  * Function: _Corpse.Standard:CHAT_MSG_SYSTEM                                 *
  ****************************************************************************]]
function me:CHAT_MSG_SYSTEM ( _, Message )
	if ( self.AddFriendLast or self.AddFriendSwapLast ) then
		if ( Message == L.FRIEND_IS_ENEMY ) then
			-- Add failed (Ambiguous); enemy
			self.Enemies[ self.AddFriendLast ] = false;
			if ( self.AddFriendLast == _Corpse.GetCorpseName() ) then -- Tooltip still up
				_Corpse.BuildCorpseTooltip( true, self.AddFriendLast, nil, nil, nil, false );
			end
			self:InviteUnit( self.AddFriendLast );
			self.AddFriendLast = nil;
			self:UnregisterChatMsgSystemSafely();
			return;
		else
			local Name = Message:match( L.FRIEND_ADDED_PATTERN );
			if ( Name ) then
				-- Added successfully
				if ( Name == self.AddFriendLast ) then
					-- Update tooltip
					self:CacheFriendInfo( GetFriendInfo( Name ) );
					self:RemoveFriend(); -- Remove temporary friend
					self:AddFriendSwap(); -- Add swapped friend back onto list
					self:UnregisterChatMsgSystemSafely();
				elseif ( Name == self.AddFriendSwapLast ) then
					self.AddFriendSwapLast = nil;
					self:UnregisterChatMsgSystemSafely();
				end
				return;
			end
		end
	end

	if ( self.InviteUnitLast ) then
		local Name = Message:match( L.ENEMY_OFFLINE_PATTERN );
		if ( Name ) then
			if ( Name == self.InviteUnitLast ) then
				-- Enemy player is offline
				if ( self.Enemies[ Name ] ~= 0 ) then
					self.Enemies[ Name ] = 0;
					if ( Name == _Corpse.GetCorpseName() ) then -- Tooltip still up
						_Corpse.BuildCorpseTooltip( true, Name, nil, nil, nil, 0 );
					end
				end
				self.InviteUnitLast = nil;
				self:UnregisterChatMsgSystemSafely();
			end
			return;
		end
	end

	if ( self.RemoveFriendLast ) then
		local Name = Message:match( L.FRIEND_REMOVED_PATTERN );
		if ( Name ) then
			if ( Name == self.RemoveFriendLast ) then
				-- Temporary friend removed successfully
				self.RemoveFriendLast = nil;
				self:UnregisterChatMsgSystemSafely();
			end
			return;
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:UI_ERROR_MESSAGE                                *
  ****************************************************************************]]
function me:UI_ERROR_MESSAGE ( _, Message )
	if ( self.InviteUnitLast and Message == L.ENEMY_ONLINE ) then
		-- Enemy player is online (Ambiguous)
		if ( self.Enemies[ self.InviteUnitLast ] ~= 1 ) then -- Changed
			self.Enemies[ self.InviteUnitLast ] = 1;
			if ( self.InviteUnitLast == _Corpse.GetCorpseName() ) then -- Tooltip still up
				_Corpse.BuildCorpseTooltip( true, self.InviteUnitLast, nil, nil, nil, 1 );
			end
		end
		self.InviteUnitLast = nil;
		if ( not _Corpse.IsModuleActive( self ) ) then
			self:UnregisterEvent( "UI_ERROR_MESSAGE" );
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:FRIENDLIST_UPDATE                               *
  * Description: Called when cached friendlist data is updated.                *
  ****************************************************************************]]
function me:FRIENDLIST_UPDATE ()
	local Name = _Corpse.GetCorpseName();
	if ( Name ) then
		self:CacheFriendInfo( GetFriendInfo( Name ) );
	end
end




--[[****************************************************************************
  * Function: _Corpse.Standard:Update                                          *
  ****************************************************************************]]
function me:Update ( Name )
	local PlayerName = UnitName( "player" );

	if ( Name == PlayerName ) then -- Our own corpse
		_Corpse.BuildCorpseTooltip( false, PlayerName,
			UnitLevel( "player" ), UnitClass( "player" ), GetRealZoneText(), 1,
			( UnitIsAFK( "player" ) and CHAT_FLAG_AFK ) or ( UnitIsDND( "player" ) and CHAT_FLAG_DND ) );
	elseif ( self.Enemies[ Name ] ~= nil ) then
		_Corpse.BuildCorpseTooltip( true, Name, nil, nil, nil, self.Enemies[ Name ] );
		self:InviteUnit( Name );
	else
		if ( GetFriendInfo( Name ) ) then -- Player already a friend
			ShowFriends();
			-- Build tooltip with possibly old data
			_Corpse.BuildCorpseTooltip( false, GetFriendInfo( Name ) );
		else
			if ( self.Allies[ Name ] ~= nil ) then
				_Corpse.BuildCorpseTooltip( false, Name , nil, nil, nil,
					self.Allies[ Name ] == 0 and 0 or false ); -- Don't fill in if last seen online
			end
			self:AddFriend( Name );
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.Standard:Enable                                          *
  ****************************************************************************]]
function me:Enable ()
	self:RegisterEvent( "CHAT_MSG_SYSTEM" );
	self:RegisterEvent( "UI_ERROR_MESSAGE" );
	self:RegisterEvent( "FRIENDLIST_UPDATE" );
end
--[[****************************************************************************
  * Function: _Corpse.Standard:Disable                                         *
  ****************************************************************************]]
function me:Disable ()
	self:UnregisterEvent( "FRIENDLIST_UPDATE" );
	if ( not self.InviteUnitLast ) then
		self:UnregisterEvent( "UI_ERROR_MESSAGE" );
		self:UnregisterChatMsgSystemSafely();
	end
end




me:SetScript( "OnEvent", _Corpse.OnEvent );

UIErrorsFrame:SetScript( "OnEvent", me.UIErrorsFrameOnEvent );
ChatFrame_AddMessageEventFilter( "CHAT_MSG_SYSTEM", me.MessageEventHandler );