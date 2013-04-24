function num_SFTs = get_num_SFTs_from_file ( sftfile )

 sft_counting_string_from_header = "Locator:";

 [status, output] = system(["lalapps_dumpSFT --SFTfiles=", sftfile, " | grep -c ", sft_counting_string_from_header]);

 num_SFTs = str2num(output);

endfunction # get_num_SFTs_from_file()