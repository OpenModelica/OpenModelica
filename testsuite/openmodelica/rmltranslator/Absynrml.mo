package Absynrml
"
  file:        Absynrml.mo
  package:     Absynrml
  description: Abstract syntax Tee constructs for the RELATIONAL META LANGUAGE(RML)
  The following are the types and uniontypes that are used for the RML AST construction"

import Absyn;

type Info= Absyn.Info;
type Ident= String;

uniontype Program
  record MODULE "RML always starts with keyword module followed by a list of interface section or definition section"
    RMLIdent rmlident;
    list<RMLInterface> rmlinterface;
    list<RMLDefinition> rmldefinition;
    Info info;
  end MODULE;
end Program;

type RMLInterface = RMLDec;

uniontype RMLDec

  record RELATION_INTERFACE
    RMLIdent ident;
    RMLType  rmltype;
  end RELATION_INTERFACE;

  record DATATYPE_INTERFACE
    RMLDatatype datatype;
    Info info;
  end DATATYPE_INTERFACE;

  record TYPE
    RMLIdent ident;
    RMLType rmltype;
    Info info;
  end TYPE;

  record WITH
    String string;
    Info info;
  end WITH;

  record VAL_INTERFACE
    RMLIdent ident;
    RMLType rmltype;
    Info info;
  end VAL_INTERFACE;
end RMLDec;

uniontype RMLDatatype
  record DATATYPE
    RMLIdent ident;
    list<DTMember> dtmember;
  end DATATYPE;
end RMLDatatype;

uniontype RMLDefinition
  record WITH_DEF
    String string;
    Info info;
  end WITH_DEF;

  record DATATYPE_DEFINITION
    RMLDatatype datatype;
    Info info;
  end DATATYPE_DEFINITION;

  record VAL_DEF
    RMLIdent ident;
    RMLExp exp;
    Info info;
  end VAL_DEF;

  record RELATION_DEFINITION
    RMLIdent ident;
    Option<RMLType> rmltype;
    list<RMLRule> rmlrule;
    Info info;
  end RELATION_DEFINITION;

end RMLDefinition;

uniontype RMLSignature
  record CALLSIGN
    list<RMLType> rmltype;
    list<RMLType> rmltype1;
  end CALLSIGN;
end RMLSignature;

uniontype RMLType

  record RMLTYPE_INT
  end RMLTYPE_INT;

  record RMLTYPE_REAL
  end RMLTYPE_REAL;

  record RMLTYPE_STRING
  end RMLTYPE_STRING;

  record RMLTYPE_NIL
  end RMLTYPE_NIL;

  record RMLTYPE_TYCONS
    list<RMLType> rmltype;
    RMLIdent ident;
  end RMLTYPE_TYCONS;

  record RMLTYPE_SIGNATURE
    RMLSignature rmlsignature;
  end RMLTYPE_SIGNATURE;

  record RMLTYPE_TUPLE
    list<RMLType> rmltype;
  end RMLTYPE_TUPLE;

  record RMLTYPE_TYVAR
    RMLIdent ident;
  end RMLTYPE_TYVAR;

  record RMLTYPE_USERDEFINED
    RMLIdent ident;
  end RMLTYPE_USERDEFINED;

end RMLType;

uniontype RMLRule
  record RMLRULE
    RMLIdent ident;
    RMLPattern rmlpattern;
    Option<RMLGoal> rmlgoal;
    RMLResult rmlresult;
    Info info;
  end RMLRULE;
end RMLRule;

uniontype RMLResult
  record RETURN
    list<RMLExp> exp;
    Info info;
  end RETURN;
  record FAIL
  end FAIL;
  record EMPTY_RESULT
  end EMPTY_RESULT;
end RMLResult;

uniontype RMLGoal

  record RMLGOAL_NOT
    RMLGoal rmlgoal;
    Info info;
  end RMLGOAL_NOT;

  record RMLGOAL_AND
    RMLGoal rmlgoal;
    RMLGoal rmlgoal1;
  end RMLGOAL_AND;

  record RMLGOAL_PAT
    RMLPattern rmlpattern;
  end RMLGOAL_PAT;

  record RMLGOAL_LET
    RMLPattern rmlpattern;
    RMLExp exp;
    Info info;
  end RMLGOAL_LET;

  record RMLGOAL_EQUAL
    RMLIdent ident;
    RMLExp exp;
    Info info;
  end RMLGOAL_EQUAL;

  record RMLGOAL_RELATION
    RMLIdent ident;
    list<RMLExp> exp;
    Option<RMLPattern> rmlpattern;
    Info info;
  end RMLGOAL_RELATION;
end RMLGoal;

uniontype RMLPattern
  record RMLPAT_WILDCARD
  end RMLPAT_WILDCARD;

  record RMLPAT_LITERAL
    RMLLiteral rmlliteral;
  end RMLPAT_LITERAL;

  record RMLPAT_IDENT
    RMLIdent ident;
  end RMLPAT_IDENT;

  record RMLPAT_AS
    RMLIdent ident;
    RMLPattern rmlpattern;
  end RMLPAT_AS;

  record RMLPAT_CONS
    RMLPattern rmlpattern;
    RMLPattern rmlpattern1;
  end RMLPAT_CONS;

  record RMLPAT_STRUCT
    Option<RMLIdent> ident;
    list<RMLPattern> rmlpattern;
  end RMLPAT_STRUCT;

  record RMLPAT_NIL
  end RMLPAT_NIL;

  record RMLPAT_LIST
    list<RMLPattern> rmlpattern;
  end RMLPAT_LIST;

end RMLPattern;

uniontype RMLIdent

  record RMLSHORTID
    Ident ident;
  end RMLSHORTID;

  record RMLLONGID
    Ident ident;
    Ident ident1;
  end RMLLONGID;
end RMLIdent;

uniontype RMLLiteral

  record RMLLIT_INTEGER
    Integer int;
  end RMLLIT_INTEGER;

  record RMLLIT_REAL
    Real real;
  end RMLLIT_REAL;

  record RMLLIT_STRING
    String string;
  end RMLLIT_STRING ;

  record RMLLIT_CHAR
    Integer int;
  end RMLLIT_CHAR;

end RMLLiteral;

uniontype DTMember
  record DTCONS
    RMLIdent ident;
    list<RMLType> rmltype;
    Info info;
  end DTCONS;
end DTMember;

uniontype RMLExp
  record RMLCALL
    RMLIdent ident;
    list<RMLExp> exp;
  end RMLCALL;

  record RMLCONS
    RMLExp exp;
    RMLExp exp1;
  end RMLCONS;

  record RMLBINARY
    RMLExp exp1;
    Absyn.Operator op;
    RMLExp exp2;
  end RMLBINARY;


  record RMLUNARY
    Absyn.Operator op;
    RMLExp exp;
  end RMLUNARY;

  record RMLEXP_NIL
  end RMLEXP_NIL;

  record RMLNIL
  end RMLNIL;

  record RMLTUPLE
    list<RMLExp> exp;
  end RMLTUPLE;

  record RMLPATEXP
    list<RMLExp> exps;
  end RMLPATEXP;

  record RMLLIST
    list<RMLExp> exp;
  end RMLLIST;

  record RMLLIT
    RMLLiteral rmlliteral;
  end RMLLIT;

  record RML_REFERENCE
    RMLIdent ident;
  end RML_REFERENCE;
end RMLExp;

end Absynrml;