--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.Standard.lua - Uses the friends list to get corpse info.           *
  ****************************************************************************]]


local _Corpse = select( 2, ... );
local L = _Corpse.L;
local NS = CreateFrame( "Frame" );
_Corpse.Standard = NS;

NS.Enemies = {}; -- Name-indexed hash of connection status.  Values: false = Unknown, 0 = Offline, 1 = Online
NS.Allies = {};

NS.AddFriendLast = nil; -- Saved in case added friend is hostile(ambiguous case)
NS.RemoveFriendLast = nil; -- Saved so system message can be hidden
NS.InviteUnitLast = nil; -- Saved in case invited enemy is online(ambiguous case)
-- Following used when friends list is full
NS.RemoveFriendSwapLast = nil;
NS.AddFriendSwapLast = nil;

local MAX_FRIENDS = 100;




--- Caches the online status of results from GetFriendInfo, and then updates the corpse tooltip if necessary.
-- @param ...  Returns from GetFriendInfo.
-- @see GetFriendInfo
function NS:CacheFriendInfo ( ... )
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




--- Invites and saves the name of a player.
-- @return True if invite was actually sent.
function NS:InviteUnit ( Name )
	if ( _Corpse.IsModuleActive( self ) and not self.InviteUnitLast ) then
		self.InviteUnitLast = Name;
		self:ReregisterEvent( "UI_ERROR_MESSAGE" );
		self:ReregisterEvent( "CHAT_MSG_SYSTEM" );
		InviteUnit( Name );
		return true;
	end
end
--- Adds a friend and saves the name.
-- @return True if friend actually added.
function NS:AddFriend ( Name )
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
--- Removes the previously added friend and saves the name.
function NS:RemoveFriend ()
	self.RemoveFriendLast = self.AddFriendLast;
	self.AddFriendLast = nil;
	self:ReregisterEvent( "CHAT_MSG_SYSTEM" );
	RemoveFriend( self.RemoveFriendLast, true ); -- "Ignore" flag for friend managing addons
end


--- Adds the previously removed friend that was swapped to make room.
-- @return True if real friend was successfully re-added.
function NS:AddFriendSwap ()
	if ( self.RemoveFriendSwapLast and not self.AddFriendSwapLast ) then
		self.AddFriendSwapLast = self.RemoveFriendSwapLast;
		self.RemoveFriendSwapLast = nil;
		self:ReregisterEvent( "CHAT_MSG_SYSTEM" );

		AddFriend( self.AddFriendSwapLast, true ); -- "Ignore" flag for friend managing addons
		return true;
	end
end
--- Removes a real friend to make room for a temporary friend.
function NS:RemoveFriendSwap ( Name )
	self.RemoveFriendSwapLast = Name;
	--self:ReregisterEvent( "CHAT_MSG_SYSTEM" ); -- Always called before RemoveFriendSwap
	RemoveFriend( Name, true ); -- "Ignore" flag for friend managing addons
end




do
	local Backup = UIErrorsFrame:GetScript( "OnEvent" );
	--- Blocks error messages about trying to invite enemies to group.
	function NS:UIErrorsFrameOnEvent ( Event, Message, ... )
		if ( not ( NS.InviteUnitLast and Event == "UI_ERROR_MESSAGE" and Message == L.ENEMY_ONLINE ) ) then
			-- Not caused by _Corpse, okay to display error
			return Backup( self, Event, Message, ... );
		end
	end
end
-- Blocks automated invite and remove messages.
-- @return True to block a system message.
function NS:MessageEventHandler ( _, Message )
	local Name;

	if ( NS.AddFriendLast or NS.AddFriendSwapLast ) then
		if ( Message == L.FRIEND_IS_ENEMY ) then
			return true;
		else
			Name = Message:match( L.FRIEND_ADDED_PATTERN );
			if ( Name and ( Name == NS.AddFriendLast or Name == NS.AddFriendSwapLast ) ) then
				return true;
			end
		end
	end
	if ( NS.InviteUnitLast ) then
		Name = Message:match( L.ENEMY_OFFLINE_PATTERN );
		if ( Name and Name == NS.InviteUnitLast ) then
			return true;
		end
	end
	if ( NS.RemoveFriendLast or NS.RemoveFriendSwapLast ) then
		Name = Message:match( L.FRIEND_REMOVED_PATTERN );
		if ( Name and ( Name == NS.RemoveFriendLast or Name == NS.RemoveFriendSwapLast ) ) then
			return true;
		end
	end
end
--- Unregisters for system chat message events when not expecting any more.
function NS:UnregisterChatMsgSystemSafely ()
	if ( not _Corpse.IsModuleActive( self )
		and not (
			self.AddFriendLast or self.RemoveFriendLast
			or self.InviteUnitLast
			or self.AddFriendSwapLast or self.RemoveFriendSwapLast )
	) then
		self:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	end
end
--- Reregisters an event so _Corpse gets it last.
function NS:ReregisterEvent ( Event )
	if ( self:IsEventRegistered( Event ) ) then
		self:UnregisterEvent( Event );
		self:RegisterEvent( Event );
	end
end




--- Reacts to system messages resulting from adding/removing friends.
function NS:CHAT_MSG_SYSTEM ( _, Message )
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
--- Reacts to error messages resulting from inviting enemies.
function NS:UI_ERROR_MESSAGE ( _, Message )
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
--- Refreshes any shown corpse tooltip when cached friendlist data updates.
function NS:FRIENDLIST_UPDATE ()
	local Name = _Corpse.GetCorpseName();
	if ( Name ) then
		self:CacheFriendInfo( GetFriendInfo( Name ) );
	end
end




--- Populates the corpse tooltip for the given player using friend list data.
function NS:Update ( Name )
	if ( self.Enemies[ Name ] ~= nil ) then
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
--- Initialize the module when activated.
function NS:Enable ()
	self:RegisterEvent( "CHAT_MSG_SYSTEM" );
	self:RegisterEvent( "UI_ERROR_MESSAGE" );
	self:RegisterEvent( "FRIENDLIST_UPDATE" );
end
--- Uninitialize the module when deactivated.
function NS:Disable ()
	self:UnregisterEvent( "FRIENDLIST_UPDATE" );
	if ( not self.InviteUnitLast ) then
		self:UnregisterEvent( "UI_ERROR_MESSAGE" );
		self:UnregisterChatMsgSystemSafely();
	end
end




NS:SetScript( "OnEvent", _Corpse.Frame.OnEvent );

UIErrorsFrame:SetScript( "OnEvent", NS.UIErrorsFrameOnEvent );
ChatFrame_AddMessageEventFilter( "CHAT_MSG_SYSTEM", NS.MessageEventHandler );