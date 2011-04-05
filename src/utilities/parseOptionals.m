%% Parse optional arguments followed by keyword-value pairs
%% Syntax:
%%   [kv, opt, ...] = parseOptionals(args, "key", defval, ...)
%%   [kv, opt, ...] = parseOptionals(args, "...", refkv)
%% where:
%%   args   = {opt, ..., "key", val, ...}
%%            {opt, ..., "...", kv, "key", val, ...}
%%   "key"  = allowed key names, i.e. will throw an error if
%%            args contains a key which is not one of the "key"s
%%   "..."  = special key name, use value to initialise kv or
%%            specify refkey = struct("key", defval, ...)
%%   defval = default values, i.e. a "key" will be assigned the value
%%            defval if it is not present in args
%%   kv     = input/output struct of keyword-value pairs
%%   opt    = output optional arguments, [] if not present
%% Usage:
%%   function out = someFunc(req1,req2,opt,varargin)
%%      [kv,opt] = parseOptionals(varargin,"key1",defval1,"key2",defval2)
%%      % do stuff with req1, req2, opt, kv.key1, kv.key2
%%   endfunction
%%   out = someFunc(req1,req2,opt,"key1",val1); % "key2"=defval2
%%   out = someFunc(req1,req2,"key1",val1);     % opt=[],"key2"=defval2
%%   kv = struct("key2",val2);
%%   out = someFunc(req1,req2,"...",keys);

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

function [kv, varargout] = parseOptionals(args, varargin)

  %% separate optional arguments from keyword-value pairs
  [varargout, keyvals] = parseparams(args);

  %% check number of optional arguments
  if length(varargout) > nargout - 1
    error("%s(): too many optional arguments", funcName);
  endif

  %% set optional arguments to [] if not given
  [varargout{end+1:nargout-1}] = deal([]);

  %% create keyword-value struct
  if length(keyvals) >= 2 && strcmp(keyvals{1}, "...")
    kv = keyvals{2};
    if !isstruct(kv)
      error("%s(): special '...' key expects a struct argument", funcName)
    endif
    keyvals = keyvals(3:end);
  else
    kv = struct();
  endif
  newkv = struct(keyvals{:});
  kv = struct([[fieldnames(kv);fieldnames(newkv)],\
               [struct2cell(kv);struct2cell(newkv)]]'{:});

  %% create valid keyword-default value struct
  if length(varargin) == 2 && strcmp(varargin{1}, "...")
    refkv = varargin{2};
    if !isstruct(refkv)
      error("%s(): special '...' key expects a struct argument", funcName)
    endif
  else
    refkv = struct(varargin{:});
  endif

  %% check that there are no invalid keywords
  keys = fieldnames(kv);
  validkeys = cellfun(@(x)isfield(refkv,x),keys);
  if !all(validkeys)
    error("%s(): invalid keywords:%s", funcName, sprintf(" '%s'", keys(!validkeys){:}));
  endif

  %% fill in default values for missing keywords
  kv = struct([[fieldnames(refkv);fieldnames(kv)],\
               [struct2cell(refkv);struct2cell(kv)]]'{:});
  
endfunction
