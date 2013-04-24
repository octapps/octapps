function SFTpower_thresh = compute_SFT_power_threshold_from_fA ( SFTpower_fA, num_SFTs )

 SFTpower_thresh = norminv ( 1.0 - SFTpower_fA, 1.0, 1.0/sqrt(num_SFTs) );

endfunction # compute_SFT_power_threshold_from_fA()