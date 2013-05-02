function num_SFTs = get_num_SFTs_from_file ( sftfile )

 % safety measure to work around lalapps_dumpSFT bug: check if sftfile is a pattern matching several files, and if it is, just use the first one.
 [status, output] = system(["find ", sftfile]);
 sftfiles = strsplit(output,"\n");

 sft_counting_string_from_header = "Locator:";

 [status, output] = system(["lalapps_dumpSFT --SFTfiles=", sftfiles{1}, " | grep -c ", sft_counting_string_from_header]);

 num_SFTs = str2num(output);

endfunction # get_num_SFTs_from_file()