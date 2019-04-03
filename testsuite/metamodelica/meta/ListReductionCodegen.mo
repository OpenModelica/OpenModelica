// name: ListReductionCodegen
// cflags: -g=MetaModelica -d=noevalfunc,gen
// status: correct
// teardown_command: rm -rf ListReduction_*

class ListReduction
  function myMin
    input Real r1,r2;
    output Real r = min(r1,r2);
  end myMin;

function f
  output String s = "\n";
protected
  String sList,sArr;
  list<Real> reals1 = {1,2,3}, reals2 = {-3.0,-2,-1,0,1,2,3};
  Real realsArr1[3] = {1,2,3}, realsArr2[:] = {-3.0,-2,-1,0,1,2,3}, realsArr3[3];
algorithm
  s := s + anyString(list(1.0*r for r in reals1));s := s + "\n";
  s := s + anyString(listReverse(1.0*r for r in reals1));s := s + "\n";
  s := s + anyString(listReverse(list(1.0*r for r in reals1)));s := s + "\n";
  s := s + anyString(listReverse(listReverse(1.0*r for r guard false or true in reals1)));s := s + "\n";
  s := s + anyString(list(3.5*r for r guard r>0 in reals2));s := s + "\n";
  s := s + anyString(myMin(0,0) + myMin(3.5*r for r guard realAbs(r)<3 in reals2));s := s + "\n";
  s := s + anyString(sum(3.5*r for r guard true and false in reals2));s := s + "\n";
  realsArr3 := array(1.0*r for r in reals1);
  s := s + "{" + sum(realString(r) + "," for r in realsArr3) + "}";s := s + "\n";
  s := s + anyString(min(1.0*r for r in reals1));s := s + "\n";
  s := s + anyString(max(1.0*r for r guard false or true in reals1));s := s + "\n";
  s := s + anyString(realMax(1.5*r for r guard false or true in reals1));s := s + "\n";
  s := s + anyString(sum(3.5*r for r guard r>0 in reals2));s := s + "\n";
  s := s + anyString(product(3.5*r for r guard r>0 in reals2));s := s + "\n";
  s := s + anyString(realMin(r for r guard r>2 in reals1));s := s + "\n";
  sList := s; s := "\n";

  s := s + anyString(list(1.0*r for r in realsArr1));s := s + "\n";
  s := s + anyString(listReverse(1.0*r for r in realsArr1));s := s + "\n";
  s := s + anyString(listReverse(list(1.0*r for r in realsArr1)));s := s + "\n";
  s := s + anyString(listReverse(listReverse(1.0*r for r guard false or true in realsArr1)));s := s + "\n";
  s := s + anyString(list(3.5*r for r guard r>0 in realsArr2));s := s + "\n";
  s := s + anyString(myMin(0,0) + myMin(3.5*r for r guard realAbs(r)<3 in realsArr2));s := s + "\n";
  s := s + anyString(sum(3.5*r for r guard true and false in realsArr2));s := s + "\n";
  realsArr3 := array(1.0*r for r in realsArr1);
  s := s + "{" + sum(realString(r) + "," for r in realsArr3) + "}";s := s + "\n";
  s := s + anyString(min(1.0*r for r in realsArr1));s := s + "\n";
  s := s + anyString(max(1.0*r for r guard false or true in realsArr1));s := s + "\n";
  s := s + anyString(realMax(1.5*r for r guard false or true in realsArr1));s := s + "\n";
  s := s + anyString(sum(3.5*r for r guard r>0 in realsArr2));s := s + "\n";
  s := s + anyString(product(3.5*r for r guard r>0 in realsArr2));s := s + "\n";
  s := s + anyString(realMin(r for r guard r>2 in realsArr1));s := s + "\n";
  sArr := s;
  assert(sList == sArr, "Reductions are different:\nArray:\n" + sArr + "\nList:\n" + sList + "\n");
end f;

  String s = f();
end ListReduction;

// Result:
// function ListReduction.f
//   output String s = "
//   ";
//   protected String sList;
//   protected String sArr;
//   protected list<#Real> reals1 = List(#(1.0), #(2.0), #(3.0));
//   protected list<#Real> reals2 = List(#(-3.0), #(-2.0), #(-1.0), #(0.0), #(1.0), #(2.0), #(3.0));
//   protected Real[3] realsArr1 = {1.0, 2.0, 3.0};
//   protected Real[7] realsArr2 = {-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0};
//   protected Real[3] realsArr3;
// algorithm
//   s := s + anyString(list(r for r in reals1));
//   s := s + "
//   ";
//   s := s + anyString(listReverse(r for r in reals1));
//   s := s + "
//   ";
//   s := s + anyString(listReverse(r for r in reals1));
//   s := s + "
//   ";
//   s := s + anyString(list(r for r in reals1));
//   s := s + "
//   ";
//   s := s + anyString(list(#(3.5 * unbox(r)) for r guard unbox(r) > 0.0 in reals2));
//   s := s + "
//   ";
//   s := s + anyString(#(ListReduction.myMin(3.5 * unbox(r) for r guard abs(unbox(r)) < 3.0 in reals2)));
//   s := s + "
//   ";
//   s := s + anyString(#(0.0));
//   s := s + "
//   ";
//   realsArr3 := array(unbox(r) for r in reals1);
//   s := s + "{" + realString(realsArr3[1]) + "," + realString(realsArr3[2]) + "," + realString(realsArr3[3]) + "," + "}";
//   s := s + "
//   ";
//   s := s + anyString(#(min(unbox(r) for r in reals1)));
//   s := s + "
//   ";
//   s := s + anyString(#(max(unbox(r) for r in reals1)));
//   s := s + "
//   ";
//   s := s + anyString(#(realMax(1.5 * unbox(r) for r in reals1)));
//   s := s + "
//   ";
//   s := s + anyString(#(sum(3.5 * unbox(r) for r guard unbox(r) > 0.0 in reals2)));
//   s := s + "
//   ";
//   s := s + anyString(#(product(3.5 * unbox(r) for r guard unbox(r) > 0.0 in reals2)));
//   s := s + "
//   ";
//   s := s + anyString(#(realMin(unbox(r) for r guard unbox(r) > 2.0 in reals1)));
//   s := s + "
//   ";
//   sList := s;
//   s := "
//   ";
//   s := s + anyString(list(#(r) for r in {realsArr1[1], realsArr1[2], realsArr1[3]}));
//   s := s + "
//   ";
//   s := s + anyString(listReverse(#(r) for r in {realsArr1[1], realsArr1[2], realsArr1[3]}));
//   s := s + "
//   ";
//   s := s + anyString(listReverse(#(r) for r in {realsArr1[1], realsArr1[2], realsArr1[3]}));
//   s := s + "
//   ";
//   s := s + anyString(list(#(r) for r in {realsArr1[1], realsArr1[2], realsArr1[3]}));
//   s := s + "
//   ";
//   s := s + anyString(list(#(3.5 * r) for r guard r > 0.0 in {realsArr2[1], realsArr2[2], realsArr2[3], realsArr2[4], realsArr2[5], realsArr2[6], realsArr2[7]}));
//   s := s + "
//   ";
//   s := s + anyString(#(ListReduction.myMin(3.5 * r for r guard abs(r) < 3.0 in {realsArr2[1], realsArr2[2], realsArr2[3], realsArr2[4], realsArr2[5], realsArr2[6], realsArr2[7]})));
//   s := s + "
//   ";
//   s := s + anyString(#(0.0));
//   s := s + "
//   ";
//   realsArr3 := {realsArr1[1], realsArr1[2], realsArr1[3]};
//   s := s + "{" + realString(realsArr3[1]) + "," + realString(realsArr3[2]) + "," + realString(realsArr3[3]) + "," + "}";
//   s := s + "
//   ";
//   s := s + anyString(#(min({realsArr1[1], realsArr1[2], realsArr1[3]})));
//   s := s + "
//   ";
//   s := s + anyString(#(max({realsArr1[1], realsArr1[2], realsArr1[3]})));
//   s := s + "
//   ";
//   s := s + anyString(#(max(1.5 * realsArr1[3], max(1.5 * realsArr1[2], 1.5 * realsArr1[1]))));
//   s := s + "
//   ";
//   s := s + anyString(#(sum(3.5 * r for r guard r > 0.0 in {realsArr2[1], realsArr2[2], realsArr2[3], realsArr2[4], realsArr2[5], realsArr2[6], realsArr2[7]})));
//   s := s + "
//   ";
//   s := s + anyString(#(product(3.5 * r for r guard r > 0.0 in {realsArr2[1], realsArr2[2], realsArr2[3], realsArr2[4], realsArr2[5], realsArr2[6], realsArr2[7]})));
//   s := s + "
//   ";
//   s := s + anyString(#(realMin(r for r guard r > 2.0 in {realsArr1[1], realsArr1[2], realsArr1[3]})));
//   s := s + "
//   ";
//   sArr := s;
//   assert(sList == sArr, "Reductions are different:
//   Array:
//   " + sArr + "
//   List:
//   " + sList + "
//   ");
// end ListReduction.f;
//
// function ListReduction.myMin
//   input Real r1;
//   input Real r2;
//   output Real r = min(r1, r2);
// end ListReduction.myMin;
//
// class ListReduction
//   String s = "
//   {1, 2, 3}
//   {3, 2, 1}
//   {3, 2, 1}
//   {1, 2, 3}
//   {3.5, 7, 10.5}
//   -7
//   0
//   {1.0,2.0,3.0,}
//   1
//   3
//   4.5
//   21
//   257.25
//   3
//   ";
// end ListReduction;
// endResult
