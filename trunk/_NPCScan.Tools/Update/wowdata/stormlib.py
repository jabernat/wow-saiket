# -*- coding: utf_8 -*-
"""StormLib is a C++ library for manipulating MPQ archives, by Ladislav Zezula (ladik@zezula.net).

Documentation can be found at <http://www.zezula.net/en/mpq/stormlib.html>.
"""

import ctypes
import os.path

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'LGPL'
__credits__ = ['Ladislav Zezula']

_stormlib = ctypes.windll.LoadLibrary(os.path.join(os.path.dirname(__file__), 'StormLib.dll'))

# Flags for SFileOpenArchive
MPQ_OPEN_NO_LISTFILE   = 0x0010
"""Don't load the internal listfile."""
MPQ_OPEN_NO_ATTRIBUTES = 0x0020
"""Don't open the attributes file."""
MPQ_OPEN_READ_ONLY     = 0x0100
"""Open the archive for read-only access."""

# Values for SFileOpenFile
SFILE_OPEN_FROM_MPQ     = 0x00000000
"""Open the file from the MPQ archive."""
SFILE_OPEN_PATCHED_FILE = 0x00000001
"""Apply patches for read operations."""

_ERROR_FILE_NOT_FOUND = 2
_ERROR_HANDLE_EOF = 38
_SFILE_INVALID_SIZE = 0xFFFFFFFF

def _errcheck(result, func, args):
  """Standard error check function for StormLib APIs to validate boolean returns."""
  if not result:
    raise ctypes.WinError()
  return args


def _import_func(name, restype, args, errcheck=_errcheck):
  """Shortcut to `ctypes` foreign function wrapper API."""
  argtypes, paramflags = [], []
  for arg in args:
    argtypes.append(arg[0])
    paramflags.append(arg[1:])
  function = ctypes.WINFUNCTYPE(restype, *argtypes)((name, _stormlib), tuple(paramflags))
  if errcheck:
    function.errcheck = errcheck
  return function


# Reading MPQ archives

SFileOpenArchive = _import_func('SFileOpenArchive', ctypes.c_uint8, (
  (ctypes.c_char_p, 1, 'filename'),  # Archive file name
  (ctypes.c_uint32, 1, 'priority', 0),  # Archive priority (unused)
  (ctypes.c_uint32, 1, 'flags', 0),  # Open flags
  (ctypes.POINTER(ctypes.c_void_p), 2),))  # Pointer to result HANDLE
"""Opens an MPQ archive."""

SFileSetLocale = _import_func('SFileSetLocale', ctypes.c_uint32, (
  (ctypes.c_uint32, 1, 'locale', 0),  # Locale ID for file operations (country IDs in Windows headers)
  ), errcheck=None)
"""Changes default locale country ID for opening files."""

SFileCloseArchive = _import_func('SFileCloseArchive', ctypes.c_uint8, (
  (ctypes.c_void_p, 1, 'mpq'),))  # Handle to an open MPQ
"""Closes an open archive."""

SFileOpenPatchArchive = _import_func('SFileOpenPatchArchive', ctypes.c_uint8, (
  (ctypes.c_void_p, 1, 'mpq'),  # Handle to an open MPQ (primary MPQ)
  (ctypes.c_char_p, 1, 'filename'),  # Patch archive file name
  (ctypes.c_char_p, 1, 'path_prefix', ''),  # Prefix for patch file names
  (ctypes.c_uint32, 0, None, 0),))  # Reserved, not used
"""Applies a patch archive over an open archive."""

# Reading files

SFileOpenFileEx = _import_func('SFileOpenFileEx', ctypes.c_uint8, (
  (ctypes.c_void_p, 1, 'mpq'),  # Archive handle
  (ctypes.c_char_p, 1, 'filename'),  # Name of the file to open
  (ctypes.c_uint32, 1, 'scope', SFILE_OPEN_FROM_MPQ),  # Specifies the search scope for the file.
  (ctypes.POINTER(ctypes.c_void_p), 2),))  # Pointer to file handle
"""Opens a file from an MPQ archive."""

def _SFileGetFileSizeCheck(result, func, args):
  """Validate output of `SFileGetFileSize` and returns a 64-bit filesize."""
  if result == _SFILE_INVALID_SIZE:
    raise ctypes.WinError()
  return (args[1].value << (ctypes.sizeof(ctypes.c_uint32) * 8)) + result
SFileGetFileSize = _import_func('SFileGetFileSize', ctypes.c_uint32, (
  (ctypes.c_void_p, 1, 'file'),  # File handle
  (ctypes.POINTER(ctypes.c_uint32), 2),  # High 32 bits of the file size.
  ), errcheck=_SFileGetFileSizeCheck)
"""Retrieves the size of the file within archive."""

__SFileSetFilePointerHigh = ctypes.c_int32(0)  # Static default pos_high argument
def _SFileSetFilePointerCheck(result, func, args):
  """Validate output of `SFileSetFilePointer` and returns a 64-bit updated file position."""
  high_arg = args[2]
  high = high_arg.value << (ctypes.sizeof(high_arg) * 8) if high_arg is not None else 0
  if high_arg is __SFileSetFilePointerHigh:  # Default value
    high_arg.value = 0  # Reset for next call
  if result == _SFILE_INVALID_SIZE:
    raise ctypes.WinError()
  return high + result
SFileSetFilePointer = _import_func('SFileSetFilePointer', ctypes.c_uint32, (
  (ctypes.c_void_p, 1, 'file'),  # File handle
  (ctypes.c_int32, 1, 'pos_low'),  # Low 32 bits of the file position
  (ctypes.POINTER(ctypes.c_int32),  # Pointer to high 32 bits of the file position
    3, 'pos_high', __SFileSetFilePointerHigh),
  (ctypes.c_uint32, 1, 'whence', os.SEEK_SET),  # The starting point for the file pointer move
  ), errcheck=_SFileSetFilePointerCheck)
"""Seeks to a byte position within the file."""

def _SFileReadFileCheck(result, func, args):
  """Validate output for `SFileReadFile` and returns the number of bytes read."""
  if result or ctypes.GetLastError() == _ERROR_HANDLE_EOF:
    return args
  raise ctypes.WinError()  # Read error
SFileReadFile = _import_func('SFileReadFile', ctypes.c_uint8, (
  (ctypes.c_void_p, 1, 'file'),  # File handle
  (ctypes.POINTER(ctypes.c_char), 1, 'buffer'),  # Pointer to buffer where to read the data
  (ctypes.c_uint32, 1, 'size'),  # Number of bytes to read
  (ctypes.POINTER(ctypes.c_uint32),  # Pointer to variable that receives number of bytes read
    2, 'bytes_read'),
  (ctypes.c_void_p, 1, 'overlapped', None),  # Pointer to OVERLAPPED structure
  ), errcheck=_SFileReadFileCheck)
"""Reads data from the file."""

SFileCloseFile = _import_func('SFileCloseFile', ctypes.c_uint8, (
  (ctypes.c_void_p, 1, 'file'),))  # Handle to an open file
"""Closes the open file handle."""

def _SSFileHasFileCheck(result, func, args):
  """Validate output for `SFileHasFile`."""
  if not result and ctypes.GetLastError() != _ERROR_FILE_NOT_FOUND:
    raise ctypes.WinError()
  return result
SFileHasFile = _import_func('SFileHasFile', ctypes.c_uint8, (
  (ctypes.c_void_p, 1, 'mpq'),  # Handle to an open MPQ
  (ctypes.c_char_p, 1, 'filename'),  # Name of a file to check
  ), errcheck=_SSFileHasFileCheck)
"""Checks for `filename` within the MPQ archive without opening it."""

del _import_func