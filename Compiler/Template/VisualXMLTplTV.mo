interface package VisualXMLTplTV

  package builtin
    function arrayGet
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      input Integer index;
      output TypeVar value;
    end arrayGet;

    function arrayLength
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      output Integer length;
    end arrayLength;

    function listReverse
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      output list<TypeVar> result;
    end listReverse;

    function listLength "Return the length of the list"
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      output Integer result;
    end listLength;

    function intAdd
      input Integer a;
      input Integer b;
      output Integer c;
    end intAdd;

    function boolAnd
      input Boolean b1;
      input Boolean b2;
      output Boolean b;
    end boolAnd;

    function boolOr
      input Boolean a;
      input Boolean b;
      output Boolean c;
    end boolOr;

    function boolNot
      input Boolean b;
      output Boolean nb;
    end boolNot;

    function intSub
      input Integer a;
      input Integer b;
      output Integer c;
    end intSub;

    function intMul
      input Integer a;
      input Integer b;
      output Integer c;
    end intMul;

    function intDiv
      input Integer a;
      input Integer b;
      output Integer c;
    end intDiv;

    function intEq
      input Integer a;
      input Integer b;
      output Boolean c;
    end intEq;

    function intGt
      input Integer i1;
      input Integer i2;
      output Boolean b;
    end intGt;

    function intString
      input Integer i;
      output String s;
    end intString;

    function realInt
      input Real r;
      output Integer i;
    end realInt;

    function realString
      input Real r;
      output String s;
    end realString;

    function arrayList
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      output list<TypeVar> lst;
    end arrayList;

    function stringEq
      input String s1;
      input String s2;
      output Boolean b;
    end stringEq;

    function listAppend
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      input list<TypeVar> lst1;
      output list<TypeVar> result;
    end listAppend;

    function realDiv
      input Real x;
      input Real y;
      output Real z;
    end realDiv;
  end builtin;

  package Tpl
    function textFile
      input Text inText;
      input String inFileName;
    end textFile;
  end Tpl;

  package Util
    function tuple21
      replaceable type TypeA subtypeof Any;
      input tuple<TypeA, TypeB> inTplTypeATypeB;
      output TypeA outTypeA;
      replaceable type TypeB subtypeof Any;
    end tuple21;
    function tuple22
      replaceable type TypeA subtypeof Any;
      input tuple<TypeA, TypeB> inTplTypeATypeB;
      output TypeA outTypeA;
      replaceable type TypeB subtypeof Any;
    end tuple22;
  end Util;

  package VisualXML
		uniontype Visualization
		  record SHAPE
		    DAE.ComponentRef ident;
		    String shapeType;
		    array<list<DAE.Exp>> T;
		    array<DAE.Exp> r;
		    array<DAE.Exp> r_shape;
		    array<DAE.Exp> lengthDir;
		    array<DAE.Exp> widthDir;
		    DAE.Exp length;
		    DAE.Exp width;
		    DAE.Exp height;
		    DAE.Exp extra;
		    array<DAE.Exp> color;
		    DAE.Exp specularCoeff;
		  end SHAPE;
		end Visualization;
  end VisualXML;

  package ExpressionDump
    function printExpStr
      input DAE.Exp e;
      output String s;
    end printExpStr;
  end ExpressionDump;

	package DAE
	  uniontype Exp
	    record ICONST
	      Integer integer "Integer constants" ;
	    end ICONST;

	    record RCONST
	      Real real "Real constants" ;
	    end RCONST;

	    record SCONST
	      String string "String constants" ;
	    end SCONST;

	    record BCONST
	      Boolean bool "Bool constants" ;
	    end BCONST;

	    record ENUM_LITERAL "Enumeration literal"
	      Absyn.Path name;
	      Integer index;
	    end ENUM_LITERAL;

	    record CREF "component references, e.g. a.b{2}.c{1}"
	      ComponentRef componentRef;
	      Type ty;
	    end CREF;

	    record BINARY "Binary operations, e.g. a+4"
	      Exp exp1;
	      Operator operator;
	      Exp exp2;
	    end BINARY;

	    record UNARY "Unary operations, -(4x)"
	      Operator operator;
	      Exp exp;
	    end UNARY;

	    record LBINARY "Logical binary operations: and, or"
	      Exp exp1;
	      Operator operator;
	      Exp exp2;
	    end LBINARY;

	    record LUNARY "Logical unary operations: not"
	      Operator operator;
	      Exp exp;
	    end LUNARY;

	    record RELATION
	      Exp exp1;
	      Operator operator;
	      Exp exp2;
	      Integer index;
	      Option<tuple<Exp,Integer,Integer>> optionExpisASUB;
	    end RELATION;

	    record IFEXP "If expressions"
	      Exp expCond;
	      Exp expThen;
	      Exp expElse;
	    end IFEXP;

	    record CALL
	      Absyn.Path path;
	      list<Exp> expLst;
	      CallAttributes attr;
	    end CALL;

	    record PARTEVALFUNCTION
	      Absyn.Path path;
	      list<Exp> expList;
	      Type ty;
	    end PARTEVALFUNCTION;

	    record ARRAY
	      Type ty;
	      Boolean scalar "scalar for codegen" ;
	      list<Exp> array "Array constructor, e.g. {1,3,4}" ;
	    end ARRAY;

	    record MATRIX
	      Type ty;
	      Integer integer;
	      list<list<Exp>> matrix;
	    end MATRIX;

	    record RANGE
	      Type ty;
	      Exp start "start value";
	      Option<Exp> step "step value";
	      Exp stop "stop value" ;
	    end RANGE;

	    record TUPLE
	      list<Exp> PR "PR. Tuples, used in func calls returning several
	                    arguments" ;
	    end TUPLE;

	    record CAST "Cast operator"
	      Type ty "This is the full type of this expression, i.e. ET_ARRAY(...) for arrays and matrices";
	      Exp exp;
	    end CAST;

	    record ASUB "Array subscripts"
	      Exp exp;
	      list<Exp> sub;
	    end ASUB;

	    record TSUB "Tuple 'subscript' (accessing only single values in calls)"
	      Exp exp;
	      Integer ix;
	      Type ty;
	    end TSUB;

	    record SIZE "The size operator"
	      Exp exp;
	      Option<Exp> sz;
	    end SIZE;

	    record CODE "Modelica AST constructor"
	      Absyn.CodeNode code;
	      Type ty;
	    end CODE;

	    record EMPTY
	      String scope "the scope where we could not find the binding";
	      ComponentRef name "the name of the variable";
	      Type ty "the type of the variable";
	      String tyStr;
	    end EMPTY;

	    record REDUCTION "e.g. sum(i*i+1 for i in 1:4)"
	      ReductionInfo reductionInfo;
	      Exp expr "expr, e.g i*i+1" ;
	      ReductionIterators iterators;
	    end REDUCTION;

	    record LIST "MetaModelica list"
	      list<Exp> valList;
	    end LIST;

	    record CONS "MetaModelica list cons"
	      Exp car;
	      Exp cdr;
	    end CONS;

	    record META_TUPLE
	      list<Exp> listExp;
	    end META_TUPLE;

	    record META_OPTION
	      Option<Exp> exp;
	    end META_OPTION;

	    record METARECORDCALL //Metamodelica extension, simbj
	      Absyn.Path path;
	      list<Exp> args;
	      list<String> fieldNames;
	      Integer index; //Index in the uniontype
	    end METARECORDCALL;

	    record MATCHEXPRESSION
	      MatchType matchType;
	      list<Exp> inputs;
	      list<Element> localDecls;
	      list<MatchCase> cases;
	      Type et;
	    end MATCHEXPRESSION;

	    record BOX "MetaModelica boxed value"
	      Exp exp;
	    end BOX;

	    record UNBOX "MetaModelica value unboxing (similar to a cast)"
	      Exp exp;
	      Type ty;
	    end UNBOX;

	    record SHARED_LITERAL
	      "Before code generation, we make a pass that replaces constant literals
	      with a SHARED_LITERAL expression. Any immutable type can be shared:
	      basic MetaModelica types and Modelica strings are fine. There is no point
	      to share Real, Integer, Boolean or Enum though."
	      Integer index;
	      Type ty "The type is required for code generation to work properly";
	    end SHARED_LITERAL;

	    record PATTERN "(x,1,ROOT(a as _,false,_)) := rhs; MetaModelica extension"
	      Pattern pattern;
	    end PATTERN;
	  end Exp;

		uniontype Operator
		  record ADD
		    Type ty;
		  end ADD;

		  record SUB
		    Type ty;
		  end SUB;

		  record MUL
		    Type ty;
		  end MUL;

		  record DIV
		    Type ty;
		  end DIV;

		  record POW
		    Type ty;
		  end POW;

		  record UMINUS
		    Type ty;
		  end UMINUS;

		  record UMINUS_ARR
		    Type ty;
		  end UMINUS_ARR;

		  record ADD_ARR
		    Type ty;
		  end ADD_ARR;

		  record SUB_ARR
		    Type ty;
		  end SUB_ARR;

		  record MUL_ARR "Element-wise array multiplication"
		    Type ty;
		  end MUL_ARR;

		  record DIV_ARR
		    Type ty;
		  end DIV_ARR;

		  record MUL_ARRAY_SCALAR " {a,b,c} * s"
		    Type ty "type of the array" ;
		  end MUL_ARRAY_SCALAR;

		  record ADD_ARRAY_SCALAR " {a,b,c} .+ s"
		    Type ty "type of the array";
		  end ADD_ARRAY_SCALAR;

		  record SUB_SCALAR_ARRAY "s .- {a,b,c}"
		    Type ty "type of the array" ;
		  end SUB_SCALAR_ARRAY;

		  record MUL_SCALAR_PRODUCT " {a,b,c} * {c,d,e} => a*c+b*d+c*e"
		    Type ty "type of the array" ;
		  end MUL_SCALAR_PRODUCT;

		  record MUL_MATRIX_PRODUCT "M1 * M2, matrix dot product"
		    Type ty "{{..},..}  {{..},{..}}" ;
		  end MUL_MATRIX_PRODUCT;

		  record DIV_ARRAY_SCALAR "{a, b} / c"
		    Type ty  "type of the array";
		  end DIV_ARRAY_SCALAR;

		  record DIV_SCALAR_ARRAY "c / {a,b}"
		    Type ty "type of the array" ;
		  end DIV_SCALAR_ARRAY;

		  record POW_ARRAY_SCALAR
		    Type ty "type of the array" ;
		  end POW_ARRAY_SCALAR;

		  record POW_SCALAR_ARRAY
		    Type ty "type of the array" ;
		  end POW_SCALAR_ARRAY;

		  record POW_ARR "Power of a matrix: {{1,2,3},{4,5.0,6},{7,8,9}}^2"
		    Type ty "type of the array";
		  end POW_ARR;

		  record POW_ARR2 "elementwise power of arrays: {1,2,3}.^{3,2,1}"
		    Type ty "type of the array";
		  end POW_ARR2;

		  record AND
		    Type ty;
		  end AND;

		  record OR
		    Type ty;
		  end OR;

		  record NOT
		    Type ty;
		  end NOT;

		  record LESS
		    Type ty;
		  end LESS;

		  record LESSEQ
		    Type ty;
		  end LESSEQ;

		  record GREATER
		    Type ty;
		  end GREATER;

		  record GREATEREQ
		    Type ty;
		  end GREATEREQ;

		  record EQUAL
		    Type ty;
		  end EQUAL;

		  record NEQUAL
		    Type ty;
		  end NEQUAL;

		  record USERDEFINED
		    Absyn.Path fqName "The FQ name of the overloaded operator function" ;
		  end USERDEFINED;

		end Operator;

	  uniontype ComponentRef
		  record CREF_QUAL
		    Ident ident;
		    Type identType "type of the identifier, without considering the subscripts";
		    list<Subscript> subscriptLst;
		    ComponentRef componentRef;
		  end CREF_QUAL;

		  record CREF_IDENT
		    Ident ident;
		    Type identType "type of the identifier, without considering the subscripts";
		    list<Subscript> subscriptLst;
		  end CREF_IDENT;

		  record CREF_ITER "An iterator index; used in local scopes in for-loops and reductions"
		    Ident ident;
		    Integer index;
		    Type identType "type of the identifier, without considering the subscripts";
		    list<Subscript> subscriptLst;
		  end CREF_ITER;

		  record OPTIMICA_ATTR_INST_CREF "An Optimica component reference with the time instant in it. e.g x2(finalTime)"
		    ComponentRef componentRef;
		    String instant;
		  end OPTIMICA_ATTR_INST_CREF;

		  record WILD end WILD;
	  end ComponentRef;
	end DAE;

	package ComponentReference
	  function printComponentRefStr
	    input DAE.ComponentRef inComponentRef;
	    output String outString;
	  end printComponentRefStr;
	end ComponentReference;

	package Absyn
	  function pathString
	    input Path path;
	    output String s;
	  end pathString;
	end Absyn;

end VisualXMLTplTV;
