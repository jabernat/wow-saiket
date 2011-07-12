--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * _MiniBlobs.lua - Adds digsites and quest regions to the minimap.           *
  ****************************************************************************]]


local AddOnName, me = ...;
_MiniBlobs = me;
me.Frame = CreateFrame( "Frame" );
me.Callbacks = LibStub( "CallbackHandler-1.0" ):New( me );

me.Types = {
	[ "Archaeology" ] = {};
	[ "Quests" ] = {};
};
me.Styles = { --- Available render options for blobs.
	-- Blobs default to styles named after their type.
	[ "Archaeology" ] = {
		Fill = [[Interface\WorldMap\UI-ArchaeologyBlob-Inside]];
		Border = [[Interface\WorldMap\UI-ArchaeologyBlob-Outside]];
		BorderScalar = 0.15; BorderAlpha = 0.75;
	};
	[ "Quests" ] = {
		Fill = [[Interface\WorldMap\UI-QuestBlob-Inside]];
		Border = [[Interface\WorldMap\UI-QuestBlob-Outside]];
		BorderScalar = 0.3; BorderAlpha = 1.0;
	};
};




--- Prints a message in the default chat window.
function me.Print ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( me.L.PRINT_FORMAT:format( Message ), Color.r, Color.g, Color.b );
end


--- Global event handler.
function me.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end
--- Load saved variables.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		me:Unpack( _MiniBlobsOptionsCharacter or {} );
		self:RegisterEvent( "PLAYER_LOGOUT" );
	end
end
--- Save settings before exiting.
function me.Frame:PLAYER_LOGOUT ()
	_MiniBlobsOptionsCharacter = me:Pack();
end




--- Unpacks settings for a specific blob type.
function me:UnpackType ( Type, Options )
	self:SetTypeEnabled( Type, Options.Enabled );
	self:SetTypeAlpha( Type, Options.Alpha );
	self:SetTypeStyle( Type, Options.Style );
end
--- Applies settings from storage.
function me:Unpack ( Options )
	self:SetQuality( Options.Quality );
	self:SetQuestsWatched( Options.QuestsWatched );
	for Type in pairs( self.Types ) do
		self:UnpackType( Type, Options[ Type ] or {} );
	end
end
--- @return A table representing this blob type's settings.
function me:PackType ( Type )
	return {
		Enabled = self:GetTypeEnabled( Type );
		Alpha = self:GetTypeAlpha( Type );
		Style = self:GetTypeStyle( Type );
	};
end
--- @return A table representing active settings.
function me:Pack ()
	local Options = {
		Quality = self:GetQuality();
		QuestsWatched = self:GetQuestsWatched();
	};
	for Type in pairs( self.Types ) do
		Options[ Type ] = self:PackType( Type );
	end
	return Options;
end


--- Enables or disables the given blob type on the minimap.
function me:SetTypeEnabled ( Type, Enabled )
	Enabled = Enabled == nil or not not Enabled; -- Default to true if nil
	if ( self.Types[ Type ].Enabled ~= Enabled ) then
		self.Types[ Type ].Enabled = Enabled;
		self.Callbacks:Fire( "MiniBlobs_TypeEnabled", Type, Enabled );
		return true;
	end
end
--- @return True if this blob type is enabled.
function me:GetTypeEnabled ( Type )
	return self.Types[ Type ].Enabled;
end

--- Sets the background fill alpha for the given blob type.
function me:SetTypeAlpha ( Type, Alpha )
	Alpha = assert( tonumber( Alpha or 0.25 ), "Alpha must be numeric." );
	Alpha = max( 0, min( 1, Alpha ) );
	if ( self.Types[ Type ].Alpha ~= Alpha ) then
		self.Types[ Type ].Alpha = Alpha;
		self.Callbacks:Fire( "MiniBlobs_TypeAlpha", Type, Alpha );
		return true;
	end
end
--- @return Alpha value between 0 and 1 for this blob type.
function me:GetTypeAlpha ( Type )
	return self.Types[ Type ].Alpha;
end

--- Sets the blob render style for the given blob type.
-- @see me.Styles
function me:SetTypeStyle ( Type, Style )
	Style = Style or Type; -- Default to style named after type
	assert( self.Styles[ Style ], "Unknown style value." );
	if ( self.Types[ Type ].Style ~= Style ) then
		self.Types[ Type ].Style = Style;
		self.Callbacks:Fire( "MiniBlobs_TypeStyle", Type, Style, self.Styles[ Style ] );
		return true;
	end
end
--- @return A string identifier for this blob type's style.
function me:GetTypeStyle ( Type )
	return self.Types[ Type ].Style;
end

local QuestsWatched;
--- Enables or disables showing only tracked quest blobs.
function me:SetQuestsWatched ( Watched )
	Watched = not not Watched; -- Default to false if nil
	if ( QuestsWatched ~= Watched ) then
		QuestsWatched = Watched;
		self.Callbacks:Fire( "MiniBlobs_QuestsWatched", Watched );
		return true;
	end
end
--- @return True if only watched quests are set to show.
function me:GetQuestsWatched ()
	return QuestsWatched;
end

local BlobQuality;
--- Adjusts rendering options of all blob types for performance or quality.
-- @param Quality  Float within [0,1], where 0 is max performance and 1 is max quality.
function me:SetQuality ( Quality )
	Quality = assert( tonumber( Quality or 0 ), "Quality must be numeric." );
	Quality = max( 0, min( 1, Quality ) );
	if ( BlobQuality ~= Quality ) then
		BlobQuality = Quality;
		self.Callbacks:Fire( "MiniBlobs_Quality", Quality );
		return true;
	end
end
--- @return Render quality float value between 0 and 1.
function me:GetQuality ()
	return BlobQuality;
end




me.Frame:SetScript( "OnEvent", me.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );