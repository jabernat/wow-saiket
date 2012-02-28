# -*- coding: utf_8 -*-
"""DBC files are a simple database format for Blizzard games.

DBC columns have no names or declared types; code must know what types to extract
from where.  See <http://wiki.nibbits.com/wiki/Category:World_of_Warcraft_DBC_Files>
for documentation on the file format.
"""

import os
import struct
import weakref

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'LGPL'

class DBCError(Exception):
  """Base class of DBC errors."""
  pass

class DBCFormatError(DBCError):
  """Used when a file's header can't be parsed as a DBC."""
  pass

class DBCRangeError(DBCError):
  """Used when the position arguments are outside the DBC's data table."""
  pass

class DBCStringError(DBCError):
  """Used when a string field can't properly be read from the string block."""
  pass

class DBCUnsupportedError(DBCError):
  """Used when the DBC file doesn't support the failed action."""
  pass


def _Repr(self):
  """Format useful attributes from this object into a constructor-like call string."""
  return '%s(%s)' % (self.__class__.__name__,
    ', '.join('%s=%r' % (key, getattr(self, key))
      for key in self._reprAttributes if hasattr(self, key)))


class DBCRow(object):
  """DBC table row object."""
  _reprAttributes = ('index', 'dbc')
  __repr__ = _Repr

  def __init__(self, dbc, row):
    self.dbc, self.index = dbc, row
    dbc._rows[row] = self

  def __len__(self):
    return self.dbc.columnCount

  def int(self, column):
    """Extract a signed integer from a field."""
    return struct.unpack('<i', self.dbc._getFieldData(self.index, column))[0]

  def float(self, column):
    """Extract a float from a field."""
    return struct.unpack('<f', self.dbc._getFieldData(self.index, column))[0]

  def char(self, column):
    """Extract a single byte from a field."""
    return self.dbc._getFieldData(self.index, column, 1)

  def bool(self, column):
    """Extract a bool from the first byte of a field."""
    return struct.unpack('<?', self.char(self.index, column))[0]

  def flags(self, column):
    """Extract a bitfield from a field as a string."""
    return self.dbc._getFieldData(self.index, column, self.dbc.columnSize)

  def str(self, column):
    """Extract a string value from a field."""
    # Offset from start of string block
    offset = struct.unpack('<I', self.dbc._getFieldData(self.index, column))[0]
    return self.dbc._getStringData(offset)


class DBC(object):
  """Opens a DBC file for parsing.  Files must be in binary mode.

  Data is read when requested, and no assumptions about column data type are made.
  File object *must* be opened in binary mode if available.
  """
  _INT_SIZE = struct.calcsize('=i')
  _HEADER_SIZE = _INT_SIZE * 5
  _reprAttributes = ('file', 'closed')
  __repr__ = _Repr

  def __init__(self, file, *keys, **kwkeys):
    self.file, self.closed = file, False
    self._rows, self.keys = weakref.WeakValueDictionary(), {}
    # Parse DBC file header.
    try:
      file.seek(0, os.SEEK_END)
      size = file.tell()
      file.seek(0)
      if file.read(4) != 'WDBC':  # Magic
        raise DBCFormatError('Invalid DBC file signature.')
      self.rowCount, self.columnCount = struct.unpack('<II', file.read(DBC._INT_SIZE * 2))
      self.rowSize = struct.unpack('<I', file.read(DBC._INT_SIZE))[0]
      self.columnSize = self.rowSize / self.columnCount

      self._stringBlockStart = DBC._HEADER_SIZE + self.rowSize * self.rowCount
      self._stringBlockSize = struct.unpack('<I', file.read(DBC._INT_SIZE))[0]
      sizeExpected = self._stringBlockStart + self._stringBlockSize
      if size != sizeExpected:
        raise DBCFormatError('Calculated size mismatch: %d != expected %d bytes.'
          % (size, sizeExpected))
      self.setKeys(*keys, **kwkeys)
    except:  # Invalid header; Abort
      self.close()
      raise

  def __len__(self):
    return self.rowCount

  def __getitem__(self, index):
    """Gets a table row object to access its element data."""
    if not isinstance(index, (int, long)):
      raise TypeError(index)
    if not 0 <= index < self.rowCount:
      raise IndexError(index)
    if index in self._rows:
      return self._rows[index]
    else:
      return DBCRow(self, index)

  def __iter__(self):
    """Iterates over each of this DBC's rows, in order."""
    for index in xrange(self.rowCount):
      yield self[index]

  def __del__(self):
    self.close()

  def __enter__(self):
    return self

  def __exit__(self, exc_type, exc_value, traceback):
    self.close()

  def close(self):
    """Closes the underlying file representing this DBC."""
    if not self.closed:
      try:
        self.file.close()
      finally:
        self.closed = True

  def _seekToField(self, row, column):
    """Seek to a field within the DBC's row data."""
    if isinstance(column, basestring):  # Named column
      column = self.keys[column]
    if not 0 <= row < self.rowCount:
      raise DBCRangeError('Row %d out of bounds [0, %d).'
        % (row, self.rowCount))
    if not 0 <= column < self.columnCount:
      raise DBCRangeError('Column %d out of bounds [0, %d).'
        % (column, self.columnCount))
    self.file.seek(DBC._HEADER_SIZE + row * self.rowSize + column * self.columnSize)

  def _getFieldData(self, row, column, size=_INT_SIZE):
    """Seek to a field and retrieve int-sized binary data.

    The DBC's columnSize must be wide enough to hold size bytes.
    """
    if size > self.columnSize:
      raise DBCUnsupportedError('DBC column size %d too small to contain %d-byte field.'
        % (self.columnSize, size))
    self._seekToField(row, column)
    return self.file.read(size)

  def _getStringData(self, offset):
    """Retrieve a null-terminated string value from the string block."""
    if offset >= self._stringBlockSize:
      raise DBCStringError('String offset %d out of bounds [0, %d).'
        % (offset, self._stringBlockSize))

    # Read null-terminated string
    self.file.seek(offset + self._stringBlockStart)
    bytes = []
    while True:
      byte = self.file.read(1)
      if not byte:
        raise DBCStringError('Unexpected end of string block.')
      if byte != '\x00':
        bytes.append(byte)
      else:
        return ''.join(bytes).decode('utf_8')

  def setKeys(self, *keys, **kwkeys):
    """Assigns string names to columns for easier access.

    Columns with omitted keys or keys set to None will not be assigned names.
    """
    if len(keys) > self.columnCount:
      raise DBCUnsupportedError('Too many column keys in list (got %d, max of %d).'
        % (len(keys), self.columnCount))
    for key in keys:
      if key is not None and not isinstance(key, basestring):
        raise TypeError('Keys in args must be strings.')
    for key in kwkeys:
      if not isinstance(key, basestring):
        raise TypeError('Keys in kwargs must be strings.')
      if not 0 <= kwkeys[key] < self.columnCount:
        raise DBCUnsupportedError('Column index %d out of bounds [0, %d) in kwargs.'
          % (kwkeys[key], self.columnCount))

    self.keys.clear()
    self.keys.update((
      (key, index) for index, key in enumerate(keys) if key is not None
      ), **kwkeys)