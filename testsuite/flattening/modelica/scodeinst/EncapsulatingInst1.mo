// name: EncapsulatingInst1
// keywords:
// status: correct
// cflags: -i=EncapsulatingInst1.M
//

model EncapsulatingInst1
  model M
    EncapsulatingInst1 x(i = 1);
  end M;

  constant Integer i;
  annotation(__OpenModelica_commandLineOptions="-i=EncapsulatingInst1.M");
end EncapsulatingInst1;

// Result:
// class EncapsulatingInst1.M
//   constant Integer x.i = 1;
// end EncapsulatingInst1.M;
// endResult
