package ErrorInteractiveCallFunctionPtr

function func
  input intBinOp fn;
  input Integer i1;
  input Integer i2;
  output Integer i;
  partial function intBinOp
    input Integer i1;
    input Integer i2;
    output Integer i;
  end intBinOp;
algorithm
  i := i1+i2;
end func;

function applyIntAdd
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := func(intAdd, i1, i2);
end applyIntAdd;

function myIntAdd
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := i1+i2;
end myIntAdd;

end ErrorInteractiveCallFunctionPtr;
