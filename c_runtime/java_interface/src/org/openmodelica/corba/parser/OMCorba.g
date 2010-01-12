// ANTLRv3 Grammar to parse the corba output from OMC to Java structures
grammar OMCorba;

options {
k=1;
}

@header {package org.openmodelica.corba.parser;
import java.util.LinkedHashMap;
import java.util.Vector;
import org.openmodelica.*;}
@lexer::header {package org.openmodelica.corba.parser;}

@members {
protected ModelicaObject memory;
private String key;
}


prog: object EOF
    | EOF {memory = new ModelicaVoid();};

object: INT {memory = new ModelicaInteger($INT.int);}
      | REAL {memory = new ModelicaReal(new Double($REAL.text));}
      | BOOL {memory = new ModelicaBoolean(new Boolean($BOOL.text));}
      | STRING {memory = new ModelicaString($STRING.text.substring(1,$STRING.text.length()-1), true);}
      // | STRING {memory = new ModelicaString($STRING.text.substring(1,$STRING.text.length()-1), false);}
      | record
      | array
      | tuple
      | option;

record : 'record' {LinkedHashMap<String,ModelicaObject> map = new LinkedHashMap<String,ModelicaObject>();}
         id1=ident
         (field {map.put(key, memory);} (',' field {map.put(key, memory);})*)?
         'end' id2=ident {if (!$id1.text.equals($id2.text)) throw new RecognitionException(input);} ';'
         {try {memory = new ModelicaRecord($id1.text, map);} catch (ModelicaRecordException ex) {throw new RecognitionException(input);}};

array : '{' {Vector<ModelicaObject> vector = new Vector<ModelicaObject>();}
         (object {vector.add(memory);}
         (',' object {vector.add(memory);})*)?
        '}' {try{memory = ModelicaArray.createModelicaArray(vector);} catch (ModelicaObjectException ex) {throw new RecognitionException(input);}};

tuple : '(' {ModelicaTuple tuple = new ModelicaTuple();}
        (object {tuple.add(memory);}
        (',' object {tuple.add(memory);})*)?
        ')' {memory = tuple;};
        
option : 'NONE()' {memory = new ModelicaOption(null);}
       | 'SOME(' object ')' {memory = new ModelicaOption(memory);};

ident : ID | FQID;

field : ID '=' object {key = new String($ID.text);};

BOOL : 'true'|'false';
FQID : (ID '.')+ ID;
ID : ('_'|'a'..'z'|'A'..'Z')('_'|'a'..'z'|'A'..'Z'|'0'..'9')* |
     '\''(~('\\'|'\'')|'\\\''  | '\\"'| '\\?' | '\\\\' | '\\a' | '\\b' | '\\f' | '\\n' | '\\r' | '\\t' | '\\v')*'\'';
STRING : '"'('\\"'|~'"')*'"';
REAL : '-'? (('.''0'..'9'+)|('0'..'9'+'.''0'..'9'*))(('e'|'E')(('+'|'-')?'0'..'9'+))? |
       '-'? '0'..'9'+('e'|'E')(('+'|'-')?'0'..'9'+);
INT :  '-'?'0'..'9'+ ;
WS  :   ('\r'|'\n'|' '|'\t')+ {skip();} ;
