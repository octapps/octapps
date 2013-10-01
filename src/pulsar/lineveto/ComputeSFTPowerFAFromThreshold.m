function SFTpower_fA = ComputeSFTPowerFAFromThreshold ( SFTpower_thresh, num_SFTs )

 SFTpower_fA = 1.0 - normcdf ( SFTpower_thresh, 1.0, 1.0/sqrt(num_SFTs) );

endfunction # ComputeSFTPowerFAFromThreshold()