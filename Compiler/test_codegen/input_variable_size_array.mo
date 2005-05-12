
function input_variable_size_array

  input Real[:] x;
  output Real[size(x,1)] y;

algorithm

  y := x;

end input_variable_size_array;

model mo
end mo;
