// name: WhenNested
// keywords: when, nested
// status: incorrect
//
// Test detection of nested when-statements, which are not allowed.
// Fix for bug 1189: http://openmodelica.ida.liu.se:8080/cb/issue/1189
//

model WhenNested
  Integer x;
  Integer y;
algorithm
  when sample(0, 1) then
    if time > 1 then
      when x > 0 then
        y := 3;
      end when;
    end if;
  end when;
end WhenNested;

// Result:
// Error processing file: WhenNested.mo
// [flattening/modelica/algorithms-functions/WhenNested.mo:13:3-19:11:writable] Error: Nested when statements are not allowed.
// Error: Error occurred while flattening model WhenNested
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
