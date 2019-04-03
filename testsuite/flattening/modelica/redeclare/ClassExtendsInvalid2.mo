// name:     ClassExtendsInvalid2
// keywords: class, extends
// status:   incorrect
//
// Checks that it's not allowed to class extend a non-inherited class.
//

model X end X;

class ClassExtendsInvalid2
 redeclare model extends X end X;
end ClassExtendsInvalid2;

// Result:
// Error processing file: ClassExtendsInvalid2.mo
// [flattening/modelica/redeclare/ClassExtendsInvalid2.mo:11:12-11:33:writable] Error: Invalid redeclaration of class X, class extends only allowed on inherited classes.
// [flattening/modelica/redeclare/ClassExtendsInvalid2.mo:11:12-11:33:writable] Error: Illegal redeclare of element X, no inherited element with that name exists.
// Error: Error occurred while flattening model ClassExtendsInvalid2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
