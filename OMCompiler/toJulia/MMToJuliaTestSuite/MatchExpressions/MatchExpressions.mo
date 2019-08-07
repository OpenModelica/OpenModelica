package MatchExpressions
/*Attempt wildcard import*/
import Absyn.*;

public function setClassFilename "Sets the filename where the class is stored."
  input Class inClass;
  input String fileName;
  output Class outClass;
algorithm
  outClass := match inClass
    local
      SourceInfo info;
      Class cl;
    case cl as CLASS(info=info as SOURCEINFO())
      equation
        info.fileName = fileName;
        cl.info = info;
      then cl;
  end match;
end setClassFilename;

public function setClassBody
  input Class inClass;
  input ClassDef inBody;
  output Class outClass = inClass;
algorithm
  outClass := match outClass
    case CLASS()
      algorithm
        outClass.body := inBody;
      then
        outClass;
  end match;
end setClassBody;

public function crefEqual " Checks if the name of a ComponentRef is
 equal to the name of another ComponentRef, including subscripts.
 See also crefEqualNoSubs."
  input ComponentRef iCr1;
  input ComponentRef iCr2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (iCr1,iCr2)
    local
      Ident id,id2;
      list<Subscript> ss1,ss2;
      ComponentRef cr1,cr2;
    case (CREF_IDENT(name = id,subscripts=ss1),CREF_IDENT(name = id2,subscripts = ss2))
      equation
        true = stringEq(id, id2);
        true = subscriptsEqual(ss1,ss2);
      then
        true;
    case (CREF_QUAL(name = id,subscripts = ss1, componentRef = cr1),CREF_QUAL(name = id2,subscripts = ss2, componentRef = cr2))
      equation
        true = stringEq(id, id2);
        true = subscriptsEqual(ss1,ss2);
        true = crefEqual(cr1, cr2);
      then
        true;
    case (CREF_FULLYQUALIFIED(componentRef = cr1),CREF_FULLYQUALIFIED(componentRef = cr2))
      then
        crefEqual(cr1, cr2);
    else false;
  end matchcontinue;
end crefEqual;

end MatchExpressions;
