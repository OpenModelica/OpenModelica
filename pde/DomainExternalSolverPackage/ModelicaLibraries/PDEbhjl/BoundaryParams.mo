package BoundaryParams 
  
  replaceable function shape 
    input Real u;
    input Data d;
    output Point x;
  algorithm 
    x := {u,u};
  end shape;
  
  replaceable function points 
    input Integer n;
    input Data d;
    output Point x[n];
  algorithm 
    for i in 1:n loop
      x[i, :] := shape((i - 1)/n, d);
    end for;
  end points;
  
  replaceable record Data 
    parameter Parameters p;
  end Data;
  
  replaceable record Parameters = Dummy;
  
  record Dummy 
    
  end Dummy;
  
end BoundaryParams;
