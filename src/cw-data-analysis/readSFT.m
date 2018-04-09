## Copyright (C) 2006 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{ret} =} readSFT ( @var{fname} )
##
## read a given SFT-file and return its meta-info (header) and data as a struct:
## ret = @{version; epoch; Tsft; f0; Band; SFTdata @}
##
## @heading C-type of SFTs
##
## @verbatim
## typedef struct tagSFTHeader {
##    REAL8  version;              /* SFT version-number (currently only 1.0 allowed )*/
##    INT4   gpsSeconds;           /* gps start-time */
##    INT4   gpsNanoSeconds;
##    REAL8  timeBase;             /* length of data-stretch in seconds */
##    INT4   fminBinIndex;         /* first frequency-index contained in SFT */
##    INT4   length;               /* number of frequency bins */
##
##    /* v2-specific part: */
##    INT8 crc64;                  /* 64 bits */
##    CHAR detector[2];
##    CHAR padding[2];
##    INT comment_length;
## } SFTHeader;
## CHAR[comment_length] comment;
## @end verbatim
##
## @end deftypefn

function ret = readSFT(fname)

  fid = fopen(fname, 'rb');
  if ( fid == -1 )
    error ('Could not open SFT-file ''%s''.', fname )
  end

  [header.version, count] = fread (fid, 1, 'real*8');
  if ( count ~= 1 )
    error ('Error reading version-info from SFT!');
  elseif ( (header.version ~= 1.0) && (header.version ~= 2.0) )
    error ('Only SFTs v1 or v2 are supported right now! Version was: %f!', header.version);
  end

  [ header.epoch.gpsSeconds, count ] = fread ( fid, 1, 'int32' );
  if ( count ~= 1 ) error ('Error reading header-info ''gpsSeconds'' from SFT-file ''%s''', fname); end

  [ header.epoch.gpsNanoSeconds, count ] = fread ( fid, 1, 'int32' );
  if ( count ~= 1 ) error ('Error reading header-info ''gpsNanoSeconds'' from SFT-file ''%s''', fname); end

  [ header.Tsft, count ] = fread ( fid, 1, 'real*8' );
  if ( count ~= 1 ) error ('Error reading header-info ''Tsft'' from SFT-file ''%s''', fname); end

  [ fminBinIndex, count ] = fread ( fid, 1, 'int32' );
  if ( count ~= 1 ) error ('Error reading header-info ''fminBinIndex'' from SFT-file ''%s''', fname); end

  [ SFTlen, count ] = fread ( fid, 1, 'int32' );
  if ( count ~= 1 ) error ('Error reading header-info ''length'' from SFT-file ''%s''', fname); end

  if ( header.version == 2 )
    [ crc64, count ] = fread ( fid, 1, 'int64' );
    if ( count ~= 1 ) error ('Error reading header-info ''crc64'' from SFTv2-file ''%s''', fname); end

    [ IFO, count ] = fread ( fid, 2, 'uchar' );
    if ( count ~= 2 ) error ('Error reading header-info ''IFO'' from SFTv2-file ''%s''', fname); end
    header.IFO = char ( IFO' );

    [ padding, count ] = fread ( fid, 2, 'uchar' );
    if ( count ~= 2 ) error ('Error reading header-info ''padding'' from SFTv2-file ''%s''', fname); end

    [ commentLen, count ] = fread ( fid, 1, 'int32' );
    if ( count ~= 1 ) error ('Error reading header-info ''comment-len'' from SFTv2-file ''%s''', fname); end

    [ comment, count ] = fread ( fid, commentLen, 'uchar' );
    if ( count ~= commentLen ) error ('Error reading comment-string from SFTv2-file ''%s''', fname); end
    header.comment = char ( comment' );
  end ## if version 2

  dfreq = 1.0 / header.Tsft;
  header.f0 = fminBinIndex * dfreq;
  header.Band = (SFTlen-1) * dfreq;

  [ rawdata, count ] = fread ( fid, [2, SFTlen], 'real*4' );
  if ( count ~= SFTlen*2 )
    error ('Inconsistent data-length (%d) and length-info (%d) in header in ''%s\''.', count, SFTlen, fname );
  end
  fclose(fid);

  ## SFT normalization
  dt = header.Tsft / (2 * SFTlen );
  if ( header.version == 1.0 )
    rawdata = rawdata * dt;
  end

  ret.header = header;
  ret.SFTdata = rawdata';

  ## now estimate psd of SFT-data
  periodo = sqrt ( ret.SFTdata(:,1).^2 + ret.SFTdata(:,2).^2 );

  ret.psd = sqrt(2 * dfreq) * periodo;

  fE = header.f0 + header.Band;
  ret.freqs = header.f0:dfreq:fE;

end

%!test
%!  sft = readSFT(fullfile(fileparts(file_in_loadpath("readSFT.m")), "SFT-good"));
