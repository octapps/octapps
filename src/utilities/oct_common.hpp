//
// Copyright (C) 2013 Karl Wette
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with with program; see the file COPYING. If not, write to the
// Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
// MA  02111-1307  USA
//

#include <string>
#include <map>
#include <octave/oct.h>

// Struct for specifying parseOptions() option specs
typedef struct {
  const char *const name;
  const char *const types;
  const octave_value defvalue;
} OptSpec;

// Use this for the default value of a required options
#define REQUIRED octave_value()

// An OptSpec array *must* be terminated by this value
#define LAST_OPTSPEC {NULL, NULL, octave_value()}

// C++ interface to OctApps parseOptions() function
typedef std::map<std::string, octave_value> OptMap;
OptMap callParseOptions(const octave_value_list& opts, const OptSpec optspecs[]);
