%% thresh_root = falseAlarm_2F_num_root ( fA, thresh_low, thresh_high, thresh_step )
%%
%% numerically compute a root of the transcendental equation for the false alarm rate inside interval [thres_low,thresh_high]
%%

function thresh_root = falseAlarm_2F_num_root ( fA, thresh_low, thresh_high, thresh_step )
 
 x = thresh_low:thresh_step:thresh_high;
 y = ( 1 + x/2 ) .* e.^(-x/2);
 
 thresh_root = zeros(length(fA),1);
 
 for fA_count = 1:1:length(fA)
  
  thresh_count = 1;
  while ( y(thresh_count) > fA(fA_count)  && thresh_count < length(y) )
   thresh_count++;
  end
 
  thresh_root(fA_count) = x(thresh_count);
 end
 
endfunction