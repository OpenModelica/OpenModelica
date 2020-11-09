// name:     DeclareConstant2
// keywords: declaration
// status:   incorrect
// cflags: -d=-newInst
//
// The attribute 'value' shall not be accessed.
//

class DeclareConstant2
  constant String s(value = "value");
end DeclareConstant2;
