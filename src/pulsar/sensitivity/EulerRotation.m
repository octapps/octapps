%% Return the Euler rotation of three angles
%% Syntax:
%%   R = EulerRotation(c1, s1, c2, s2, c3, s3)
%% where:
%%   c1,c2,c3 = cosines of angles 1,2,3
%%   s1,s2,s3 =   sines of angles 1,2,3
%%   R        = Euler rotation matrix
function R = EulerRotation(c1, s1, c2, s2, c3, s3)

  assert(isvector(c1) && isvector(c2) && ...
	 isvector(c3) && isvector(s1) && ...
	 isvector(s2) && isvector(s3));

  R        = zeros(3,3,length(c1));
  R(1,1,:) =  c1.*c3 - s1.*c2.*s3;
  R(1,2,:) =  s1.*c3 + c1.*c2.*s3;
  R(1,3,:) =  s2.*s3;
  R(2,1,:) = -c1.*s3 - s1.*c2.*c3;
  R(2,2,:) = -s1.*s3 + c1.*c2.*c3;
  R(2,3,:) =  s2.*c3;
  R(3,1,:) =  s1.*s2;
  R(3,2,:) = -c1.*s2;
  R(3,3,:) =  c2;

endfunction
