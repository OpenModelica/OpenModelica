// name: ArrayOperators
// keywords: array, operators
// status: correct

model ArrayOperators
  constant Real rarr1[2,2] = [1,2;3,4] .* [5,6;7,8];
  constant Real rarr2[2,2] = [5,6;7,8] ./ [1,2;3,4];
  constant Real rarr3[2,2] = [1,2;3,4] .+ [5,6;7,8];
  constant Real rarr4[2,2] = [5,6;7,8] .- [1,2;3,4];
end ArrayOperators;

// Result:
// class ArrayOperators
//   constant Real rarr1[1,1] = 5.0;
//   constant Real rarr1[1,2] = 12.0;
//   constant Real rarr1[2,1] = 21.0;
//   constant Real rarr1[2,2] = 32.0;
//   constant Real rarr2[1,1] = 5.0;
//   constant Real rarr2[1,2] = 3.0;
//   constant Real rarr2[2,1] = 2.3333333333333335;
//   constant Real rarr2[2,2] = 2.0;
//   constant Real rarr3[1,1] = 6.0;
//   constant Real rarr3[1,2] = 8.0;
//   constant Real rarr3[2,1] = 10.0;
//   constant Real rarr3[2,2] = 12.0;
//   constant Real rarr4[1,1] = 4.0;
//   constant Real rarr4[1,2] = 4.0;
//   constant Real rarr4[2,1] = 4.0;
//   constant Real rarr4[2,2] = 4.0;
// end ArrayOperators;
// endResult
