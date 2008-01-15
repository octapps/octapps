%% plot a given SFT and return its meta-info (header) and data as a struct:
%% ret = {version; epoch; Tsft; f0; Band; SFTdata }
%%
%% C-type: of v1 SFTs:
%% typedef struct tagSFTHeader {
%% REAL8  version;		/* SFT version-number (currently only 1.0 allowed )*/
%% INT4   gpsSeconds;		/* gps start-time */
%% INT4   gpsNanoSeconds;
%% REAL8  timeBase;		/* length of data-stretch in seconds */
%% INT4   fminBinIndex;	/* first frequency-index contained in SFT */
%% INT4   length;  		/* number of frequency bins */
%%
%% /* v2-specific part: */
%% INT8 crc64;		/* 64 bits */
%% CHAR detector[2];
%% CHAR padding[2];
%% INT comment_length;
%% } SFTHeader;
%% CHAR[comment_length] comment;
%%

%%
%% Copyright (C) 2006 Reinhard Prix
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

function ret = plotSFT(fname)

  if ( (fid = fopen (fname, "rb")) == -1 )
    error ("Could not open SFT-file '%s'.", fname )
  endif

  [ret.version, count] = fread (fid, 1, "real*8");
  if ( count != 1 )
    error ("Error reading version-info from SFT!");
  elseif ( (ret.version != 1.0) && (ret.version != 2.0) )
    error ("Only SFTs v1 or v2 are supported right now! Version was: %f!", ret.version);
  endif

  [ ret.epoch.gpsSeconds, count ] = fread ( fid, 1, "int32" );
  if ( count != 1 ) error ("Error reading header-info 'gpsSeconds' from SFT-file '%s'", fname); endif

  [ ret.epoch.gpsNanoSeconds, count ] = fread ( fid, 1, "int32" );
  if ( count != 1 ) error ("Error reading header-info 'gpsNanoSeconds' from SFT-file '%s'", fname); endif

  [ ret.Tsft, count ] = fread ( fid, 1, "real*8" );
  if ( count != 1 ) error ("Error reading header-info 'Tsft' from SFT-file '%s'", fname); endif

  [ fminBinIndex, count ] = fread ( fid, 1, "int32" );
  if ( count != 1 ) error ("Error reading header-info 'fminBinIndex' from SFT-file '%s'", fname); endif

  [ SFTlen, count ] = fread ( fid, 1, "int32" );
  if ( count != 1 ) error ("Error reading header-info 'length' from SFT-file '%s'", fname); endif

  if ( ret.version == 2 )
    [ crc64, count ] = fread ( fid, 1, "int64" );
    if ( count != 1 ) error ("Error reading header-info 'crc64' from SFTv2-file '%s'", fname); endif

    [ IFO, count ] = fread ( fid, 2, "uchar" );
    if ( count != 2 ) error ("Error reading header-info 'IFO' from SFTv2-file '%s'", fname); endif
    ret.IFO = char ( IFO' );

    [ padding, count ] = fread ( fid, 2, "uchar" );
    if ( count != 2 ) error ("Error reading header-info 'padding' from SFTv2-file '%s'", fname); endif

    [ commentLen, count ] = fread ( fid, 1, "int32" );
    if ( count != 1 ) error ("Error reading header-info 'comment-len' from SFTv2-file '%s'", fname); endif

    [ comment, count ] = fread ( fid, commentLen, "uchar" );
    if ( count != commentLen ) error ("Error reading comment-string from SFTv2-file '%s'", fname); endif
    ret.comment = char ( comment' );
  endif %% if version 2

  dfreq = 1.0 / ret.Tsft;
  ret.f0 = fminBinIndex * dfreq;
  ret.Band = (SFTlen-1) * dfreq;

  [ rawdata, count ] = fread ( fid, [2, SFTlen], "real*4" );
  if ( count != SFTlen*2 )
    error ("Inconsistent data-length (%d) and length-info (%d) in header in '%s'.", count, SFTlen, fname );
  endif
  fclose(fid);

  %% SFT normalization
  dt = ret.Tsft / (2 * SFTlen );
  if ( ret.version == 1.0 )
    rawdata *= dt;
  endif

  ret.SFTdata = rawdata';

  %% now plot psd of SFT-data
  periodo = sqrt ( ret.SFTdata(:,1).^2 .+ ret.SFTdata(:,2).^2 );

  psd = sqrt(2 * dfreq) * periodo;

  fE = ret.f0 + ret.Band;
  ret.freqs = ret.f0:dfreq:fE;

  axis([ret.f0,fE]);
  plot ( ret.freqs, psd );


endfunction
