// name:     ConstructFunc
// keywords: array
// status:   correct
//
// Array constructs.
// Error! linspace not implemented.
// Drmodelica: 7.7 Built-in Functions (p. 225)
//

class ConstructFunc
  Real z[2,3]  = zeros(2, 3);  // Constructs the matrix {{0,0,0}, {0,0,0}}
  Real o[3]    = ones(3);      // Constructs the vector {1, 1, 1}
  Real f[2,2]  = fill(2.1,2,2); // Constructs the matrix {{2.1, 2.1}, {2.1, 2.1}}
  Boolean check[3, 4]  = fill(true, 3, 4);   // Fills a Boolean matrix
  Real id[3,3]    = identity(3);    // Creates the matrix {{1,0,0}, {0,1,0}, {0, 0, 1}}
  Real di[3,3] = diagonal({1, 2, 3}); // Creates the matrix {{1, 0, 0}, {0, 2, 0}, {0, 0, 3}}
  Real ls[5] = linspace(0.0, 8.0, 5);  // Computes the vector {0.0, 2.0, 4.0, 6.0, 8.0}
end ConstructFunc;


