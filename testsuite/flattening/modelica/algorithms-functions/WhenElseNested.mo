// name: WhenElseNested
// keywords: elsewhen, nested
// status: incorrect
//
// Test detection of nested when-statements in the elsewhen branch, which are
// not allowed.
// Fix for bug 1189: http://openmodelica.ida.liu.se:8080/cb/issue/1189
//

model WhenElseNested
  Integer x;
  Integer y;
algorithm
  when sample(0, 1) then
    y := 3;
  elsewhen x == 3 then
    when y < 1 then
      y := 2;
    end when;
  end when;
end WhenElseNested;

// Result:
// Error processing file: WhenElseNested.mo
// [flattening/modelica/algorithms-functions/WhenElseNested.mo:17:5-19:13:writable] Error: Nested when statements are not allowed.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
