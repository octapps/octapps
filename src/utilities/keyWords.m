%% Parse optional arguments given as keyword-value pairs
%% Syntax:
%%   keys = keyWords(args, "key1", defval1, "key2", defval2, ...)
%% where:
%%   args    = either a struct:
%%                struct("key1", val1, "key2", val2, ...)
%%             or a cell array:
%%                {"key1", val1, "key2", val2, ...}
%%   "keyN"  = allowed key names, i.e. will throw an error if
%%             args contains a key which is not one of the "keyN"
%%   defvalN = default values, i.e. "keyN" will be assigned the value
%%             defvalN if it is not present in args
%%   keys    = output struct of keyword-value pairs
%% Usage:
%%   function out = someFunc(req1,req2,varargin)
%%      kv = keyWords(varargin, "key1", defval1, "key2", defval2)
%%      % do stuff with req1, req2, kv.key1, kv.key2
%%   endfunction
%%   out = someFunc(req1,req2,"key1",val1);
%%   keys = struct("key2",val2);
%%   out = someFunc(req1,req2,keys);

%%
%%  Copyright (C) 2011 Karl Wette
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function keys = keyWords(args, varargin)

  %% create keyword-value struct
  if isstruct(args)
    keys = args;
  elseif iscell(args)
    keys = struct(args{:});
  else
    error("%s(): invalid input type '%s' to variable 'args'", funcName, typeinfo(args));
  endif

  %% create valid keyword-default value struct
  refkeys = struct(varargin{:});

  %% check that there are no invalid keywords
  names = fieldnames(keys);
  for i = 1:length(names)
    if !isfield(refkeys, names{i})
      error("%s(): invalid keyword '%s'", funcName, names{i});
    endif
  endfor

  %% fill in default values for missing keywords
  names = fieldnames(refkeys);
  for i = 1:length(names)
    if !isfield(keys, names{i})
      keys = setfield(keys, names{i}, getfield(refkeys, names{i}));
    endif
  endfor
  
endfunction
