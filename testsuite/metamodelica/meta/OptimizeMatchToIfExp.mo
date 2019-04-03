// name: OptimizeMatchToIfExp
// status: correct
// cflags: +g=MetaModelica +d=noevalfunc,nogen
// Checks that we are able to convert a match-expression into if
// and inlining it with a non-boxed function that is in turn also
// correctly inlined.
//

class OptimizeMatchToIfExp
  function f
  input Boolean flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c default;
  output Type_c res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
  algorithm
  res := match (flag,func,arg1,arg2,default)
    case (true,_,_,_,_)
      equation
        res = func(arg1,arg2);
      then res;
    else default;
  end match;
  end f;
  Boolean b1 = f(time>0,boolAnd,false,time>2,true);
  Boolean b2 = f(time>0,boolAnd,false,time>2,false);
  Boolean b3 = f(time>0,boolAnd,false,time>2,time>3);
end OptimizeMatchToIfExp;

// Result:
// class OptimizeMatchToIfExp
//   Boolean b1 = not noEvent(time > 0.0);
//   Boolean b2 = false;
//   Boolean b3 = if noEvent(time > 0.0) then false else time > 3.0;
// end OptimizeMatchToIfExp;
// endResult
