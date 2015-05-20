//
// Copyright (C) 2015 Karl Wette
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

#include <list>
#include <map>
#include <octave/oct.h>
#include <octave/dynamic-ld.h>
#include <octave/ov-usr-fcn.h>
#include <octave/pt-all.h>
#include <octave/Cell.h>

#if OCT_VERS_NUM <= 0x030204
#define octave_map Octave_map
#endif

static const char *const simulateLRUCache_usage = "-*- texinfo -*- \n\
@deftypefn {Loadable Function} {[@var{cache}, @var{max_age}] =} \
simulateLRUCache(@var{cache}, @var{max_age}, @var{requests})\n\
\n\
Simulate the behaviour of an LRU (least recently used) cache.\n\
\n\
@var{cache} contains the current state of the cache, with members \
ordered from most recent to least recent. \
@var{max_age} stores the highest age (starting from 1) achieved by \
any cache item before it is required for re-use; zero indicates that \
no cache item was ever re-used. \
@var{requests} is a list of cache item requests to process.\n\
\n\
All inputs must be of 'uint64' integer type, or empty.\n\
\n\
If the input @var{cache} is empty, the input @var{max_age} is ignored.\n\
@end deftypefn";

DEFUN_DLD( simulateLRUCache, args, nargout, simulateLRUCache_usage ) {

  // Prevent octave from crashing ...
  octave_exit = ::_Exit;

  // Check input and output
  if (args.length() != 3 || nargout != 2) {
    print_usage();
    return octave_value();
  }
  for (octave_idx_type i = 0; i < args.length(); ++i) {
    if (args(i).numel() > 0 && !args(i).is_uint64_type()) {
      error("argument #%i is not of 'uint64' integer type", i+1);
      return octave_value();
    }
  }

  // Get input arguments
  uint64NDArray cache_in = args(0).uint64_array_value();
  octave_uint64 max_age = 0;
  if (cache_in.numel() > 0) {
    max_age = args(1).uint64_scalar_value();
  }
  uint64NDArray requests = args(2).uint64_array_value();

  // Load cache from input
  std::list<octave_uint64> cache;
  for (octave_idx_type i = 0; i < cache_in.numel(); ++i) {
    cache.push_back(cache_in(i));
  }

  // Process requests
  for (octave_idx_type i = 0; i < requests.numel(); ++i) {

    // Look for request in cache
    std::list<octave_uint64>::iterator elem = cache.begin();
    for (size_t age = 1; age <= cache.size(); ++age, ++elem) {
      if (*elem != requests(i)) {
        continue;
      }

      // Calculate maximum age achieved by this request in cache
      if (max_age.value() < age) {
        max_age = age;
      }

      // Remove request from cache
      cache.erase(elem);

      break;
    }

    // Add request to front of cache
    cache.push_front(requests(i));

  }

  // Save cache to output
  dim_vector dv(2, 1);
  dv(0) = 1;
  dv(1) = cache.size();
  uint64NDArray cache_out(dv);
  {
    std::list<octave_uint64>::iterator elem = cache.begin();
    for (size_t i = 0; i < cache.size(); ++i, ++elem) {
      cache_out(i) = *elem;
    }
  }

  // Return output arguments
  octave_value_list argout;
  argout.append(octave_value(cache_out));
  argout.append(octave_value(max_age));
  return argout;

}

/*

%!test
%!  cache = max_age = [];
%!  [cache, max_age] = simulateLRUCache(cache, max_age, []);
%!  assert(length(cache) == 0);
%!  assert(max_age == 0);

%!test
%!  cache = max_age = [];
%!  [cache, max_age] = simulateLRUCache(cache, max_age, uint64(0:10));
%!  assert(all(cache == uint64(10:-1:0)));
%!  assert(max_age == 0);
%!  [cache, max_age] = simulateLRUCache(cache, max_age, uint64(0:10));
%!  assert(all(cache == uint64(10:-1:0)));
%!  assert(max_age == 11);
%!  [cache, max_age] = simulateLRUCache(cache, max_age, uint64(0:10));
%!  assert(all(cache == uint64(10:-1:0)));
%!  assert(max_age == 11);

%!test
%!  cache = max_age = [];
%!  for i = 0:4
%!    [cache, max_age] = simulateLRUCache(cache, max_age, uint64(i:i+4));
%!    assert(all(cache == uint64(i+4:-1:0)));
%!    if i == 0
%!      assert(max_age == 0);
%!    else
%!      assert(max_age == 4);
%!    endif
%!  endfor

%!test
%!  cache = max_age = [];
%!  requests = uint64(randi([0, 100], [1, 10]));
%!  for i = 1:length(requests)
%!    [cache, max_age] = simulateLRUCache(cache, max_age, requests(i));
%!    assert(cache(1) == requests(i));
%!  endfor

%!test
%!  cache = max_age = [];
%!  requests = uint64([5, 1, 3, 7, 4, 1, 1, 10, 2, 5, 1, 9, 3, 0, 1, 4, 2, 0, 4, 0]);
%!  final_cache = uint64([0, 4, 2, 1, 3, 9, 5, 10, 7]);
%!  [cache, max_age] = simulateLRUCache(cache, max_age, requests);
%!  assert(all(cache == final_cache));

%!test
%!  cache = max_age = [];
%!  requests = uint64([5, 1, 3, 7, 4, 1, 1, 10, 2, 5, 1, 9, 3, 0, 1, 4, 2, 0, 4, 0]);
%!  max_ages = uint64([0, 0, 0, 0, 0, 4, 4, 4, 4, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8]);
%!  final_cache = uint64([0, 4, 2, 1, 3, 9, 5, 10, 7]);
%!  for i = 1:length(requests)
%!    [cache, max_age] = simulateLRUCache(cache, max_age, requests(i));
%!    assert(max_age == max_ages(i));
%!  endfor
%!  assert(all(cache == final_cache));

*/
