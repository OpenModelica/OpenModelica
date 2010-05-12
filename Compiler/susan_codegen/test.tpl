spackage test
  
  package builtin
	function testfn
	  input String inString;
	  output Integer outString;
	end testfn;
	
	function listLength "Return the length of the list"
      replaceable type TypeVar subtypeof Any;    
      input list<TypeVar> lst;
      output Integer result;
    end listLength;
    
    function listMember "Verify if an element is part of the list"
      replaceable type TypeVar subtypeof Any;
      input TypeVar element;
      input list<TypeVar> lst;
      output Boolean result;
    end listMember;
	
	function listGet "Return the element of the list at the given index.
                      The index starts from 1."
      input list<TypeVar> lst;
      input Integer index;
      output TypeVar result;
      replaceable type TypeVar subtypeof Any;
    end listGet;
	
	function listReverse "Reverse the order of elements in the list"
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      output list<TypeVar> result;
    end listReverse;
	
  end builtin;
  
  package TplAbsyn
    type Ident = String;
  	type TypedIdents = list<tuple<Ident, PathIdent>>;
	
	  uniontype PathIdent
	    record IDENT
	      Ident ident;    
	    end IDENT;
	  
	    record PATH_IDENT
	      Ident ident;
	      PathIdent path;
	    end PATH_IDENT;
	  end PathIdent;
  end TplAbsyn;


template pathIdent(PathIdent) "bla" ::= 
  case IDENT      then ident
  case PATH_IDENT then '<%ident%>.<%pathIdent(path)%>'
end pathIdent;

template typedIdents(TypedIdents decls) ::= 
(decls of (id,pid) : 
   '<%pathIdent(pid)%> <%id%>;//heja' 
   \n 
)
end typedIdents;

template test(list<String> items, Integer ind) ::= (items ind; align=testfn(ind); alignSeparator='ss<%ind%>'; wrapSeparator=testfn(2))
end test;

template test2(list<String> items, String sep, Integer a) ::= (items sep; align=a)
end test2;

template test3(list<String> items, String item, Integer ii) ::= 
  <<
  <%[items, item, ii] of st: 'bla<%st%>' \n%>
  <%[items, item, ii, ([items, item, ii]\n), "blaaa" ] ", "%>
  <%[items, item, ii] ", "/*]*/%>!!!!!error should be
  <%[items, item, ii, ([items, item, ii]\n), "blaaa" ] : case it then it ", "%>
  <%match 'aha<%ii%>' case it then it%>
  >>
end test3;

template testCond(Option<tuple<String,Integer>> nvOpt) ::= 
  if nvOpt is SOME((name,value)) then '<%name%> = <%value%>;'
  else "no value"
end testCond;

template testCond2(Option<tuple<String,Integer>> nvOpt) ::= 
  if nvOpt is not SOME((name,value)) then "none" 
  else 'SOME(<%name%>,<%value%>)' 
end testCond2;

template mapInt(Integer) ::= '(int:<%it%>)'
end mapInt;

template mapString(String) ::= '(str:<%it%>)'
end mapString;

template mapIntString(Integer intPar, String stPar) ::= '(int:<%intPar%>,str:<%stPar%>)'
end mapIntString;

template testMap(list<Integer> ints) ::= (ints : mapInt() : mapString() ", ")
end testMap;

template testMap2(list<Integer> ints) ::= (ints of int : mapInt() of st : mapIntString(int, st) ", ")
end testMap2;

template testMap3(list<list<Integer>> lstOfLst) ::= 
	(lstOfLst of intLst : 
		(intLst of int : mapInt(int) ", ") 
	";\n"; anchor)
end testMap3;

template testMap4(list<list<Integer>> lstOfLst) ::= lstOfLst : it : mapInt()
end testMap4;

template testMap5(list<Integer> ints) ::= (ints : mapString(mapInt()) ", ")
end testMap5;

template intMatrix(list<list<Integer>> lstOfLst) ::= 
<< 
[ <%lstOfLst of intLst : 
		(intLst ", ") 
   ";\n"; anchor%> ]
>>
end intMatrix;

template ifTest(Integer i) ::= if mapInt(i) then '<%it%> name;' else "/* weird I */"
end ifTest;

template bindTest() ::= 
  ifTest(1) of ii : 
    <<
      some hej<%ii%>
    >>
end bindTest;

template txtTest() ::= 
  # txt = "ahoj"
  # txt += "hej"
  txt
end txtTest;

template txtTest2() ::= 
# txt = "ahoj2"
# txt += "hej2"
<<
bláá <%txt%>
  <%/* jhgjhgjh  */%>  
jo
>>
end txtTest2;

template txtTest3(String hej, Text buf) ::= 
# txt = "aahoj2"
# txt += "ahej2"
# buf += txt 
# buf += '<%txtTest4("ha!",buf)%>ahoj' //TODO: not allow this ...  
<<
abláá <%txt%>
  <%/* jhgjhgjh  */%>  
ajo
>>
end txtTest3;

template txtTest4(String hej, Text buf) ::= 
if hej then 
  # txt = "ahoj2"
  # txt += hej
  # buf += txt
  <<
  bláá <%txt%>
  <%/* jhgjhgjh  */%>  
  jo
  >>
end txtTest4;

template txtTest5(String hej, Text buf, Text nobuf) ::= 
# txt = "aahoj2" 
# txt += "ahej2"
# buf += txt
# buf += '<%txtTest4("ha!",buf)%>ahoj' //TODO: not allow this ...  
<<
abláá <%txt%>
  <%/* jhgjhgjh  */%>  
ajo
>>
end txtTest5;

template txtTest6(list<String> hej, Text buf) ::=
  # mytxt = "bolo"
  # nomut = ','
  
  case "1"::_ then
    # buf2 = "hop"
    (hej : 
      # buf2 += it 
      # mytxt += '<%it%>jo'
      '<%it%><%nomut%>'
     nomut)
  
  case h::_ then
    # buf2 = "hop"
    (h : 
      # buf2 += it 
      # mytxt += '<%it%>jo'
      '<%it%><%nomut%>'
     nomut)
end txtTest6;

template contCase(String tst) ::=
  case "a"
  case "b"
  case "bb"
  case "c" then "hej"
  case "d" then "Hej!"
end contCase;

template contCase2(PathIdent) ::=
  case IDENT
  case PATH_IDENT 
  case IDENT(ident = "ii")
    then 'id=<%ident%>'
  case IDENT then "hej"


/*
  case skdflk then
    <<
    something
    >>
  case sdjfk then <<
    something
  >>
  
  if sdklfn then 
    <<
    bla something
    dfgf
    >> 
  else 
    <<
    bla else something
    sdf
    >>
 */
end contCase2;

template genericTest(list<String> lst) ::= listLength(lst)  
end genericTest;

template genericTest2(list<Integer> lst) ::= listLength(lst)
end genericTest2;

template genericTest3(list<Integer> lst) ::= listMember(3,lst)
end genericTest3;

template genericTest4(list<String> lst) ::= listMember("ahoj",lst)
end genericTest4;

template genericTest5(list<String> lst, String hoj) ::= listMember('a<%hoj%>',lst)
end genericTest5;

template genericTest6(list<String> lst, Integer idx) ::= listGet(lst,idx)
end genericTest6;

template genericTest7(list<Integer> lst, Integer idx) ::= listGet(lst,idx)
end genericTest7;

template genericTest8(list<Integer> lst) ::= listReverse(lst) : '<%it%>th revesed'
end genericTest8;

template genericTest9(list<list<String>> lst) ::= listReverse() : listReverse() : '<%it%>hej!'
end genericTest9;

//Error - unmatched type for type variable 'TypeVar'. Firstly inferred 'String', next inferred 'Integer'(dealiased 'Integer').
//genericTest10(list<Integer> lst) ::= listMember("3",lst) 
/* new syntax
current:  tuple2Val of (a,b) : expr

proposal: let a,b = tuple2Val; expr
      or: let a,b = tuple2Val expr 

current:  multiValue of itVal: expr  
proposal: multiValue map itVal -> expr

current:  multiValue of pattern: expr
proposal: multiValue filter pattern -> expr

examples:

current:
mapInt(Integer) ::= '(int:<%it%>)'
mapString(String) ::= '(str:<%it%>)'
mapIntString(Integer intPar, String stPar) ::= '(int:<%intPar%>,str:<%stPar%>)'

testMap(list<Integer> ints) ::= (ints : mapInt() : mapString() ", ")
testMap2(list<Integer> ints) ::= (ints of int : mapInt() of st : mapIntString(int, st) ", ")
testMap3(list<list<Integer>> lstOfLst) ::= 
	(lstOfLst of intLst : 
		(intLst of int : mapInt(int) ", ") 
	";\n"; anchor)
testMap4(list<list<Integer>> lstOfLst) ::= lstOfLst : (lst : mapInt())
testMap5(list<Integer> ints) ::= (ints : mapString(mapInt()) ", ")


proposal:
mapInt(Integer) ::= '(int:<%it%>)'
mapString(String) ::= '(str:<%it%>)'
mapIntString(Integer intPar, String stPar) ::= '(int:<%intPar%>,str:<%stPar%>)'

testMap(list<Integer> ints) ::= (ints map i -> mapInt(i) map mi -> mapString(mi) ", ")
testMap2(list<Integer> ints) ::= (ints map int -> mapInt(int) map st -> mapIntString(int, st) ", ")
testMap3(list<list<Integer>> lstOfLst) ::= 
	(lstOfLst map intLst -> 
		(intLst map int -> mapInt(int) ", ") 
	";\n"; anchor)
testMap4(list<list<Integer>> lstOfLst) ::= lstOfLst map it -> it map it -> mapInt(it)
testMap5(list<Integer> ints) ::= (ints map i -> mapString(mapInt(i)) ", ")

or

testMap(list<Integer> ints) ::= (ints | i -> mapInt(i) | mi -> mapString(mi) ;separ = ", ")
testMap2(list<Integer> ints) ::= (ints | int -> mapInt(int) | st -> mapIntString(int, st) ;separ = ", ")
testMap3(list<list<Integer>> lstOfLst) ::= 
	(lstOfLst | intLst -> 
		(intLst | int -> mapInt(int) ; separ = ", ") 
	; separ = ";\n"; anchor)
testMap4(list<list<Integer>> lstOfLst) ::= lstOfLst | intLst -> intLst | it -> mapInt(it)
testMap5(list<Integer> ints) ::= (ints | i -> mapString(mapInt(i)) ; separ = ", ")

lstOfLst | intLst -> (intLst | it -> mapInt(it)) 

lstOfLst | intLst -> intLst | it -> mapInt(it) //not correct!! 

lstOfLst | intLst -> 
	let outerIndex = i0 
	(intLst | it -> 
		'<<outerIndex>>/<<i0>> ... <<mapInt(it)>>') 


lstOfLst |> map (fun lst -> lst |> map (fun it -> mapInt(it)) )

lstOfLst |> map intLst -> (intLst |> map it -> mapInt(it))

testMap(list<Integer> ints) ::=
	<< >>

<<	
private static readonly SimVarInfo[] VariableInfosStatic = new[] {
	<% {  
		filter vars.stateVars with SIMVAR then 
		
		map vars.stateVars with el then
		 
		  <<
		  new SimVarInfo( "(% cref(origName) %)", "(%comment%)", SimVarType.State, <% index %>, false)
		  >>; separator=",\n"
		,
		vars.derivativeVars |? SIMVAR => <<
		new SimVarInfo( "<% cref(origName) %>", "<% comment %>", SimVarType.StateDer, <% index %>, false)
		>>; separator=",\n"
		,
		(vars.algVars of SIMVAR: <<
		new SimVarInfo( "<cref(origName)>", "<comment>", SimVarType.Algebraic, <index>, false)
		>>; separator=",\n"),
		(vars.paramVars of SIMVAR: <<
		new SimVarInfo( "<cref(origName)>", "<comment>", SimVarType.Parameter, <index>, true)
		>>; separator=",\n")
	}; separator=",\n\n" %>
};  

*/
/*
typeTempl(list<String> lst) ::= lst

typeTemplCall(list<String> lst) ::= '<%typeTempl( (lst) )> hoop'

multiTest(list<String> lst, String s, String s2, list<String> lst2) ::=
	([lst, s, lst2, s2] ; separator=",")

multiTest2(list<String> lst, String s, String s2, list<String> lst2) ::=
	([lst : if it then it, s, lst2, s2] ; separator=",")

multiTest23(list<String> lst, String s, String s2, list<String> lst2) ::=
	([lst : if it then it, s, '<%lst2>', s2] : 'bla<%it>' ; separator=",") //!! TODO: '<%lst2>' is same as lst2 ... it is not reduced
*/
end test;
