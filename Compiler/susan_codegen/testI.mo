interface package testI

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

end testI;