 function aprox_value_of_pi = approximate_pi( steps_to_take ) 
 
 
  aprox_value_of_pi = 4.0; 
  time_to_subtract = 1.0; 
 
  for i = 2:steps_to_take 
 
    if (time_to_subtract==1.0) 
      aprox_value_of_pi = aprox_value_of_pi - (4 / ((2*i)-1)); 
    else 
      aprox_value_of_pi = aprox_value_of_pi + (4 / ((2*i)-1)); 
    end 
 
    time_to_subtract = 0.0; 
 
  end % for loop 
 
  end % function 