package ErrorMatchNumOutput

function func
  input Integer i1;
  input Integer i2;
  input Integer i3;
  output Integer o1;
  output Integer o2;
  output Integer o3;
algorithm
  (o1,o2,o3) := match (i1,i2)
    case (1,2) then (3,4);
    else then (5,6,7);
  end match;
end func;

end ErrorMatchNumOutput;
