// name:     DimSize
// keywords: array
// status:   correct
//
// ??Error - not yet implemented
// Drmodelica: 7.7 Built-in Functions (p. 225)
//
class DimSize
  parameter Real[4, 1, 6] x = fill(1., 4, 1, 6);
  parameter Real dim = ndims(x);           // Returns 3
  parameter Real dimsize = size(x, 1);     // Returns 4
  parameter Real specsize[3] = size(x);    // Returns the vector {4, 1, 6}
equation
 // size(2*x + x) = size(x);                // This equation holds
end DimSize;
