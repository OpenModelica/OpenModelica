model BooleanArray
  Boolean[5] boolArr = {true,false,true,false,true};
  Integer[5] realArr = {1,2,3,4,5};
  Real[5] resArr;

  function abc
    input Boolean[:] boolArr;
    input Integer[size(boolArr,1)] realArr;
    output Real[size(boolArr,1)] outArr;
  protected
    Boolean[size(boolArr,1)] boolArr2;
  algorithm
    boolArr2 := fill(true,size(boolArr,1));
    for i in 1:size(boolArr,1) loop
      if not boolArr2[i] then
        outArr[i] := -1;
      elseif boolArr[i] then
        outArr[i] := realArr[i]*i;
      else
        outArr[i] := 0;
      end if;
    end for;
  end abc;
equation
  resArr = abc(boolArr,realArr);
end BooleanArray;
