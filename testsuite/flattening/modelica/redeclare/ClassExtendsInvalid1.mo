// name:     ClassExtendsInvalid1
// keywords: class,extends
// status:   incorrect
//
// Checks that it's not allowed to class extend a non-replaceable class.
//

class Y
  model X end X;
end Y;

class ClassExtendsInvalid1
 extends Y;

 redeclare model extends X end X;
end ClassExtendsInvalid1;

// Result:
// Error processing file: ClassExtendsInvalid1.mo
// Notification: From here:
// [flattening/modelica/redeclare/ClassExtendsInvalid1.mo:9:3-9:16:writable] Error: Non-replaceable base class X in class extends.
// [flattening/modelica/redeclare/ClassExtendsInvalid1.mo:15:12-15:33:writable] Notification: From here:
// [flattening/modelica/redeclare/ClassExtendsInvalid1.mo:9:3-9:16:writable] Error: Trying to redeclare class X but class not declared as replaceable.
// Error: Error occurred while flattening model ClassExtendsInvalid1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
