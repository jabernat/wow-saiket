# -*- coding: utf_8 -*-
"""Shared routines to handle Lua source files."""

import lupa

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'LGPL'

runtime = lupa.LuaRuntime(encoding=None)
"""Shared Lua runtime environment with no automatic encoding."""

escape_data = runtime.eval('''
  function ( Bytes )
    return ( "%q" ):format( Bytes );
  end
  ''')
"""Returns `Bytes` properly escaped and quoted for use in Lua source code."""

_load_data = runtime.eval('''
  function ( Bytes, Filename )
    local Env = {}; -- Fill with global definitions from file
    setfenv( assert( loadstring( Bytes, Filename ) ), Env )();
    return Env;
  end
  ''')
"""Returns globals defined by `Bytes` from `Filename`."""
def load_saved_variables(filename):
  """Returns global variables defined by a World of Warcraft Lua saved variables file."""
  # Note: Can't use Lua's `loadfile` function since it can't handle Unicode paths.
  with open(filename, 'rb') as saved_variables:
    return _load_data(saved_variables.read(), filename.encode('utf_8'))