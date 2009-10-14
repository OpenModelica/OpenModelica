grammar OMCorbaDefinitions;

options {
	language = Java;
	output = none;
	k = 2;
}

@header {package org.openmodelica.corba.parser;import java.util.Vector;}
@lexer::header {package org.openmodelica.corba.parser;}

@members {
public Vector<PackageDefinition> defs = new Vector<PackageDefinition>();
public SymbolTable st = new SymbolTable();
private Object memory;
private String curPackage;
protected Object recoverFromMismatchedToken(IntStream input, int ttype, BitSet follow) throws RecognitionException {
  MismatchedTokenException ex = new MismatchedTokenException(ttype, input);
  throw ex;
}
}

definitions : {this.curPackage = null; PackageDefinition pack = new PackageDefinition(null);}
  '(' (object {pack.add(memory);})* ')' EOF {defs.add(pack); memory = null; st.add(pack, null);};

object : package_ | record | function | uniontype | typedef | replaceable_type;

package_ : '(' 'package' ID {String oldPackage = curPackage; curPackage = (curPackage != null ? curPackage + "." + $ID.text : $ID.text); PackageDefinition pack = new PackageDefinition(curPackage);}
           (object {pack.add(memory);})* ')' {defs.add(pack); memory = null; st.add(pack, null); curPackage = oldPackage;};
record : '(' 'record' ID1=ID {String oldPackage = curPackage; curPackage = (curPackage != null ? curPackage + "." : "") + $ID1.text ; RecordDefinition rec = new RecordDefinition($ID1.text, curPackage); PackageDefinition pack = new PackageDefinition(curPackage + ".inner");}
         ((('(' varDef ')')|extends_){rec.fields.add(memory);}
          | object {pack.add(memory);}
          )* ')' {memory = rec; curPackage = oldPackage; st.add(rec, curPackage);}
         |'(' 'metarecord' ID1=ID {String recID = $ID1.text; String oldPackage = curPackage; curPackage = (curPackage != null ? curPackage + "." : "") + $ID1.text ; RecordDefinition rec; PackageDefinition pack = new PackageDefinition(curPackage + ".inner");}
           INT {int index = $INT.int;}
           UT=ID {String uniontype = $UT.text;}
           {rec = new RecordDefinition(recID, uniontype, index, curPackage);}
           ((('(' varDef ')')|extends_){rec.fields.add(memory);}
            | object {pack.add(memory);}
            )* ')' {memory = rec; curPackage = oldPackage; st.add(rec, curPackage);};
extends_ : '(' 'extends' fqid ')';
function : '(' 'function' ID {FunctionDefinition fun = new FunctionDefinition($ID.text); String oldPackage = curPackage; curPackage = (curPackage != null ? curPackage + "." : "") + $ID.text; PackageDefinition pack = new PackageDefinition(curPackage + ".inner");}
            ( input{fun.input.add((VariableDefinition)memory);}
            | output{fun.output.add((VariableDefinition)memory);}
            | object {pack.add(memory);}
            )*
            ')' {curPackage = oldPackage; memory = fun; st.add(fun, curPackage);};
uniontype : '(' 'uniontype' ID ')' {UniontypeDefinition union = new UniontypeDefinition($ID.text); memory = union; st.add(union, curPackage);};
typedef : '(' 'partial' 'function' ID ')' {memory = new VariableDefinition(new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.FUNCTION_REFERENCE), $ID.text, curPackage);st.add((VariableDefinition)memory, curPackage);}
        | '(' 'type' ID type ')' {memory = new VariableDefinition((ComplexTypeDefinition) memory, $ID.text, curPackage); st.add((VariableDefinition)memory, curPackage);};

replaceable_type : '(' 'replaceable' 'type' ID ')' {memory = new VariableDefinition(new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.GENERIC_TYPE, "ModelicaObject"), $ID.text, curPackage); st.add((VariableDefinition)memory, curPackage);};

type : basetype
     | complextype
     | '[' INT type {memory = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.ARRAY, (ComplexTypeDefinition) memory, $INT.int);} 
     | fqid {memory = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.DEFINED_TYPE, (String) memory);};
varDef : type ID {memory = new VariableDefinition((ComplexTypeDefinition)memory, $ID.text, curPackage);};
input  : '(' 'input' varDef ')';
output : '(' 'output' varDef ')';
basetype : 'Integer' {memory = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.BUILT_IN, "ModelicaInteger");}
          |'Real' {memory = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.BUILT_IN, "ModelicaReal");}
          |'Boolean' {memory = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.BUILT_IN, "ModelicaBoolean");}
          |'String' {memory = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.BUILT_IN, "ModelicaString");};
complextype :  /* MetaModelica */
       ('list') {ComplexTypeDefinition def = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.LIST_TYPE);}
       '<' type {def.add((ComplexTypeDefinition)memory);} '>' {memory = def;}
     | ('tuple') {ComplexTypeDefinition def = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.TUPLE_TYPE);}
       '<' type (',' type)* '>' {memory = def;}
     | ('Option') {ComplexTypeDefinition def = new ComplexTypeDefinition(ComplexTypeDefinition.ComplexType.OPTION_TYPE);}
       '<' type {def.add((ComplexTypeDefinition)memory);} '>' {memory = def;};
fqid : ID {memory = $ID.text;}
     | QID {memory = $QID.text;};

QID : (ID '.')+ ID;
ID : ('_'|'a'..'z'|'A'..'Z')('_'|'a'..'z'|'A'..'Z'|'0'..'9')* |
     '\''(~('\\'|'\'')|'\\\''  | '\\"'| '\\?' | '\\\\' | '\\a' | '\\b' | '\\f' | '\\n' | '\\r' | '\\t' | '\\v')*'\'';
INT :  '-'?'0'..'9'+ ;
WS  :   ('\r'|'\n'|' '|'\t')+ {skip();} ;