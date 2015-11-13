function perfect = isperfect(test_value)
% 
% This function checks to see if the given number is "perfect";
%   a "perfect" number is an integer whose factors (excluding 
%   itself) add up to it.
%
%   Example:  6    is a perfect number:   1 + 2 + 3 = 6  == 6
%             8    is not                 1 + 2 + 4 = 7  ~= 8
%
% Arguments:
%
%       test_value        (input)     check to see if this value is
%                                     perfect or not
%
%       perfect           (output)    if yes, set this to 1
%                                     if no, set this to 0
%
% MWR 3/14/2001
%
% this will keep track of the sum of all integer divisors
  sum = 0;
  
  % we check all possible divisors
  for (divisor = 1 : test_value - 1)    
    div_result = test_value / divisor;

    if (div_result == floor(div_result)) 
       % this is an integer divisor, so add it to the sum
       sum = sum + divisor;
    end

  end

  % now, does the sum equal the test_value?
  if (sum == test_value) 
     perfect = 1;
  else
     perfect = 0;
  end  
end
  