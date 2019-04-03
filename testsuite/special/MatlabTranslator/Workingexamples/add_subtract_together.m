function result = add_subtract_together(input_val, num_iter)
% Repeatedly add and subtract a constant value
%   from the 'input_val',
%   in such a way that the end result should be identical
%   to the input value.
%   
% Return the result.
% 

  result = input_val;
  one_third = 1.0/3.0;
    
  for (icount = 1 : num_iter)
    result = result + one_third;
    result = result - one_third;
  end
end