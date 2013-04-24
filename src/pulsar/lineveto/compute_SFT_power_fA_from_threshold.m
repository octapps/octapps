function SFTpower_fA = compute_SFT_power_fA_from_threshold ( SFTpower_thresh, sftfile )

 num_SFTs = get_num_SFTs_from_file ( sftfile )

 SFTpower_fA = 1.0 - normcdf ( SFTpower_thresh, 1.0, 1.0/sqrt(num_SFTs) );

endfunction # compute_SFT_power_fA_from_threshold()