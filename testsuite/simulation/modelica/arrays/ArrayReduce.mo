// name:     ArrayReduce
// keywords: array
// status:   correct
//
// Drmodelica: 7.7 Built-in Functions (p. 225)
//

class ArrayReduce
  Real minimum, maximum, summ, prod;
equation
  minimum = min({1, -1, 7});              // Gives the value -1
  maximum = max([1, 2, 3; 4, 5, 6]);      // Gives the value 6
  summ    = sum({{1, 2, 3}, {4, 5, 6}});  // Gives the value 21
  prod    = product({3.14, 2, 2});        // Gives the value 12.56
end ArrayReduce;

// class ArrayReduce
// Real minimum;
// Real maximum;
// Real summ;
// Real prod;
// equation
//   minimum = -1.0;
//   maximum = 6.0;
//   summ = Real({1,2,3} + {4,5,6});
//   prod = 12.56;
// end ArrayReduce;
