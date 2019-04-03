function [min_val, max_val] = array_extremes(array)
% 
% Find the minimum and maximum values in an array of numbers.
% 
% Arguments:
% 
%       array           (input)   1-D array of numbers
%
%       min_val         (output)  the minimum value
%
%       max_val         (output)  the maximum value
% 

  min_val = min(array);
  max_val = max(array);
end 