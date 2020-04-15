encapsulated package MMToJuliaKeywords

public
constant String  ABSTRACT = "abstract";
constant String  ARRAY = "array";
constant String  BAREMODULE = "baremodule";
constant String  BEGIN = "begin";
constant String  BITSTYPE = "bitstype";
constant String  BOOLEAN = "Boolean";
constant String  BREAK = "break";
constant String  CONST = "const";
constant String  CONTINUE = "continue";
constant String  DO = "do";
constant String  EXPORT = "export";
constant String  FOR = "for";
constant String  FUNCTION_LC = "function";
constant String  GLOBAL = "global";
constant String  IF = "if";
constant String  IMPORT = "import";
constant String  IMPORTALL = "importall";
constant String  LET =  "let";
constant String  LIST = "list";
constant String  LOCAL = "local";
constant String  MACRO = "macro";
constant String  MODULE = "module";
constant String  MUTABLE = "mutable";
constant String  POLYMORPHIC = "polymorphic";
constant String  QUOTE = "quote";
constant String  REAL = "Real";
constant String  RETURN = "return";
constant String  STRUCT = "struct";
constant String  TRY = "try";
constant String  TUPLE = "tuple";
constant String  TYPE_LC = "type";
constant String  TYPE_UC = "Type";
constant String  TYPEALIAS = "typealias";
constant String  USING = "using";
constant String  WHILE = "while";
constant String  FUNCTION_UC = "Function";

encapsulated package MM_INDEPENDENT_PACKAGES
"Some modules can be readily used without refeering to the Main module.
This is a way of getting around the Julia package system."
/*TODO: Add me:)*/
constant String ARRAY = "ARRAY";
constant String LIST = "LIST";
end MM_INDEPENDENT_PACKAGES;

annotation(__OpenModelica_Interface="backend");
end MMToJuliaKeywords;
