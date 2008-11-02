
function expression_index1
  input Real[3,3] x;
  output Real[size(x,2)] y;

algorithm

  y := x[:,1];

end expression_index1;

model mo
end mo;
