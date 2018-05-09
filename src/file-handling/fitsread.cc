//
// Copyright (C) 2012 Karl Wette
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

#include <cstdlib>
#include <string>
#include <algorithm>

#include <octave/oct.h>
#if OCTAVE_VERSION_HEX >= 0x040200
#include <octave/interpreter.h>
#else
#include <octave/toplev.h>
#endif

#if OCTAVE_VERSION_HEX <= 0x030204
#define octave_map Octave_map
#endif

#include <fitsio.h>

extern "C" int fffree(void*, int *);

static const char *const fitsread_usage = "-*- texinfo -*- \n\
@deftypefn {Loadable Function} {@var{data} =} fitsread(@var{filename})\n\
\n\
Load data from a FITS (Flexible Image Transport System) file.\n\
\n\
@example\n\
data = fitsread(\"results.fits\");             # Load all data in \"results.fits\"\n\
data = fitsread(\"results.fits[table1]\");     # Load only the table \"table1\" in \"results.fits\"\n\
@end example\n\
\n\
@end deftypefn";

// Transform FITS header keyword into either (lowercase) alphanumeric
// characters or '_', in order to be easily accessible from Octave
int transform_keyword(int c) {
  return isalnum(c) ? tolower(c) : '_';
}

DEFUN_DLD( fitsread, args, nargout, fitsread_usage ) {

  // Prevent octave from crashing ...
#if OCTAVE_VERSION_HEX < 0x040400
  octave_exit = ::_Exit;
#endif

  // Check input and output
  if (args.length() != 1 || nargout > 1) {
    error("incorrect number of input/output arguments");
    print_usage();
    return octave_value();
  }
  if (!args(0).is_string()) {
    error("argument is not a string");
    print_usage();
    return octave_value();
  }
  std::string filename = args(0).string_value();

  // Open FITS file
  int status = 0;
  fitsfile *ff = 0;
  octave_map all_hdus(dim_vector(1, 1));
  int ext_index = 0;
  do {
    if (fits_open_file(&ff, filename.c_str(), READONLY, &status) != 0) break;

    // Read all HDUs
    do {

      // Read HDU header
      octave_map header(dim_vector(1, 1));
      int nkeys = 0;
      fits_get_hdrspace(ff, &nkeys, 0, &status);
      for (int i = 1; i <= nkeys; ++i) {

        // Read next header card and parse into keyword/value
        char card[FLEN_CARD];
        if (fits_read_record(ff, i, card, &status) != 0) break;
        char keyname[FLEN_KEYWORD], value[FLEN_VALUE], comment[FLEN_COMMENT];
        int keylength = 0;
        if (fits_get_keyname(card, keyname, &keylength, &status) != 0) break;
        if (keylength == 0) {
          continue;
        }
        std::string key(keyname);
        std::transform(key.begin(), key.end(), key.begin(), transform_keyword);
        if (fits_parse_value(card, value, comment, &status) != 0) {
          break;
        }
        if (strlen(value) == 0) {
          continue;
        }

        // String trailing number from keyword, indicating keyword sequence
        int keyn = 1;
        {
          std::string::reverse_iterator jj = std::find_if(key.rbegin(), key.rend(), std::not1(std::ptr_fun(::isdigit)));
          size_t j = std::distance(key.rbegin(), jj);
          if (j > 0) {
            int n = atoi(key.substr(key.length() - j).c_str());
            std::string key_base = key.substr(0, key.length() - j);
            if (n == 1 || header.contains(key_base)) {
              key = key_base;
              keyn = n;
            }
          }
        }

        // Parse card value to get datatype
        char dtype = 0;
        if (fits_get_keytype(value, &dtype, &status) != 0) break;

        // Read previous card, so that we can reread this card again
        if (fits_read_record(ff, i - 1, card, &status) != 0) break;

        // Reread this header card using datatype information
        octave_value val;
        if (dtype == 'C') {
          char *longstr = 0;
          if (fits_read_key_longstr(ff, keyname, &longstr, comment, &status) != 0) break;
          val = octave_value(longstr);
          fffree(longstr, &status);
        } else if (dtype == 'L') {
          int logval = 0;
          if (fits_read_key_log(ff, keyname, &logval, comment, &status) != 0) break;
          val = octave_value(logval ? true : false);
        } else if (dtype == 'X') {
          double dblcmpval[2] = {0, 0};
          if (fits_read_key_dblcmp(ff, keyname, dblcmpval, comment, &status) != 0) break;
          val = octave_value(Complex(dblcmpval[0], dblcmpval[1]));
        } else {
          double dblval = 0;
          if (fits_read_key_dbl(ff, keyname, &dblval, comment, &status) != 0) break;
          val = octave_value(dblval);
        }

        // Add value to header; keyword sequences are added to cell arrays
        if (!header.contains(key)) {
          header.contents(key) = Cell(val);
        } else {
          Cell vals;
          if (header.contents(key).elem(0).is_cell()) {
            vals = header.contents(key).elem(0).cell_value();
          } else {
            vals = Cell(header.contents(key).elem(0));
          }
          vals.insert(val, keyn - 1, 0);
          header.contents(key) = Cell(octave_value(vals));
        }

      }

      // Read HDU data
      int hdutype = 0;
      octave_value data;
      {
        NDArray empty(dim_vector(0, 0));
        data = octave_value(empty.squeeze());
      }
      if (fits_get_hdu_type(ff, &hdutype, &status) != 0) break;
      if (hdutype == IMAGE_HDU) {

        // Get image dimensions
        int bitpix = 0, naxis = 0;
        long naxes[4] = {0};
        if (fits_get_img_param(ff, 4, &bitpix, &naxis, naxes, &status) != 0) break;
        for (int i = naxis; i < 4; ++i) {
          naxes[i] = 1;
        }
        if (naxis > 0) {

          // Fill N-dimensional array with image
          NDArray array(dim_vector(naxes[0], naxes[1], naxes[2], naxes[3]));
          long fpixel[4];
          Array<octave_idx_type> idx(dim_vector(1, 4), 0);
          for (fpixel[0] = 1; fpixel[0] <= naxes[0]; ++fpixel[0]) {
            idx(0) = fpixel[0] - 1;
            for (fpixel[1] = 1; fpixel[1] <= naxes[1]; ++fpixel[1]) {
              idx(1) = fpixel[1] - 1;
              for (fpixel[2] = 1; fpixel[2] <= naxes[2]; ++fpixel[2]) {
                idx(2) = fpixel[2] - 1;
                for (fpixel[3] = 1; fpixel[3] <= naxes[3]; ++fpixel[3]) {
                  idx(3) = fpixel[3] - 1;
                  double val = 0;
                  if (fits_read_pix(ff, TDOUBLE, fpixel, 1, 0, &val, 0, &status) != 0) break;
                  array.elem(idx) = val;
                }
                if (status != 0) break;
              }
              if (status != 0) break;
            }
            if (status != 0) break;
          }
          if (status != 0) break;
          data = octave_value(array.squeeze());

        }

      } else {

        // Get table dimensions and fields
        long nrows = 0;
        int nfields = 0;
        if (fits_get_num_rows(ff, &nrows, &status) != 0) break;
        if (fits_get_num_cols(ff, &nfields, &status) != 0) break;
        octave_map tbl(dim_vector(nrows, 1));
        {
          char card[FLEN_CARD];
          if (fits_read_record(ff, 0, card, &status) != 0) break;
        }
        for (int j = 1; j <= nfields; ++j) {

          // Read field name
          char keyword[FLEN_KEYWORD], fieldname[FLEN_VALUE];
          if (fits_make_keyn("TTYPE", j, keyword, &status) != 0) break;
          if (fits_read_key(ff, TSTRING, keyword, fieldname, 0, &status) != 0) break;
          std::string field(fieldname);

          // Get field datatype
          int typecode = 0;
          long repeat = 0, width = 0;
          if (fits_get_eqcoltype(ff, j, &typecode, &repeat, &width, &status) != 0) break;

          // Read table field using datatype information
          for (long i = 1; i <= nrows; ++i) {
            octave_value val;
            if (typecode == TSTRING) {
              char *strval = new char[width + 1];
              if (fits_read_col_str(ff, j, i, 1, 1, 0, &strval, 0, &status) != 0) break;
              val = octave_value(std::string(strval));
              delete [] strval;
            } else if (typecode == TLOGICAL) {
              boolNDArray array(dim_vector(repeat, 1));
              Array<octave_idx_type> idx(dim_vector(1, 1), 0);
              for (long r = 1; r <= repeat; ++r) {
                idx(0) = r - 1;
                char logval = 0;
                if (fits_read_col_log(ff, j, i, r, 1, 0, &logval, 0, &status) != 0) break;
                array.elem(idx) = logval ? true : false;
              }
              val = octave_value(array.squeeze());
            } else if (typecode == TCOMPLEX || typecode == TDBLCOMPLEX) {
              ComplexNDArray array(dim_vector(repeat, 1));
              Array<octave_idx_type> idx(dim_vector(1, 1), 0);
              for (long r = 1; r <= repeat; ++r) {
                idx(0) = r - 1;
                double dblcmpval[2] = {0, 0};
                if (fits_read_col_dblcmp(ff, j, i, r, 1, 0, dblcmpval, 0, &status) != 0) break;
                array.elem(idx) = Complex(dblcmpval[0], dblcmpval[1]);
              }
              val = octave_value(array.squeeze());
            } else {
              NDArray array(dim_vector(repeat, 1));
              Array<octave_idx_type> idx(dim_vector(1, 1), 0);
              for (long r = 1; r <= repeat; ++r) {
                idx(0) = r - 1;
                double dblval = 0;
                if (fits_read_col_dbl(ff, j, i, r, 1, 0, &dblval, 0, &status) != 0) break;
                array.elem(idx) = dblval;
              }
              val = octave_value(array.squeeze());
            }
            tbl.contents(field).insert(val, i - 1, 0);
          }

        }
        data = octave_value(tbl);

      }

      // Determine name of HDU
      std::string hduname;
      if (header.isfield("hduname")) {
        hduname = header.contents("hduname").elem(0).string_value();
      } else if (header.isfield("extname")) {
        hduname = header.contents("extname").elem(0).string_value();
      } else {
        int hdunum = 0;
        fits_get_hdu_num(ff, &hdunum);
        if ( hdunum < 1 ) {
          status = BAD_HDU_NUM;
          break;
        }
        hduname = ( hdunum == 1 ) ? "primary" : "extension";
      }

      // Insert HDU into map
      if ( hduname == "extension" ) {
        octave_map ext_hdus(dim_vector(1, 1));
        if (all_hdus.contents(hduname).elem(0).is_map()) {
          ext_hdus = all_hdus.contents(hduname).elem(0).map_value();
        }
        ext_hdus.resize(dim_vector(1 + ext_index, 1));
        ext_hdus.contents("header").insert(Cell(octave_value(header)), ext_index, 0);
        ext_hdus.contents("data").insert(Cell(octave_value(data)), ext_index, 0);
        all_hdus.contents(hduname) = Cell(octave_value(ext_hdus));
        ++ext_index;
      } else {
        octave_map hdu(dim_vector(1, 1));
        hdu.contents("header") = Cell(octave_value(header));
        hdu.contents("data") = Cell(octave_value(data));
        all_hdus.contents(hduname) = Cell(octave_value(hdu));
      }

      // Move to next HDU
      fits_movrel_hdu(ff, 1, 0, &status);

    } while (status != END_OF_FILE);
    if (status == END_OF_FILE) {
      status = 0;
    }

  } while (0);

  // Close FITS file
  if (ff != 0) {
    fits_close_file(ff, &status);
  }

  // Report any FITS error messages
  if (status != 0) {
    char errstatus[FLEN_STATUS];
    fits_get_errstatus(status, errstatus);
    error("in FITS file '%s': %s", filename.c_str(), errstatus);
    return octave_value();
  }

  // Return read FITS header-data-units
  return octave_value(all_hdus);

}

/*

%!test
%!  fitsread(fullfile(fileparts(file_in_loadpath("fitsread.cc")), "fitsread_test.fits"));

*/
