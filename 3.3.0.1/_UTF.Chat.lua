--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Chat.lua - Text replacement hooks.                                    *
  *                                                                            *
  * + Adds text replacement to non-secure macro commands.                      *
  * + Replaces text in the chat frame edit box when tab is pressed.            *
  ****************************************************************************]]


_UTFOptions.Chat = {
	EntityReferenceReplace = true;
	TextReplace = false;
	TextReplacements = {
		{ "%.%.%.+", _UTF.DecToUTF( 8230 ) } -- &hellip;
	};
};


local _UTF = _UTF;
local me = {
	ChatEditCustomTabPressedBackup = ChatEdit_CustomTabPressed;
	SendChatMessageBackup = SendChatMessage;
};
_UTF.Chat = me;




--[[****************************************************************************
  * Function: _UTF.Chat.ReplaceEditBoxText                                     *
  * Description: Replaces character references in a chat edit box.             *
  ****************************************************************************]]
function me.ReplaceEditBoxText ( EditBox )
	if ( _UTFOptions.Chat.EntityReferenceReplace ) then
		local OldText = EditBox:GetText();
		local Command = OldText:match( "^(/%S+)" );
		if ( not ( Command and IsSecureCmd( Command ) ) ) then
			local NewText, CursorPosition = _UTF.ReplaceCharacterReferences( OldText, EditBox:GetCursorPosition() );
			if ( OldText ~= NewText ) then
				EditBox:SetText( NewText );
				EditBox:SetCursorPosition( CursorPosition );
				return true;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Chat:ChatEditCustomTabPressed                               *
  * Description: Replaces references when tab is pressed in an edit box.       *
  ****************************************************************************]]
function me:ChatEditCustomTabPressed ()
	if ( not self ) then
		self = this;
	end
	local BackupReturn = me.ChatEditCustomTabPressedBackup( self );
	return me.ReplaceEditBoxText( self ) or BackupReturn;
end


--[[****************************************************************************
  * Function: _UTF.Chat.SendChatMessage                                        *
  * Description: Replaces custom text strings in outbound chat. Note that it   *
  *   could pulverize the string table with many replacements.                 *
  ****************************************************************************]]
do
	local ipairs = ipairs;
	function me.SendChatMessage ( Message, ... )
		if ( _UTFOptions.Chat.TextReplace and Message ) then
			for _, Replacement in ipairs( _UTFOptions.Chat.TextReplacements ) do
				Message = Message:gsub( Replacement[ 1 ], Replacement[ 2 ] );
			end
		end
	
		me.SendChatMessageBackup( Message, ... );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	--hooksecurefunc( ChatFrameEditBox, "SetText", me.ReplaceEditBoxText );
	hooksecurefunc( MacroEditBox, "SetText", me.ReplaceEditBoxText );
	ChatEdit_CustomTabPressed = me.ChatEditCustomTabPressed;

	SendChatMessage = me.SendChatMessage;
end
