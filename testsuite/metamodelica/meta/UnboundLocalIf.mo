// cflags: +g=MetaModelica
// status: correct

model UnboundLocalIf
  function assignedInSingleBranch
    input Boolean cond;
    output Integer y;
  protected
    Integer x;
  algorithm
    if cond then
      x := 1;
    end if;
    y := x;
  end assignedInSingleBranch;

  function assignedInIfElseifNoElse
    input Boolean c1;
    input Boolean c2;
    output Integer y;
  protected
    Integer x;
  algorithm
    if c1 then
      x := 1;
    elseif c2 then
      x := 2;
    end if;
    y := x;
  end assignedInIfElseifNoElse;

  function assignedInAllBranches
    input Boolean c;
    output Integer y;
  protected
    Integer x;
  algorithm
    if c then
      x := 1;
    else
      x := 2;
    end if;
    y := x;
  end assignedInAllBranches;

  Integer r1 = assignedInSingleBranch(true);
  Integer r2 = assignedInIfElseifNoElse(true, false);
  Integer r3 = assignedInAllBranches(true);
end UnboundLocalIf;

// Result:
// class UnboundLocalIf
//   Integer r1 = 1;
//   Integer r2 = 1;
//   Integer r3 = 1;
// end UnboundLocalIf;
// [metamodelica/meta/UnboundLocalIf.mo:14:5-14:11:writable] Warning: x was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [metamodelica/meta/UnboundLocalIf.mo:29:5-29:11:writable] Warning: x was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
//
// endResult
