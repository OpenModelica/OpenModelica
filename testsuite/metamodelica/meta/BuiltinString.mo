package BuiltinString

  function func
    input String str1;
    input String str2;
    input String chr;
    input Integer i;
    output String str12_op;
    output String str12_fn;
    output Integer str12_fn_length;
    output Integer str1_2_comp;
    output Boolean str1_2_eq;
    output String str12_fn_char_i;
    output Integer str12_int;
    output Real str12_real;
    output list<String> str12_chars;
    output String str12_chars_rev_str;
    output String str12_chars_rev_str_updated;
    output Integer asciiVal;
    output String asciiChar;
  algorithm
    str12_op := str1 + str2;
    str12_fn := stringAppend(str1,str2);
    str12_fn_length := stringLength(str12_fn);
    str1_2_comp := stringCompare(str1,str2);
    str1_2_eq := stringEq(str1,str2);
    str12_fn_char_i := stringGetStringChar(str12_fn,i);
    str12_int := stringInt(str12_fn);
    str12_real := stringReal(str12_fn);
    str12_chars := stringListStringChar(str12_fn);
    str12_chars_rev_str := listStringCharString(listReverse(str12_chars));
    str12_chars_rev_str_updated := stringUpdateStringChar(str12_chars_rev_str, chr, i);
    asciiVal := stringCharInt(chr);
    asciiChar := intStringChar(i+64 /* 65 = ASCII 'A' */);
  end func;

  function funcStringAppendList
    input list<String> lst;
    output String out;
  algorithm
    out := stringAppendList(lst);
  end funcStringAppendList;

end BuiltinString;
