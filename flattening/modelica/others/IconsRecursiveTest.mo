// name:     RecursiveSelfReference
// keywords: Instantiation
// status:   correct
//
// Testing fixes for bug: 179 (http://openmodelica.ida.liu.se/bugzilla/show_bug.cgi?id=179)
// the previous compiler failed to instantiate this model with Stack Overflow
//

  package BaseClasses
   extends Icons.BaseLibrary;
   package Icons
    extends Icons.BaseLibrary;
     model BaseLibrary "Icon for base library"
       parameter Real p = 1;
     end BaseLibrary;
   end Icons;
  end BaseClasses;

// Result:
// class BaseClasses
//   parameter Real p = 1.0;
// end BaseClasses;
// endResult
