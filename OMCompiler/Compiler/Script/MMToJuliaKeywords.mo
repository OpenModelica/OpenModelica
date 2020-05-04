encapsulated package MMToJuliaKeywords

public
constant String ABSTRACT = "abstract";
constant String BAREMODULE = "baremodule";
constant String  BEGIN = "begin";
constant String  BITSTYPE = "bitstype";
constant String  BREAK = "break";
constant String  CONST = "const";
constant String  CONTINUE = "continue";
constant String  DO = "do";
constant String  EXPORT = "export";
constant String  FOR = "for";
constant String  FUNCTION = "function";
constant String  GLOBAL = "global";
constant String  IF = "if";
constant String  IMPORT = "import";
constant String  IMPORTALL = "importall";
constant String  LET =  "let";
constant String  LOCAL = "local";
constant String  MACRO = "macro";
constant String  MODULE = "module";
constant String  QUOTE = "quote";
constant String  RETURN = "return";
constant String  STRUCT = "struct";
constant String  TRY = "try";
constant String  TYPE = "type";
constant String  TYPEALIAS = "typealias";
constant String  USING = "using";
constant String  WHILE = "while";

// public constant list<String> KEYWORDS := list(ABSTRACT,
//                                               BITSTYPE,
//                                               BLOCK,
//                                               CALL,
//                                               CATCH,
//                                               CONST) "List of Julia keywords";
annotation(__OpenModelica_Interface="backend");
end MMToJuliaKeywords;
