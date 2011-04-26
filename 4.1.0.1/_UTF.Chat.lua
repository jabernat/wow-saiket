--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Chat.lua - Text replacement hooks for macro commands and chat.        *
  ****************************************************************************]]


_UTFOptions.Chat = {
	EntityReferenceReplace = true;
	TextReplace = false;
	TextReplacements = {
		{ "%.%.%.+", _UTF.IntToUTF( 8230 ) } -- &hellip;
	};
};


local _UTF = select( 2, ... );
local me = {};
_UTF.Chat = me;




--- Replaces character references in a chat edit box.
-- @return True if any replacements were made.
function me:ReplaceEditBoxText ()
	if ( _UTFOptions.Chat.EntityReferenceReplace ) then
		local OldText = self:GetText();
		local Command = OldText:match( "^(/%S+)" );
		if ( not ( Command and IsSecureCmd( Command ) ) ) then
			local NewText, CursorPosition = _UTF.ReplaceCharacterReferences( OldText, self:GetCursorPosition() );
			if ( OldText ~= NewText ) then
				self:SetText( NewText );
				self:SetCursorPosition( CursorPosition );
				return true;
			end
		end
	end
end


do
	--- Replaces the "Handled" return without affecting other returns.
	local function HandleReturn ( self, Handled, ... )
		return me.ReplaceEditBoxText( self ) or Handled, ...;
	end
	local Backup = ChatEdit_CustomTabPressed;
	--- Replaces references when tab is pressed in an edit box.
	-- @return True if the tab keypress was handled.
	function me:ChatEditCustomTabPressed ( ... )
		return HandleReturn( self, Backup( self, ... ) );
	end
end
do
	--- Applies all text replacements to a message if enabled.
	local function TextReplace ( Message )
		if ( Message and _UTFOptions.Chat.TextReplace ) then
			for _, Replacement in ipairs( _UTFOptions.Chat.TextReplacements ) do
				Message = Message:gsub( Replacement[ 1 ], Replacement[ 2 ] );
			end
		end
		return Message;
	end
	local Backup = SendChatMessage;
	--- Replaces custom text strings in outbound chat.
	function me.SendChatMessage ( Message, ... )
		return Backup( TextReplace( Message ), ... );
	end

	local Backup = BNSendWhisper;
	--- Replaces custom text strings in outbound Battle.net RealID whispers.
	function me.BNSendWhisper ( ID, Message, ... )
		return Backup( ID, TextReplace( Message ), ... );
	end
end




-- Hook to catch macro lines as they're executed
hooksecurefunc( MacroEditBox, "SetText", me.ReplaceEditBoxText );

ChatEdit_CustomTabPressed = me.ChatEditCustomTabPressed;
SendChatMessage = me.SendChatMessage;
BNSendWhisper = me.BNSendWhisper;