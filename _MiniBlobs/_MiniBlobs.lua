--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * _MiniBlobs.lua - Adds digsites and quest regions to the minimap.           *
  ****************************************************************************]]


local AddOnName, NS = ...;
_MiniBlobs = NS;
NS.Frame = CreateFrame( "Frame" );
NS.Callbacks = LibStub( "CallbackHandler-1.0" ):New( NS );

NS.Types = {
	[ "Archaeology" ] = {};
	[ "Quests" ] = {};
};
NS.Styles = { --- Available render options for blobs.
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
function NS.Print ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( NS.L.PRINT_FORMAT:format( Message ), Color.r, Color.g, Color.b );
end


--- Global event handler.
function NS.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end
--- Load saved variables.
function NS.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		NS:Unpack( _MiniBlobsOptionsCharacter or {} );
		self:RegisterEvent( "PLAYER_LOGOUT" );
	end
end
--- Save settings before exiting.
function NS.Frame:PLAYER_LOGOUT ()
	_MiniBlobsOptionsCharacter = NS:Pack();
end




--- Unpacks settings for a specific blob type.
function NS:UnpackType ( Type, Options )
	self:SetTypeEnabled( Type, Options.Enabled );
	self:SetTypeAlpha( Type, Options.Alpha );
	self:SetTypeStyle( Type, Options.Style );
end
--- Applies settings from storage.
function NS:Unpack ( Options )
	self:SetQuality( Options.Quality );
	self:SetQuestsFilter( Options.QuestsFilter );
	for Type in pairs( self.Types ) do
		self:UnpackType( Type, Options[ Type ] or {} );
	end
end
--- @return A table representing this blob type's settings.
function NS:PackType ( Type )
	return {
		Enabled = self:GetTypeEnabled( Type );
		Alpha = self:GetTypeAlpha( Type );
		Style = self:GetTypeStyle( Type );
	};
end
--- @return A table representing active settings.
function NS:Pack ()
	local Options = {
		Quality = self:GetQuality();
		QuestsFilter = self:GetQuestsFilter();
	};
	for Type in pairs( self.Types ) do
		Options[ Type ] = self:PackType( Type );
	end
	return Options;
end


--- Enables or disables the given blob type on the minimap.
function NS:SetTypeEnabled ( Type, Enabled )
	Enabled = Enabled == nil or not not Enabled; -- Default to true if nil
	if ( self.Types[ Type ].Enabled ~= Enabled ) then
		self.Types[ Type ].Enabled = Enabled;
		self.Callbacks:Fire( "MiniBlobs_TypeEnabled", Type, Enabled );
		return true;
	end
end
--- @return True if this blob type is enabled.
function NS:GetTypeEnabled ( Type )
	return self.Types[ Type ].Enabled;
end

--- Sets the background fill alpha for the given blob type.
function NS:SetTypeAlpha ( Type, Alpha )
	Alpha = assert( tonumber( Alpha or 0.25 ), "Alpha must be numeric." );
	Alpha = max( 0, min( 1, Alpha ) );
	if ( self.Types[ Type ].Alpha ~= Alpha ) then
		self.Types[ Type ].Alpha = Alpha;
		self.Callbacks:Fire( "MiniBlobs_TypeAlpha", Type, Alpha );
		return true;
	end
end
--- @return Alpha value between 0 and 1 for this blob type.
function NS:GetTypeAlpha ( Type )
	return self.Types[ Type ].Alpha;
end

--- Sets the blob render style for the given blob type.
-- @see NS.Styles
function NS:SetTypeStyle ( Type, Style )
	Style = Style or Type; -- Default to style named after type
	assert( self.Styles[ Style ], "Unknown style value." );
	if ( self.Types[ Type ].Style ~= Style ) then
		self.Types[ Type ].Style = Style;
		self.Callbacks:Fire( "MiniBlobs_TypeStyle", Type, Style, self.Styles[ Style ] );
		return true;
	end
end
--- @return A string identifier for this blob type's style.
function NS:GetTypeStyle ( Type )
	return self.Types[ Type ].Style;
end

do
	local QuestsFilter;
	local Values = {
		NONE = true; -- No filter
		WATCHED = true; -- Tracked quests only
		SELECTED = true; -- Selected ("super tracked") quest only
	};
	--- Sets which method to filter quest blobs by.
	-- @param Filter  "NONE", "WATCHED" for tracked quests, or "SELECTED" for super tracked quests.
	function NS:SetQuestsFilter ( Filter )
		Filter = Filter or "NONE";
		assert( Values[ Filter ], "Unknown filter type." );
		if ( QuestsFilter ~= Filter ) then
			QuestsFilter = Filter;
			self.Callbacks:Fire( "MiniBlobs_QuestsFilter", Filter );
			return true;
		end
	end
	--- @return Current quests filter method.
	function NS:GetQuestsFilter ()
		return QuestsFilter;
	end
end

local BlobQuality;
--- Adjusts rendering options of all blob types for performance or quality.
-- @param Quality  Float within [0,1], where 0 is max performance and 1 is max quality.
function NS:SetQuality ( Quality )
	Quality = assert( tonumber( Quality or 0 ), "Quality must be numeric." );
	Quality = max( 0, min( 1, Quality ) );
	if ( BlobQuality ~= Quality ) then
		BlobQuality = Quality;
		self.Callbacks:Fire( "MiniBlobs_Quality", Quality );
		return true;
	end
end
--- @return Render quality float value between 0 and 1.
function NS:GetQuality ()
	return BlobQuality;
end




NS.Frame:SetScript( "OnEvent", NS.Frame.OnEvent );
NS.Frame:RegisterEvent( "ADDON_LOADED" );