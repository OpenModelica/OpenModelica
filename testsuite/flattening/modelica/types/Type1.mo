// name:     Type1
// keywords: type
// status:   incorrect
//
// You cannot define your own types, only derive them from the builtings.
//

type Type1
  Real x;
end Type1;
// Result:
// Error processing file: Type1.mo
// Error: In class .Type1, class specialization 'type' can only be derived from predefined types.
// Error: Error occurred while flattening model Type1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
