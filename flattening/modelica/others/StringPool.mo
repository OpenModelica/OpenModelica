// name: StringPool
// cflags: -d=noevalfunc,gen
// status: correct
// teardown_command: rm -f StringPool_*
//
// Tests that the stringpool runtime returns proper strings from
// function calls

package StringPool

function weirdStrStuff
  input String str;
  output String os1;
  output String os2;
algorithm
  os1 := "os1";
  os2 := "os2";
end weirdStrStuff;

function weirdStrStuff1
  input String str;
  output String os;
protected
  String os1,os2;
algorithm
  (os1,os2) := weirdStrStuff(str);
  os := "overwritethecharpoolhere";
  os := os1+os2;
end weirdStrStuff1;

  constant String str1 = weirdStrStuff1("abc");
end StringPool;

// Result:
// function StringPool.weirdStrStuff
//   input String str;
//   output String os1;
//   output String os2;
// algorithm
//   os1 := "os1";
//   os2 := "os2";
// end StringPool.weirdStrStuff;
//
// function StringPool.weirdStrStuff1
//   input String str;
//   output String os;
//   protected String os1;
//   protected String os2;
// algorithm
//   (os1, os2) := StringPool.weirdStrStuff(str);
//   os := "overwritethecharpoolhere";
//   os := os1 + os2;
// end StringPool.weirdStrStuff1;
//
// class StringPool
//   constant String str1 = "os1os2";
// end StringPool;
// endResult
