function x= counter(startval, increment, endval)
%
% Count from 'startval' to 'endval', incrementing by 'increment'.
%   Print out each number in the count as we go.
%
% Arguments:
% 
%       startval           (input)  we start counting here ...
%
%       increment          (input)  amount by which to increase each time
%
%       endval             (input)  stop counting when we reach this value;
%                                      if our count equals this value exactly,
%                                      then we print it out; otherwise, we
%                                      don't print it out.
%                                      
%                                      Example:   counter(1, 2, 5)
%                                                     will print '5'
%                                                    
%                                                 counter(1, 2, 6)
%                                                     will not print '6'
% 

  val = startval;
  while (val <= endval) 
    val = val + increment;
  end
  x=val;
