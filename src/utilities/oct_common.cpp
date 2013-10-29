//
//  Copyright (C) 2013 Karl Wette
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with with program; see the file COPYING. If not, write to the
//  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
//  MA  02111-1307  USA
//

#include "utilities/oct_common.hpp"
#include <octave/parse.h>
#include <octave/oct-map.h>

// For Octave 3.2.4 compatibility
#ifndef OCTAVE_API_VERSION_NUMBER
#define OCTAVE_API_VERSION_NUMBER 0
#endif
#if OCTAVE_API_VERSION_NUMBER < 40
#define octave_map Octave_map
#endif

OptMap callParseOptions(const octave_value_list& opts, const OptSpec optspecs[]) {

  // Create argument list for parseOptions()
  octave_value_list args;
  args.append(octave_value(Cell(opts)));
  for (size_t i = 0; optspecs[i].name != NULL; ++i) {
    octave_value_list spec;
    spec.append(octave_value(optspecs[i].name));
    spec.append(octave_value(optspecs[i].types));
    if (optspecs[i].defvalue.is_defined()) {
      spec.append(optspecs[i].defvalue);
    }
    args.append(octave_value(Cell(spec)));
  }

  // Call parseOptions() and return parsed options
  octave_value_list retn = feval("parseOptions", args, 1);
  if (retn.length() != 1 || !retn(0).is_map()) {
    return OptMap();
  }
  octave_map octmap = retn(0).map_value();
  OptMap map;
  for (octave_map::const_iterator i = octmap.begin(); i != octmap.end(); ++i) {
    map[octmap.key(i)] = octave_value(octmap.contents(i)(0));
  }
  return map;

}
