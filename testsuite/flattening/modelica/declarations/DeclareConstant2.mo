// name:     DeclareConstant2
// keywords: declaration
// status:   incorrect
//
// The attribute 'value' shall not be accessed.
//

class DeclareConstant2
  constant String s(value = "value");
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DeclareConstant2;
