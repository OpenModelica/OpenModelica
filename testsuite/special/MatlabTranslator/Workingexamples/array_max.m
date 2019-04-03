function max_val = array_max(array)
% 
% Find the maximum value in an array of numbers.
% 
% Arguments:
% 
%       array           (input)   1-D array of numbers
%
%       max_val         (output)  the maximum value
% 

 
  % Loop through the array to find the largest element
  largest_so_far = array(1);
  for index = 2 : size(array,2)
    if (array(index) > largest_so_far) 
      largest_so_far = array(index);
    end
  end

  max_val = largest_so_far;
end