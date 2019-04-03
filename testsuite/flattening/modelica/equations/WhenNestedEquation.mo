// name: WhenNestedEquation
// keywords: when, nested, equation
// status: incorrect
//
// Test detection of nested when-equations, which are not allowed.
// Fix for bug 1189: http://openmodelica.ida.liu.se:8080/cb/issue/1189
//

model ErrorNestedWhen
  Real x,y1,y2;
equation
  when x > 2 then
    when y1 > 3 then
      y2=sin(x);
    end when;
  end when;
end ErrorNestedWhen;

// Result:
// Error processing file: WhenNestedEquation.mo
// [flattening/modelica/equations/WhenNestedEquation.mo:13:5-15:13:writable] Error: Nested when statements are not allowed.
// Error: Error occurred while flattening model ErrorNestedWhen
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
