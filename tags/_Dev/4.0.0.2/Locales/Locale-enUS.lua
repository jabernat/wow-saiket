--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


_DevLocalization = setmetatable( {
	COLOR = { r = 0.8; g = 0.8; b = 8 / 15 }; -- Gold, same as title

	-- ToggleMod
	TOGGLEADDON_ERROR_FORMAT = "_|cffcccc88Dev|r: Error loading AddOn “%s”: %s."; -- AddonName, ErrorMessage


	-- Dump
	DUMP_MESSAGE_FORMAT = "_|cffcccc88Dev|r.Dump: %s";
	DUMP_TIME_EXCEEDED = "Time limit exceeded.";
	-- Output formats
	DUMP_TYPE_FORMATS = {
		[ "string" ] = "|cffcccccc“%s|cffcccccc”|r"; -- StringVar (Light gray)
		[ "other" ] = "|cffffffff%s|r"; -- Var
		[ "table" ] = "|cff20ff20<Table %s>|r"; -- TableCount
		[ "function" ] = "|cff33ccff<Function %s>|r"; -- FunctionCount (Teal)
		[ "userdata" ] = "|cffff2020<UserData %s>|r"; -- UserDataCount
		[ "thread" ] = "|cffff2020<Thread %s>|r"; -- ThreadCount
	};
	DUMP_LVALUE_DEFAULT = "_|cffcccc88Dev|r.Dump";
	DUMP_INDENT = "    "; -- Tab-equivalent
	DUMP_GLOBALENV = "_G";
	DUMP_UIOBJECT_FORMAT = "%d: UIObject:%s %s|cff20ff20"; -- TableCount, UIObjectType, UIObjectName
		-- Fed into the table format for UIObjects along with their frame name and type
	DUMP_MAXDEPTH_ABBR = "|cffff2020…|r"; -- Printed when limits reached
	DUMP_MAXSTRLEN_ABBR = "|cffff2020…|r";
	DUMP_MAXTABLELEN_ABBR = "|cffff2020…|r";
	DUMP_MAXEXPLORETIME_ABBR = "|cffff2020…|r";


	-- Events
	ADDONCHAT_MESSAGES = "|cffCCCC88AddOn Messages|r"; -- Tan
	ADDONCHAT_MSG_FORMAT = "[|cff808080Mod|r%s]%1s|Hplayer:%3$s|h[%3$s]|h: [%s] %s";
	ADDONCHAT_OUTBOUND = "»";
		-- Type, Sender, Sender, Prefix, Message
	ADDONCHAT_TYPES = {
		[ "GUILD" ]        = CHAT_MSG_GUILD;
		[ "RAID" ]         = CHAT_MSG_RAID;
		[ "PARTY" ]        = CHAT_MSG_PARTY;
		[ "BATTLEGROUND" ] = CHAT_MSG_BATTLEGROUND;
		[ "WHISPER" ]      = CHAT_MSG_WHISPER_INFORM;
		[ "WHISPER_INFORM" ] = CHAT_MSG_WHISPER_INFORM;
	};


	-- Outline
	OUTLINE_MESSAGE_FORMAT = "_|cffcccc88Dev|r.Outline: %s";
	OUTLINE_ADD_FORMAT = "[|cff%02x%02x%02x█|r] Borders added to “|cff20ff20%s|r”."; -- R, G, B, ObjectName
	OUTLINE_REMOVE_FORMAT = "Borders removed from “|cff20ff20%s|r”."; -- ObjectName
	OUTLINE_REMOVEALL_FORMAT = "%d |4border:borders; removed."; -- OutlineCount
	OUTLINE_INVALID = "Input must evaluate to a valid Region UIObject.";
	OUTLINE_INVALID_DIMENSIONS = "Note - the target frame has a height or width of 0 and may show erroneous borders.";
	OUTLINE_INVALID_POSITION = "Note - the target frame has a nil position and may show no borders.";


	-- Frames
	FRAMES_MESSAGE_FORMAT = "_|cffcccc88Dev|r.Frames: %s";
	FRAMES_ENABLED = "Focus frame browsing enabled.";
	FRAMES_DISABLED = "Focus frame browsing disabled.";
	FRAMES_MOUSEFOCUS = "Mouse Focus";
	FRAMES_UIOBJECT_FORMAT = "|cff20ff20<%s %s|cff20ff20>|r"; -- UIObjectType, UIObjectName
		-- Intentionally similar to Dump's UIObject table format
	FRAMES_BRIEF_FORMAT = "Focus: %s, Parent: %s"; -- FocusName, ParentName

	-- Options
	OPTIONS_TITLE = "_|cffcccc88Dev|r";
	OPTIONS_DESC = "These options control the amount of information _Dev provides, as well as safety limits to protect against overflows and softlocks.";
	OPTIONS = setmetatable( {
		PRINTLUAERRORS = "Print Lua Errors";
		PRINTLUAERRORS_DESC = "Print Lua errors to the chat window rather than causing real errors.  Only protects _Dev-related commands.";

		DUMP = "Dump |cff808080(“/dump”)|r";
		DUMP_SKIPGLOBALENV = "Skip Global Env.";
		DUMP_SKIPGLOBALENV_DESC = "Prevents the global environment from being recursed.  When encountered, it uses the “_G” identifier rather than a table number.";
		DUMP_MAXEXPLORETIME = "Max Explore Time";
		DUMP_MAXEXPLORETIME_DESC = "Maximum number of seconds to spend printing before giving up.  If disabled, some operations such as printing the global environment will softlock the client until it gets disconnected.";
		DUMP_MAXDEPTH = "Max Depth";
		DUMP_MAXDEPTH_DESC = "Maximum number of tables to traverse.  For example, “1” will print the contents of a given table, but will not traverse any sub-tables it may contain.  Note that dump is already protected against recursive tables.";
		DUMP_MAXTABLELEN = "Max Table Length";
		DUMP_MAXTABLELEN_DESC = "Maximum number of elements per table to print before prematurely leaving that table.  For example, “5” will print the first five elements and then leave the table even if there is a sixth.";
		DUMP_MAXSTRLEN = "Max String Length";
		DUMP_MAXSTRLEN_DESC = "Number of characters to escape and print for strings before truncating them.  Can increase performance if full string escaping is enabled.";
		DUMP_ESCAPEMODE = "Escape Mode";
		DUMP_ESCAPEMODE_DESC = "What types of characters will be escaped from printed strings (each is progressively more thorough).";
		DUMP_ESCAPEMODE_ARGS = {
			[ 0 ] = "None|cffffd200 - Raw, fastest.";
			[ 1 ] = "Escapes|cffffd200 - Pipes (“||”).";
			[ 2 ] = "Full|cffffd200 - Pipes & non-ASCII.";
		};

		OUTLINE = "Outline |cff808080(“/outline”)|r";
		OUTLINE_BOUNDSTHRESHOLD = "Bounds Threshold";
		OUTLINE_BOUNDSTHRESHOLD_DESC = "Distance from the edge of the screen an outline can fall before showing a guide marker.  For example, “5” will show a guide when only five pixels of the outline remain on-screen in any direction.";
		OUTLINE_BORDERALPHA = "Border Alpha";
		OUTLINE_BORDERALPHA_DESC = "Opacity of outline borders, between zero for fully transparent and one for opaque.";
		OUTLINE_BORDERALPHA_FORMAT = "%01.01f";
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				Key = Key:gsub( "%.", "_" ):upper();
				return rawget( self, Key ) or "OPTIONS."..Key;
			end
		end;
	} );


	-- Stats
	STATS_HERTZ_FORMAT       = "%.1fHz";
	STATS_MILLISECOND_FORMAT = "%dms";
	STATS_MEGABYTE_FORMAT    = "%.3fMB";
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );


SLASH__DEV_OPTIONS1 = "/dev";
SLASH__DEV_OPTIONS2 = "/devoptions";

-- Bindings
BINDING_HEADER__DEV = "_|cffcccc88Dev|r";

BINDING_NAME__DEV_RELOADUI = "Reload UI";
BINDING_NAME__DEV_OPENCHATSCRIPT = "Open Script";

-- Stats: Rename the old FPS binding instead of making a new one
BINDING_NAME_TOGGLEFPS = "Toggle _|cffcccc88Dev|r.Stats";


-- ToggleMod
SLASH__DEV_TOGGLEADDON1 = "/toggleaddon";
SLASH__DEV_TOGGLEADDON2 = "/togglemod";


-- Dump
SLASH__DEV_DUMP1 = "/dump";
SLASH__DEV_DUMP2 = "/d";


-- Outline
SLASH__DEV_OUTLINE1 = "/outline";

-- Frames
SLASH__DEV_FRAMESTOGGLE1 = "/frames";
BINDING_NAME__DEV_FRAMESTOGGLE = "Toggle Frames Browsing";