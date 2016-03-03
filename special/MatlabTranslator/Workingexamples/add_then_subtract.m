function result = add_then_subtract(input_val, num_iter)
% Repeatedly multiply and divide the given value by three,
%   in such a way that the end result should be identical
%   to the input value.
%   
% Return the result.
% 

  result = input_val;
  one_third = 1.0/3.0;
    
  for (icount = 1 : num_iter)
    result = result + one_third;
  end
           
  for (icount = 1 : num_iter)
    result = result - one_third;
  end
                    