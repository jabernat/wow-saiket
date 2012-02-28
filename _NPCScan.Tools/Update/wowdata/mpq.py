# -*- coding: utf_8 -*-
"""MPQ files are archives used in Blizzard games.

This module implements an abstraction around StormLib's APIs with more familiar
methods.  No write-related APIs are included, since this module is intended
for reading official World of Warcraft archives only.  File objects opened from
MPQs implement Python's file type closely so filesystem and MPQ files can be
used interchangeably.
"""

import ctypes
import os.path
import re
import weakref

import wowdata.stormlib as stormlib

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'LGPL'

class _Handle(object):
  """Abstract class for resource handles."""
  def __repr__(self):
    """Format useful attributes into a constructor-like call string."""
    return '%s(%s)' % (self.__class__.__name__,
      ', '.join('%s=%r' % (key, getattr(self, key))
        for key in self._repr_attributes if hasattr(self, key)))

  def __del__(self):
    """Automatically close the handle when nothing is referencing it."""
    self.close()

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, traceback):
    self.close()


class MPQFile(_Handle):
  """Simple binary mode read-only file object."""
  # Minimal implementation, similar to the standard file object.
  buffer_size = 256
  buffer = ctypes.create_string_buffer(buffer_size)
  _repr_attributes = ('filename', 'mode', 'handle', 'closed', 'mpq')

  def __init__(self, mpq, filename):
    self.mpq, self.closed = mpq, True
    self.filename, self.mode = filename, 'rb'
    self.handle, self.closed = stormlib.SFileOpenFileEx(mpq.handle, filename.encode('utf_8'),
      scope=stormlib.SFILE_OPEN_FROM_MPQ | stormlib.SFILE_OPEN_PATCHED_FILE), False
    mpq.files[self.handle] = self

  def __len__(self):
    """Return this file's length."""
    return stormlib.SFileGetFileSize(self.handle)

  def __iter__(self):
    return self

  def next(self):
    """Returns this file's next line for iteration."""
    line = self.readline()
    if line:
      return line
    raise StopIteration()

  __close = stormlib.SFileCloseFile
  def close(self):
    """Close this file's resource handle."""
    if not self.closed:
      try:
        self.__close(self.handle)
      finally:
        self.closed = True

  def tell(self):
    """Return this file's current position."""
    return stormlib.SFileSetFilePointer(self.handle, 0, whence=os.SEEK_CUR)

  __seek_long_bits = ctypes.sizeof(ctypes.c_int32) * 8
  __seek_long_mask = 2 ** __seek_long_bits - 1
  __seek_offset_high = ctypes.c_int32()
  def seek(self, offset, whence=os.SEEK_SET):
    """Set this file's current position."""
    MPQFile.__seek_offset_high.value = offset >> MPQFile.__seek_long_bits
    offset = offset & MPQFile.__seek_long_mask
    stormlib.SFileSetFilePointer(self.handle, offset, MPQFile.__seek_offset_high, whence=whence)

  __read_max = 2 ** (ctypes.sizeof(ctypes.c_uint32) * 8) - 1
  def read(self, size=-1):
    """Read file contents up to a maximum of `size` bytes.

    The `size` parameter cannot be larger than a `DWORD`.
    """
    if size > self.__read_max:
      raise ValueError('Read size too large.')
    if size < 0:  # Read rest of file
      size = max(0, len(self) - self.tell())  # tell can return positions beyond EOF
    if size > MPQFile.buffer_size:  # Redimension buffer
      MPQFile.buffer_size, MPQFile.buffer = size, ctypes.create_string_buffer(size)
    bytes_read = stormlib.SFileReadFile(self.handle, MPQFile.buffer, size)
    return ''.join(MPQFile.buffer[:bytes_read])

  def readline(self, size=-1):
    """Read one entire line from this file."""
    if size < 0:  # Read rest of file
      size = len(self) - self.tell()
    bytes = []
    for index in xrange(size):
      byte = self.read(1)
      if not byte:
        break
      else:
        bytes.append(byte)
      if byte == b'\n':
        break
    return ''.join(bytes)

  def readlines(self, sizehint=None):
    """Read the rest of this file into a list of lines using `readline`."""
    return list(self)


class MPQ(_Handle):
  """Simple read-only interface to StormLib's MPQ archive APIs.

  All resources created by an MPQ object are only valid while the MPQ is open.
  Once an MPQ closes, all files will close as well.
  """
  _repr_attributes = ('filename', 'mode', 'locale', 'handle', 'closed')

  def __init__(self, filename, locale=0):
    """Opens the MPQ archive at filename.

    `locale` specifies the numeric country ID from Windows' headers.  It defaults
    to "Neutral/English (American)", which is the only ID used by World of Warcraft.
    """
    self.filename, self.locale, self.closed = filename, locale, True
    self.mode = stormlib.MPQ_OPEN_READ_ONLY | stormlib.MPQ_OPEN_NO_LISTFILE | stormlib.MPQ_OPEN_NO_ATTRIBUTES
    self.files = weakref.WeakValueDictionary()  # Open file handles
    self.handle, self.closed = stormlib.SFileOpenArchive(str(filename), flags=self.mode), False

  def __contains__(self, key):
    if isinstance(key, unicode):
      return self.contains(key)

  __close = stormlib.SFileCloseArchive
  def close(self):
    """Close this MPQ file and all open handles."""
    if not self.closed:
      try:
        # Close all open resources
        for ref in tuple(self.files.itervaluerefs()):
          file = ref()
          if file is not None:
            file.close()
      finally:
        try:
          self.__close(self.handle)
        finally:
          self.closed = True

  def add_patch(self, filename, prefix=''):
    """Overlay another MPQ's contents over this one."""
    stormlib.SFileOpenPatchArchive(self.handle, str(filename), prefix.encode('utf_8'))

  def contains(self, filename):
    """Check if `filename` exists in this MPQ."""
    stormlib.SFileSetLocale(self.locale)
    return stormlib.SFileHasFile(self.handle, filename.encode('utf_8'))

  def open(self, filename):
    """Open a file contained in this MPQ for reading."""
    stormlib.SFileSetLocale(self.locale)
    return MPQFile(self, filename)


def open_locale_mpq(data_path, locale):
  """Open a World of Warcraft locale MPQ with all patches."""
  locale = unicode(locale)
  data_path = os.path.join(os.path.normpath(data_path), locale)
  archive = MPQ(os.path.join(data_path, 'locale-' + locale + '.MPQ'))
  try:
    # Iterate over patch MPQs in revision order
    pattern = re.compile(r'^wow\-update\-' + re.escape(locale) + r'\-(?P<revision>\d+)\.MPQ$', re.IGNORECASE)
    for revision, filename in sorted(
      (int(match.group('revision')), match.string) for match in (
        pattern.match(filename) for filename in os.listdir(data_path)
      ) if match is not None
    ):
      archive.add_patch(os.path.join(data_path, filename), prefix=locale)
  except:
    archive.close()
    raise
  return archive