// name:     ConstructFunc
// keywords: array
// status:   correct
//
// Array constructs.
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

// Result:
// class ConstructFunc
//   Real z[1,1];
//   Real z[1,2];
//   Real z[1,3];
//   Real z[2,1];
//   Real z[2,2];
//   Real z[2,3];
//   Real o[1];
//   Real o[2];
//   Real o[3];
//   Real f[1,1];
//   Real f[1,2];
//   Real f[2,1];
//   Real f[2,2];
//   Boolean check[1,1];
//   Boolean check[1,2];
//   Boolean check[1,3];
//   Boolean check[1,4];
//   Boolean check[2,1];
//   Boolean check[2,2];
//   Boolean check[2,3];
//   Boolean check[2,4];
//   Boolean check[3,1];
//   Boolean check[3,2];
//   Boolean check[3,3];
//   Boolean check[3,4];
//   Real id[1,1];
//   Real id[1,2];
//   Real id[1,3];
//   Real id[2,1];
//   Real id[2,2];
//   Real id[2,3];
//   Real id[3,1];
//   Real id[3,2];
//   Real id[3,3];
//   Real di[1,1];
//   Real di[1,2];
//   Real di[1,3];
//   Real di[2,1];
//   Real di[2,2];
//   Real di[2,3];
//   Real di[3,1];
//   Real di[3,2];
//   Real di[3,3];
//   Real ls[1];
//   Real ls[2];
//   Real ls[3];
//   Real ls[4];
//   Real ls[5];
// equation
//   z = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
//   o = {1.0, 1.0, 1.0};
//   f = {{2.1, 2.1}, {2.1, 2.1}};
//   check = {{true, true, true, true}, {true, true, true, true}, {true, true, true, true}};
//   id = {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}};
//   di = {{1.0, 0.0, 0.0}, {0.0, 2.0, 0.0}, {0.0, 0.0, 3.0}};
//   ls = {0.0, 2.0, 4.0, 6.0, 8.0};
// end ConstructFunc;
// endResult
