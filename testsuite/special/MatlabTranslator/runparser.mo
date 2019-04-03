encapsulated package runparser
// this function is used to generate the modelica AST from the ANTLR parser generator
public function main
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> inStringLst;
  protected
  //list<OMCCTypes.Token> tokens;
 // AbsynMat.AstStart matstart;
  Absyn.Program modast;
  type Mcode_MCodeLst = list<Mcode.MCode>;
algorithm
  _ := matchcontinue (inStringLst)
    local
      String filename,unparsed,grammar;
      list<String> args;
      Boolean c;
      Real r1;
    case args as _::_
      equation
        {filename,grammar} = Flags.new(args);
         r1 = 1.0;
        c=Absyn.isDerCref(Absyn.REAL(realString(r1)));
        modast = ParserExt.parse(filename,"",1,"UTF-8",1,false);
        print (anyString(modast));
        unparsed=Dump.unparseStr(modast,false);
        print (anyString(unparsed));
        then
          ();
     end matchcontinue;
   end main;
 end runparser;