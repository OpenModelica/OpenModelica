package Boundary 
  
  replaceable function shape 
    input Real u;
    input Data d;
    output BPoint x;
  algorithm 
    x := {u,u,d.bc.index};
  end shape;
  
  replaceable function points 
    input Integer n;
    input Data d;
    output BPoint x[n];
  algorithm 
    for i in 1:n loop
      x[i, :] := shape((i - 1)/n, d);
    end for;
  end points;
  
  replaceable record Data 
    parameter BoundaryCondition.Data bc;
  end Data;
  
end Boundary;
