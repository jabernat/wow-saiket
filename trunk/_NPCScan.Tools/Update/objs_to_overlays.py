# -*- coding: utf_8 -*-
"""Joins Wavefront *.obj model files into a binary data file for _NPCScan.Overlay.

Instructions:
1. Run <routes_to_objs.py> to build a folder of map area sub-folders with NPC
   *.obj files from outlines in your Routes saved variables.
2. Run this script with relevant file paths to pack resulting *.obj files into
   a Lua source file for _NPCScan.Overlay.
"""

import bisect
import codecs
import os
import re
import struct

import p2t as poly2tri

import wowdata.lua

__author__ = 'Saiket'
__email__ = 'saiket.wow@gmail.com'
__license__ = 'GPL'

class ObjError(Exception):
  """Error raised when an *.obj file couldn't be parsed."""
  pass


class Overlay(object):
  """Represents an *.obj file containing geometry for an NPC."""
  OBJ_VERTEX = 'V'
  OBJ_POINT = 'P'
  OBJ_LINE = 'L'
  OBJ_POLYGON = 'F'  # Face

  def __init__(self, filename):
    """Parses the *.obj at `filename` for an NPC's geometry information."""
    vertices, polygons = [], []
    self.points, self.lines, self.triangles = [], [], []

    def get_vertex(word):
      """Returns the vertex corresponding to index `word` in `vertices`."""
      try:
        index = int(word)
        return vertices[index - 1]  # Vertex indices are 1-based in *.objs
      except ValueError:
        raise ObjError('Encountered non-numeric vertex index {!r}.'.format(word))
      except IndexError:
        raise ObjError('Vertex index {:d} out of range.'.format(index))

    with codecs.open(filename, encoding='utf_8') as input:
      for statement in input:
        words = statement.split()
        if words:
          operator = words.pop(0).upper()
          if operator == self.OBJ_VERTEX:
            if len(words) == 3:
              try:
                coordinates = tuple(map(float, words[:2]))  # Discard Z-coordinate
              except ValueError:
                raise ObjError('Encountered non-numeric coordinate in vertex.')
              if not all(0 <= coordinate and coordinate <= 1 for coordinate in coordinates):
                raise ObjError('Coordinate out of bounds [0, 1]: {!r}.'.format(coordinates))
              vertices.append(coordinates)

          elif operator == self.OBJ_POINT:
            if len(words) == 1:
              self.points.append(get_vertex(word))

          elif operator == self.OBJ_LINE:
            if len(words) >= 2:
              line = tuple(map(get_vertex, words))
              for index in xrange(len(line) - 1):
                self.lines.append((line[index], line[index + 1]))

          elif operator == self.OBJ_POLYGON:
            if len(words) >= 3:
              polygons.append(
                self.Polygon(get_vertex(word) for word in words))

    # Join and triangulate polygons
    if self.Polygon.any_intersections(polygons):
      raise ObjError('Polygons cannot overlap with themselves or each other.')
    top_level = []
    polygons.sort(key=lambda polygon: polygon.get_area())
    while polygons:
      smallest = polygons.pop(0)
      for current in polygons:
        # Either entirely inside or outside, so only check one point
        if current.contains_point(smallest[0]):
          current.children.append(smallest)
          smallest = None
          break
      if smallest:  # No containing polygon
        top_level.append(smallest)
    self._triangulate_polygons(top_level)

  _DWORD = '>I'
  _COORD = '>H'  # Unsigned short
  _COORD_MAX = 2 ** (8 * struct.calcsize(_COORD)) - 1  # Max value for packed coordinates
  _VERTEX_LENGTH = struct.calcsize(_COORD) * 2
  def pack(self):
    """Returns a binary representation of this NPC's map area geometry."""
    bytes = []
    def pack_vertices(bytes, vertices):
      """Packs coordinates from `vertices` into `bytes`."""
      for vertex in vertices:
        for coordinate in vertex:
          bytes.append(struct.pack(self._COORD, round(coordinate * self._COORD_MAX)))

    points_offset = struct.calcsize(self._DWORD) * 3
    lines_offset = points_offset + self._VERTEX_LENGTH * len(self.points)
    triangles_offset = lines_offset + 2 * self._VERTEX_LENGTH * len(self.lines)
    bytes.append(struct.pack(self._DWORD, points_offset))
    bytes.append(struct.pack(self._DWORD, lines_offset))
    bytes.append(struct.pack(self._DWORD, triangles_offset))

    pack_vertices(bytes, self.points)
    for line in self.lines:
      pack_vertices(bytes, line)
    for triangle in self.triangles:
      pack_vertices(bytes, triangle)
    return ''.join(bytes)

  def _triangulate_polygons(self, polygons):
    for polygon in polygons:
      cdt = poly2tri.CDT([poly2tri.Point(*vertex) for vertex in polygon])  # Constrained Delaunay Triangulation
      for child in polygon.children:
        cdt.add_hole([poly2tri.Point(*vertex) for vertex in child])
        self._triangulate_polygons(child.children)
      for triangle in cdt.triangulate():
        self.triangles.append((
          (triangle.a.x, triangle.a.y),
          (triangle.b.x, triangle.b.y),
          (triangle.c.x, triangle.c.y)))

  class Polygon(list):
    """Represents a polygonal geometric area with nested child `Polygon`s."""
    def __init__(self, *args, **kwargs):
      super(type(self), self).__init__(*args, **kwargs)
      self.left, self.top, self.right, self.bottom = _bounding_box(self)
      self.children = []

    def contains_point(self, point):
      """Returns ``True`` if `point` is contained within this `Polygon`."""
      if point[0] <= self.left or self.right <= point[0] or point[1] <= self.bottom or self.top <= point[1]:
        return False  # Outside of bounding box
      winding, line = 0, None
      for vertex in self:
        line = self.Line((line[1] if line else self[-1], vertex))
        if line[0][1] <= point[1]:  # Starts below point
          if line[1][1] > point[1]:  # Crossed upwards
            if line.distance_to_point(point) < 0:  # Intersects right of x
              winding += 1
        elif line[1][1] <= point[1]:  # Crossed downwards
          if line.distance_to_point(point) > 0:  # Intersects right of x
            winding -= 1
      return winding > 0

    def get_area(self):
      """Returns the area of this polygon."""
      area, last_vertex = 0, self[-1]
      for vertex in self:
        area += last_vertex[0] * vertex[1] - vertex[0] * last_vertex[1]
        last_vertex = vertex
      return abs(area / 2)

    @classmethod
    def any_intersections(cls, polygons):
      """Returns ``True`` if any `Polygon` in `polygons` intersect with themselves or each other."""
      endpoints = []
      for polygon in polygons:
        last_vertex = polygon[-1]
        for vertex in polygon:
          if vertex < last_vertex:
            line = cls.Line((vertex, last_vertex))
          else:  # Change direction to match iteration order
            line = cls.Line((last_vertex, vertex))
          endpoints.extend(line)
          last_vertex = vertex
      # Order end-points bottom to top, left to right (read in reverse)
      endpoints.sort(reverse=True)

      sweep_line = cls.SweepLine()
      while endpoints:
        endpoint = endpoints.pop()
        if endpoint.is_start():
          if not sweep_line.insert_line(endpoint.line):  # New line intersected its neighbors
            return True
        elif not sweep_line.remove_line(endpoint.line):  # Ending line left an intersection
          return True

    class SweepLine(list):
      """Represents a sorted collection of lines crossing the current x-coordinate."""
      def _line_neighbors(self, index):
        """Returns the lines immediately before and after `index` in this `SweepLine`, if they exist."""
        return index - 1 >= 0 and self[index - 1], index + 1 < len(self) and self[index + 1]

      def insert_line(self, line):
        """Adds `line` to this `SweepLine`, and returns ``True`` if it didn't intersect anything."""
        index = bisect.bisect(self, line)
        self.insert(index, line)
        before, after = self._line_neighbors(index)
        return not (line.intersects(after) or line.intersects(before))

      def remove_line(self, line):
        """Removes `line` to this `SweepLine`, and returns ``True`` if it didn't leave an intersection."""
        index = bisect.bisect_left(self, line)
        if index == len(self) or self[index] != line:
          raise ValueError(line)
        before, after = self._line_neighbors(index)
        self.pop(index)
        return not (after and after.intersects(before))

    class Line(list):
      """Represents a two-dimensional line."""
      __slots__ = ()

      def __init__(self, iterator, *args, **kwargs):
        super(type(self), self).__init__(
          (self.EndPoint(vertex, line=self) for vertex in iterator), *args, **kwargs)

      def distance_to_point(self, point):
        """Returns the perpendicular distance from this line's right side to `point`."""
        return (point[0] - self[0][0]) * (self[1][1] - self[0][1]) \
          - (self[1][0] - self[0][0]) * (point[1] - self[0][1])

      def intersects(self, line):
        """Returns ``True`` if this `Line` intersects with other segment `line`."""
        if line:
          if (self.distance_to_point(line[0]) * self.distance_to_point(line[1]) < 0
            and line.distance_to_point(self[0]) * line.distance_to_point(self[1]) < 0
          ):
            return True  # Lines crossed each other

      class EndPoint(list):
        """Represents a `Line`'s end-point."""
        __slots__ = ('line')

        def __init__(self, *args, **kwargs):
          self.line = kwargs.pop('line')  # Required keyword-only argument
          super(type(self), self).__init__(*args, **kwargs)

        def is_start(self):
          """Returns ``True`` if this `Line.EndPoint` is the start of `Line`."""
          return self is self.line[0]


def _bounding_box(vertices):
  """Returns the bounding box containing `vertices` as (`left`, `top`, `right`, `bottom`)."""
  x_coords, y_coords = zip(*vertices)
  return min(x_coords), max(y_coords), max(x_coords), min(y_coords)

def write(output_filename, input_path):
  """Reads *.obj files from an input folder and packs them into a Lua source file."""
  output_filename = os.path.normcase(output_filename)
  input_path = os.path.normcase(unicode(input_path))
  print 'Packing *.obj files from <{:s}> to <{:s}>...'.format(input_path, output_filename)

  map_areas = {}
  map_area_match = re.compile(r'^maparea-(?P<id>\d+)$', flags=re.IGNORECASE).match
  for map_area_id, folder in sorted(
    (int(match.group('id')), match.string) for match
      in map(map_area_match, os.listdir(input_path))
      if match and os.path.isdir(os.path.join(input_path, match.string))
  ):
    print '\t{:s}'.format(folder)
    folder = os.path.join(input_path, folder)
    map_areas[map_area_id] = {}
    npc_match = re.compile(r'^npc-(?P<id>\d+)\.obj$', flags=re.IGNORECASE).match
    for npc_id, filename in sorted(
      (int(match.group('id')), match.string) for match
        in map(npc_match, os.listdir(folder))
        if match and os.path.isfile(os.path.join(folder, match.string))
    ):
      print '\t\t{:s}'.format(filename)
      map_areas[map_area_id][npc_id] = Overlay(os.path.join(folder, filename))

  print '\tWriting geometry...'
  with open(output_filename, 'w+b') as output:
    output.write('-- AUTOMATICALLY GENERATED BY <{:s}>!\n'.format(__file__.encode('utf_8')))
    output.write('select( 2, ... ).PathData = {\n')
    for map_area_id, npc_overlays in sorted(map_areas.iteritems()):
      output.write('\t[ {:d} ] = {{\n'.format(map_area_id))
      for npc_id, overlay in npc_overlays.iteritems():
        output.write('\t\t[ {:d} ] = {:s};\n'.format(
          npc_id, wowdata.lua.escape_data(overlay.pack())))
      output.write('\t};\n')
    output.write('};')


if __name__ == '__main__':
  import argparse
  parser = argparse.ArgumentParser(
    description='Convert *.obj models to a Lua source file for _NPCScan.Overlay.',
    epilog=''.join((__doc__ or '').splitlines(True)[2:]),  # Duplicate file docstring's instructions
    formatter_class=argparse.RawDescriptionHelpFormatter)
  parser.add_argument('input_path', type=unicode,
    help='Path containing *.obj models generated by routes_to_objs.py.')
  parser.add_argument('output_filename', type=unicode,
    help='Output path for the resulting Lua source file.')
  write(**vars(parser.parse_args()))