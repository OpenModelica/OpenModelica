package Domain 
  replaceable package boundaryP = Boundary extends Boundary;
  //  record Data = boundary.Data;
  
  /*  
  replaceable record Parameters 
    parameter boundaryP.Parameters boundary;
  end Parameters;
  */
  
  replaceable record Data 
    parameter boundaryP.Data boundary;
  end Data;
  
  function discretizeBoundary 
    input Integer n;
    input boundaryP.Data d;
    output BPoint p[n];
  algorithm 
    for i in 1:n loop
      p[i, :] := boundaryP.shape((i - 1)/n, d);
    end for;
  end discretizeBoundary;
  
  function boundaryPoints = boundaryP.points;
  
end Domain;
