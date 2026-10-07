// name:     EnumConnectArray
// keywords: enum connect array
// status:   correct
//
// Tests that enumeration literals are preserved when connecting two arrays
// whose dimensions are given by enumerations.
//
type TComponents = enumeration (AA, BB, CC);

block TBlock
  input Real[TComponents] In;
  output Real[TComponents] Out;
end TBlock;

block EnumConnectArray
  TBlock Block1;
  TBlock Block2;
equation
  connect(Block2.In, Block1.Out);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end EnumConnectArray;

// Result:
// class EnumConnectArray
//   Real Block1.In[TComponents.AA];
//   Real Block1.In[TComponents.BB];
//   Real Block1.In[TComponents.CC];
//   Real Block1.Out[TComponents.AA];
//   Real Block1.Out[TComponents.BB];
//   Real Block1.Out[TComponents.CC];
//   Real Block2.In[TComponents.AA];
//   Real Block2.In[TComponents.BB];
//   Real Block2.In[TComponents.CC];
//   Real Block2.Out[TComponents.AA];
//   Real Block2.Out[TComponents.BB];
//   Real Block2.Out[TComponents.CC];
// equation
//   Block1.Out[TComponents.AA] = Block2.In[TComponents.AA];
//   Block1.Out[TComponents.BB] = Block2.In[TComponents.BB];
//   Block1.Out[TComponents.CC] = Block2.In[TComponents.CC];
// end EnumConnectArray;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
