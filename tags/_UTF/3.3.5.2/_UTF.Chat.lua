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


--- Replaces references when tab is pressed in an edit box.
-- @return True if the tab keypress was handled.
do
	local function HandleReturn ( self, Handled, ... )
		return me.ReplaceEditBoxText( self ) or Handled, ...;
	end
	local Backup = ChatEdit_CustomTabPressed;
	function me:ChatEditCustomTabPressed ( ... )
		if ( not self ) then
			self = this;
		end
		return HandleReturn( self, Backup( self, ... ) );
	end
end
--- Replaces custom text strings in outbound chat.
do
	local Backup = SendChatMessage;
	function me.SendChatMessage ( Message, ... )
		if ( _UTFOptions.Chat.TextReplace and Message ) then
			for _, Replacement in ipairs( _UTFOptions.Chat.TextReplacements ) do
				Message = Message:gsub( Replacement[ 1 ], Replacement[ 2 ] );
			end
		end

		return Backup( Message, ... );
	end
end




-- Hook to catch macro lines as they're executed
hooksecurefunc( MacroEditBox, "SetText", me.ReplaceEditBoxText );

ChatEdit_CustomTabPressed = me.ChatEditCustomTabPressed;
SendChatMessage = me.SendChatMessage;