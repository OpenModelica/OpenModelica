function min_val = array_min(array)
% 
% Find the minimum value in an array of numbers.
% 
% Arguments:
% 
%       array           (input)   1-D array of numbers
%
%       min_val         (output)  the minimum value
% 

  % Check the dimensions of the 'array' argument.
  %   We expect a simple 1-D array of numbers, in which case
  %      num_rows     should be 1
  %      num_cols     will be the number of values in the array
  %
  % If the given 'array' isn't a simple 1-D array, print an error
  %   message and quit.
 
  % Loop through the array to find the smallest element
  lowest_so_far = array(1);
  for index = 2 : size(array,2)
    if (array(index) < lowest_so_far) 
      lowest_so_far = array(index);
    end
  end

  min_val = lowest_so_far;
