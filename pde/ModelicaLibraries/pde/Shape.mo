package Shape "Rudimentary set of shaping functions" 
  
partial function shape1D 
  input Real u;
  output Coordinate x;
end shape1D;
  
partial function shape2D 
  input Real u;
  output Coordinate x[2];
end shape2D;
  
function lineShape1D 
  extends shape1D;
  input Elements.Line1D line;
algorithm 
  x := line.x1 + u*(line.x2 - line.x1);
end lineShape1D;
  
function lineShape2D 
  extends shape2D;
  input Elements.Line2D line;
algorithm 
  x := line.x1 + u*(line.x2 - line.x1);
end lineShape2D;
  
end Shape;
