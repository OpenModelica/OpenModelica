// name: String arrays
// keywords: array
// status: correct

function strCombine
  input String[:] inVal;
  output String outVal;
algorithm
  outVal := "";
  for i in 1:size(inVal,1) loop
    outVal := outVal + inVal[i];
  end for;
end strCombine;

class InOutArray2
  constant String A[5] = { "hello", " world", "!", " ab", "ba " };
  String Asum = strCombine(A);
end InOutArray2;

// Result:
// function strCombine
//   input String[:] inVal;
//   output String outVal;
// algorithm
//   outVal := "";
//   for i in 1:size(inVal, 1) loop
//     outVal := outVal + inVal[i];
//   end for;
// end strCombine;
//
// class InOutArray2
//   constant String A[1] = "hello";
//   constant String A[2] = " world";
//   constant String A[3] = "!";
//   constant String A[4] = " ab";
//   constant String A[5] = "ba ";
//   String Asum = "hello world! abba ";
// end InOutArray2;
// endResult
