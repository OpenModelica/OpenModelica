package BuiltinList

  function func
    input List<Integer> lst;
    input Integer i;
    output List<Integer> reverse;
    output List<Integer> appendDupe;
    output Integer len;
    output Boolean hasMember;
    output Integer getIx;
    output List<Integer> deleteIx;
  algorithm
    reverse := listReverse(lst);
    appendDupe := listAppend(lst,lst);
    len := listLength(lst);
    hasMember := listMember(i, lst);
    getIx := listGet(lst, i);
    deleteIx := listDelete(lst, i+1);
  end func;

  uniontype UT
    record UT1
      List<tuple<Integer,Option<Integer>>> lst;
    end UT1;
  end UT;

  type T1 = tuple<Integer,Real,Boolean,String,UT>;

  function funcTuple
    input List<T1> lst;
    input T1 member;
    input Integer i;
    output List<T1> reverse;
    output List<T1> appendDupe;
    output Integer len;
    output Boolean hasMember1;
    output Boolean hasMember2;
    output T1 getIx;
    output List<T1> deleteIx;
    output List<T1> consIx;
  protected
    Integer i2;
    Real r;
    Boolean b;
    String s;
    UT ut;
  algorithm
    reverse := listReverse(lst);
    appendDupe := listAppend(lst,lst);
    len := listLength(lst);
    hasMember1 := listMember(member, lst);
    (i2,r,b,s,ut) := member;
    hasMember2 := listMember((i2,r,b,s,ut), lst); // We also need to see if we can call listMember with a tuple
    getIx := listGet(lst, i);
    deleteIx := listDelete(lst, i+1);
    consIx := cons(member, {});
  end funcTuple;

end BuiltinList;
