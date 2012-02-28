# -*- coding: utf_8 -*-
"""Shared routines to handle Lua source files."""

import lupa

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'LGPL'

runtime = lupa.LuaRuntime(encoding=None)
"""Shared Lua runtime environment with no automatic encoding."""

escapeData = runtime.eval('''
  function ( String )
    return ( "%q" ):format( String );
  end
  ''')
"""Returns input bytes properly escaped and quoted for use in Lua source code."""

_loadData = runtime.eval('''
  --- @return Globals defined by String from Filename.
  function ( String, Filename )
    local Env = {}; -- Fill with global definitions from file
    setfenv( assert( loadstring( String, Filename ) ), Env )();
    return Env;
  end
  ''')
def loadSavedVariables(filename):
  """Returns global variables defined by a World of Warcraft Lua saved variables file."""
  # Can't use Lua's `loadfile` function since it can't handle Unicode paths
  with open(filename, 'rb') as savedVariables:
    return _loadData(savedVariables.read(), filename.encode('utf_8'))