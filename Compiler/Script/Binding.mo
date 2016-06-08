encapsulated package Binding "Binding generation support."

// Imports
public import Absyn;
public import SCode;
public import SCodeDump;
public import Dump;
public import Print;

protected import SCodeUtil;
protected import Interactive;
protected import Parser;
protected import GlobalScript;
protected import System;

// Aliases
public type Ident = Absyn.Ident;
public type Path = Absyn.Path;
public type TypeSpec = Absyn.TypeSpec;

// Types
public uniontype Mediator
 record MEDIATOR
   String mType;
   String template;
   list<Client> clients;
   list<Provider> providers;
   list<Preferred> preferred;
 end MEDIATOR;
end Mediator;

public uniontype Client
 record CLIENT
   String modelID ;
   String component;
   String template;
   Boolean isMandatory;
 end CLIENT;
end Client;

public uniontype Provider
 record PROVIDER
   String modelID ;
   String component;
   String template;
 end PROVIDER;
end Provider;

public uniontype Preferred
 record PREFERRED
   String clientInstancePath;
   String providerInstancePath;
 end PREFERRED;
end Preferred;

 protected uniontype Client_e "internal client list representation"
 record CLIENT_E
   list<Absyn.ComponentItem> components;
   TypeSpec typeSpec;
   Absyn.Class def;
   String instance;
   Client_e predecessors;
   list<Mediator> mediator;
 end CLIENT_E;

 record NO_PRED end NO_PRED;
end Client_e;

public function inferBindings "@autor lenab : root function called from API "
input Path model_path "Model for which the bindings will be computed";
input Absyn.Program env "All loaded models";
output Absyn.Program out_model_def "Updated environment";
protected
  list<Mediator> ms;
  Absyn.Class model_def, out_vmodel;
  list<SCode.Element> scode_def;
  list<Client_e> client_list;
algorithm
  model_def := Interactive.getPathedClassInProgram(model_path, env);
  scode_def := SCodeUtil.translateAbsyn2SCode(env);
 // print(SCodeDump.programStr(scode_def));
  ms := getMediatorDefsElements(scode_def, {});
  client_list := buildInstList(model_def, env, NO_PRED(), ms, {});
  out_vmodel := inferBindingClientList(client_list, model_def, env);
  print(Dump.unparseClassStr(out_vmodel) + "\n");
  out_model_def := Interactive.updateProgram(Absyn.PROGRAM({out_vmodel}, Interactive.buildWithin(model_path)), env);
end inferBindings;

/*public function generateVerificationScenarios "@autor lenab : root function called from API "
input Path package_path "The package where the bindings will be generated";
input Absyn.Program in_env "All loaded models";
output Absyn.Program out_env;

protected
  list<Mediator> ms;
  Absyn.Class package_def, out_vmodel;
  list<SCode.Element> scode_def;
  list<Client_e> client_list;
algorithm
  // get all design alternatives
  // get all requirements
  // get all scenarios
  ms := getMediatorDefsElements(scode_def, {});
  package_def := Interactive.getPathedClassInProgram(package_path, in_env);
  out_env := in_env;
end generateVerificationScenarios; */

protected function getAllElementsOfType
input list<SCode.Element> element_defs;
input Ident typeName;
input List<SCode.Element>  elements_in;
output List<SCode.Element> elements_out;
  algorithm
  elements_out := match(element_defs)
   local
     list<SCode.Element> rest,m ;
     SCode.Element el;
    case {} then elements_in;
    case el::rest
      equation
        m = listAppend(getAllElementsOfType2(el, typeName), elements_in);
        then getAllElementsOfType(rest, typeName, m);
   end match;
end getAllElementsOfType;

protected function getAllElementsOfType2
input SCode.Element el;
input Ident typeName;
output List<SCode.Element> res_elem;
algorithm
  res_elem := matchcontinue(el)
  local
    Absyn.Ident n;
    list<SCode.Element> elist;
    SCode.Mod mod, clientMod, providerMod;
    list<Absyn.Exp> cMod, pMod, prMod;
    String template, mType, name, str1, str2;
    Absyn.FunctionArgs pArgs, cArgs;
    list<Client> cls;
    list<Provider> prvs;
    list<Preferred> pref;
    case SCode.CLASS(_, _, _, _, SCode.R_PACKAGE(), SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)
      then getAllElementsOfType(elist, typeName, {});
    case SCode.CLASS(_, _, _, _, _, SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)
      equation
        (true) = isOfType(elist, typeName);

      then {el};
    case _
    equation print("noName\n");
     // print(SCodeDump.unparseElementStr(el));
      then {};
   end matchcontinue;
end getAllElementsOfType2;

protected function isOfType
input list<SCode.Element> elems;
input String typeName;
output Boolean result;
  algorithm
  (result) := matchcontinue(elems)
   local
     list<SCode.Element> rest;
     SCode.Element el;
     Mediator m;
     Absyn.Ident id;
     SCode.Mod mod;
     String name;
    case {} then (false);
    case SCode.EXTENDS(Absyn.IDENT(name), _, _, _, _)::_
      equation
        true = (name == typeName);
        then (true);
    case _::rest
        then isOfType(rest, typeName);
   end matchcontinue;
end isOfType;

protected function inferBindingClientList
input list<Client_e> client_list "list of nodes for which the binding is inferred";
input Absyn.Class vmodel;
input Absyn.Program env;
output Absyn.Class out_vmodel;
 algorithm
  out_vmodel := match(client_list)
   local
     Client_e ce;
     list<Client_e> rest;
     Absyn.Class upd_vmodel;
    case {} then vmodel;
    case ce::rest
      equation
         upd_vmodel = inferBindingClient(ce, vmodel, env);
        then inferBindingClientList(rest, upd_vmodel, env);
   end match;
end inferBindingClientList;

protected function inferBindingClient
input Client_e client_e;
input Absyn.Class vmodel;
input Absyn.Program env;
output Absyn.Class out_vmodel;
 algorithm
   out_vmodel := match(client_e)
   local
    list<Absyn.ComponentItem> components;
   TypeSpec typeSpec;
   Absyn.Class def;
   Client_e predecessors;
    String name, iname;
   String mType;
   String template;
   list<Client> clients;
   list<Provider> providers;
   list<Preferred> preferred;
   list<tuple<Absyn.Exp, String>>  out_es;
   Absyn.Exp exp, new_exp;
   Absyn.Class  out_class;
    case CLIENT_E(_, typeSpec, _, iname, _,
      MEDIATOR(_, template, _, providers, {})::_) /* no preferred bindings indicated */
      equation
        out_es = getProviders(providers, vmodel, env, {});
         if (template == "") then
         out_class = updateClass(vmodel, typeSpec, out_es, iname, env, false, {}, "");
         else
          GlobalScript.ISTMTS({GlobalScript.IEXP(exp, _)}, _) = Parser.parsestringexp(template);
          new_exp = parseAggregator(exp, Absyn.FUNCTIONARGS({Absyn.LIST(toExpList(out_es, {}))}, {}));
          // print("new TEMPLATE : " + Dump.dumpExpStr(new_exp) + "\n");
         out_class = updateClass(vmodel, typeSpec, {(new_exp, "")}, iname, env, false, {}, "");
         end if;
        then  out_class;

    case CLIENT_E(_, typeSpec, _, iname, _,
      MEDIATOR(_, _, _, providers, preferred)::_) /* preferred bindings indicated */
      equation
        out_es = getProviders(providers, vmodel, env, {});
        out_class = updateClass(vmodel, typeSpec, out_es, iname, env, true, preferred, "");

        then  out_class;
    case NO_PRED()
      equation
        print("NO_PRED\n");
      then vmodel;
   end match;
end inferBindingClient;

public function toExpList
input list<tuple<Absyn.Exp, String>>  e_list;
input list<Absyn.Exp>  in_es;
output list<Absyn.Exp>  out_es;
 algorithm
   out_es := match(e_list)
   local
     list<tuple<Absyn.Exp, String>> rest;
     Absyn.Exp exp;
    case {} then in_es;
    case (exp, _)::rest
        then toExpList(rest, exp::in_es);
   end match;
end toExpList;

public function updateClass
  input Absyn.Class  in_class;
  input TypeSpec typeSpec;
  input list<tuple<Absyn.Exp, String>> exp;
  input String instance_name;
  input Absyn.Program defs;
  input Boolean hasPreferred;
  input list<Preferred> preferred;
  input String path;
  output Absyn.Class  out_class;
algorithm
  out_class := match(in_class)
    local
      list<Absyn.Class>  r_classes, nr_classes;
      Absyn.Class cls, n_cls;
      Absyn.Ident name;
      Boolean     partialPrefix, finalPrefix, encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef    body, nbody;
      SourceInfo       info ;
    case(Absyn.CLASS(name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, body, info))
      equation
        nbody = parseClassDef(body, defs, typeSpec, exp, instance_name, hasPreferred, preferred, path + name + ".");
      then
        Absyn.CLASS(name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, nbody, info);
  end match;
end updateClass;

protected function parseClassDef
  input Absyn.ClassDef  in_def;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input list<tuple<Absyn.Exp, String>> exp;
  input String instance_name;
  input Boolean hasPreferred;
  input list<Preferred> preferred;
  input String path;
  output Absyn.ClassDef  out_def;
algorithm
  out_def := match(in_def)
    local
      list<String> typeVars ;
      list<Absyn.NamedArg> classAttrs ;
      list<Absyn.ClassPart> classParts, nclsp;
      list<Absyn.Annotation> ann ;
      Option<String>  comment;
      list<Absyn.EquationItem> contents;
      list<Absyn.EquationItem> eqs;
      list<Absyn.ElementItem> elems;
    case(Absyn.PARTS(typeVars, classAttrs, classParts, ann, comment))
      equation
        (nclsp) = parseClassParts(classParts, defs, typeSpec, exp, instance_name, hasPreferred, preferred, path);
      then
        Absyn.PARTS(typeVars, classAttrs, nclsp, ann, comment);
  end match;
end parseClassDef;

protected function parseClassParts
  input list<Absyn.ClassPart>  classes;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input list<tuple<Absyn.Exp, String>> exp;
  input String instance_name;
  input Boolean hasPreferred;
  input list<Preferred> preferred;
   input String path;
  output list<Absyn.ClassPart>  out_classes;

algorithm
  (out_classes) := match(classes)
    local
      list<Absyn.ClassPart>  r_classes, nr_classes;
      Absyn.ClassPart cls, n_cls;
      list<Absyn.EquationItem> eqs1, eqs2;
      list<Absyn.ElementItem> elems1, elems2;
      Integer count, count1;
    case({}) then ({});
    case(cls :: r_classes)
      equation
        (n_cls) = parseClassPart(cls, defs, typeSpec, exp, instance_name, hasPreferred, preferred, path);
        (nr_classes) = parseClassParts(r_classes, defs, typeSpec, exp, instance_name, hasPreferred, preferred, path);
           then
        (n_cls :: nr_classes);
  end match;
end parseClassParts;

protected function parseClassPart
  input Absyn.ClassPart  in_def;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input list<tuple<Absyn.Exp, String>> exp;
  input String instance_name;
   input Boolean hasPreferred;
  input list<Preferred> preferred;
   input String path;
  output Absyn.ClassPart  out_def;

algorithm
  (out_def) := match(in_def)
    local
      list<Absyn.ElementItem> elems;
      list<Absyn.Exp> exps;
      list<Absyn.EquationItem> eqs, neqs;
      list<Absyn.AlgorithmItem> algs;
      Absyn.ExternalDecl externalDecl;
      Option<Absyn.Annotation> annotation_ ;
      list<Absyn.EquationItem> eqs1, eqs2;
      list<Absyn.ElementItem> elems1, elems2;
      Integer count;
    case(Absyn.PUBLIC(elems)) //TODO
    equation
     // print("updating in parsePart   Class\n");
        elems1 = parseElems(elems, defs, typeSpec, exp, instance_name, hasPreferred, preferred, path);
    then
      (Absyn.PUBLIC(elems1));
   /* case(Absyn.PROTECTED(elems)) //TODO
    then
      (Absyn.PROTECTED(elems), {}, {}, instNo); //TODO */
    case(_)
    then
      (in_def);
  end match;
end parseClassPart;

protected function parseElems
  input list<Absyn.ElementItem> in_elems;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input list<tuple<Absyn.Exp, String>> exp;
  input String instance_name;
   input Boolean hasPreferred;
  input list<Preferred> preferred;
   input String pathInClass;
  output list<Absyn.ElementItem> out_elems;
algorithm
  out_elems := matchcontinue(in_elems)
   local
   Boolean                   finalPrefix;
    Option<Absyn.RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
    Absyn.InnerOuter                innerOuter "inner/outer" ;
    Absyn.Info                      info  "File name the class is defined in + line no + column no" ;
    Option<Absyn.ConstrainClass> constrainClass "only valid for classdef and component" ;
    Absyn.ElementAttributes attributes;
   Absyn.ElementItem e_item, e_new;
   list<Absyn.ElementItem> rest, re_items, e_list;
   list<Absyn.ComponentItem> components, cnew, cnew2;
   Path path;
   TypeSpec tSpec;
   Absyn.Class def;
   list<Client_e> l1, l2;
   Boolean isCl;
   List<Mediator> m;
   case {}
     then in_elems;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords ,innerOuter, Absyn.COMPONENTS(attributes,tSpec, components), info , constrainClass))::rest)
      algorithm
          _ := Absyn.typeSpecPath(typeSpec);
         // print ("*****************FINDING CLIENTS ... ");
         // print(Dump.unparseTypeSpec(typeSpec));
         // print("      +        ");
         // print(Dump.unparseTypeSpec(tSpec));
         // print ("... \n");
          //if Interactive.isPrimitive(Absyn.pathToCref(path), defs) then fail(); end if;

          if (Absyn.typeSpecPathString(typeSpec) == Absyn.typeSpecPathString(tSpec)) then
          print("Found provider \n");
          if(hasPreferred) then // handle preferred bindings
          e_list := applyModifiersPreferred(components, exp, instance_name,  pathInClass, finalPrefix, redeclareKeywords ,innerOuter, info , constrainClass, attributes,tSpec, preferred);
          else
          e_list := applyModifiers(components, exp, instance_name, 0, finalPrefix, redeclareKeywords ,innerOuter, info , constrainClass, attributes,tSpec);
          end if;
          else
           print("NOT Found provider \n");
          e_list := { Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords ,innerOuter, Absyn.COMPONENTS(attributes,tSpec, components), info , constrainClass))};

          end if;
      then listAppend(e_list, parseElems(rest, defs, typeSpec, exp, instance_name, hasPreferred, preferred,  pathInClass));
    case (e_item::rest)
        then e_item::parseElems(rest, defs, typeSpec, exp, instance_name, hasPreferred, preferred,  pathInClass);
  end matchcontinue;
end parseElems;

protected function applyModifiersPreferred
  input list<Absyn.ComponentItem> comps;
  input list<tuple<Absyn.Exp, String>>  exp;
  input String instance_name;
  input String typeSp;
  input Boolean                   finalPrefix;
  input Option<Absyn.RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
  input Absyn.InnerOuter                innerOuter "inner/outer" ;
  input Absyn.Info                      info  "File name the class is defined in + line no + column no" ;
  input Option<Absyn.ConstrainClass> constrainClass "only valid for classdef and component" ;
  input Absyn.ElementAttributes attributes;
  input TypeSpec tSpec;
  input list<Preferred> preferred;
  output list<Absyn.ElementItem> out_elems;
  algorithm
  out_elems := matchcontinue(exp)
   local
    list<tuple<Absyn.Exp, String>> rest;
    list<Absyn.ComponentItem> cnew;
    Option<Absyn.ComponentCondition> condition "condition" ;
    Option<Absyn.Comment> comment "comment" ;
     Absyn.Ident name "name" ;
    Absyn.ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Absyn.Modification> modification "Optional modification" ;
    Absyn.Exp e;
    String ename, client_pref;
    Absyn.ElementItem enew;
    case {} then {};
    case (e, ename)::rest
      equation
        client_pref = getPreferredBinding(ename, preferred);
        cnew = applyModifierPreferred(comps, e, client_pref, instance_name, ename);
        enew = Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords ,innerOuter, Absyn.COMPONENTS(attributes,tSpec, cnew), info , constrainClass));

        then enew::applyModifiersPreferred(comps, rest, instance_name, typeSp, finalPrefix,redeclareKeywords ,innerOuter, info , constrainClass, attributes,tSpec, preferred);
    case _::rest
        then applyModifiersPreferred(comps, rest, instance_name, typeSp, finalPrefix, redeclareKeywords ,innerOuter, info , constrainClass, attributes,tSpec, preferred);
   end matchcontinue;
end applyModifiersPreferred;

protected function getPreferredBinding
input String ename;
input list<Preferred> elems;
output String cl_name;
  algorithm
  (cl_name) := matchcontinue(elems)
   local
     list<Preferred> rest;
     String c_id, p_id;
    case {} then fail();
    case PREFERRED(c_id, p_id)::_
      equation
        true = (p_id == ename);
        then c_id;
    case _::rest
        then getPreferredBinding(ename, rest);
   end matchcontinue;
end getPreferredBinding;

protected function applyModifierPreferred
  input list<Absyn.ComponentItem> comps;
  input Absyn.Exp  exp;
  input String typeSp;
  input String instance_name;
  input String ename;
  output list<Absyn.ComponentItem> out_comps;
  algorithm
  out_comps := matchcontinue(comps)
   local
     list<Absyn.ComponentItem> rest;
    Absyn.ComponentItem cnew;
    Option<Absyn.ComponentCondition> condition "condition" ;
    Option<Absyn.Comment> comment "comment" ;
    Ident name "name" ;
    Absyn.ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Absyn.Modification> modification "Optional modification" ;
    case {} then {};
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name, arrayDim, _), condition, comment)::_
      equation
        true = (typeSp == name);
        cnew = Absyn.COMPONENTITEM(Absyn.COMPONENT(name, arrayDim,
        SOME(Absyn.CLASSMOD({Absyn.MODIFICATION(false, Absyn.NON_EACH(),
          Absyn.IDENT(instance_name), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(exp, Absyn.dummyInfo))), NONE(), Absyn.dummyInfo)}, Absyn.NOMOD()))), condition, comment);
        then {cnew};
    case _::rest
        then applyModifierPreferred(rest, exp, typeSp, instance_name, ename);
   end matchcontinue;
end applyModifierPreferred;

protected function applyModifiers
  input list<Absyn.ComponentItem> comps;
  input list<tuple<Absyn.Exp, String>>  exp;
  input String instance_name;
  input Integer counter;
  input Boolean                   finalPrefix;
  input Option<Absyn.RedeclareKeywords> redeclareKeywords "replaceable, redeclare" ;
  input Absyn.InnerOuter                innerOuter "inner/outer" ;
  input Absyn.Info                      info  "File name the class is defined in + line no + column no" ;
  input Option<Absyn.ConstrainClass> constrainClass "only valid for classdef and component" ;
  input Absyn.ElementAttributes attributes;
  input TypeSpec tSpec;
  output list<Absyn.ElementItem> out_elems;
  algorithm
  out_elems := matchcontinue(exp)
   local
     list<tuple<Absyn.Exp, String>> rest;
    list<Absyn.ComponentItem> cnew;
    Option<Absyn.ComponentCondition> condition "condition" ;
    Option<Absyn.Comment> comment "comment" ;
     Absyn.Ident name "name" ;
    Absyn.ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Absyn.Modification> modification "Optional modification" ;
    Absyn.Exp e;
    String ename;
    Absyn.ElementItem enew;
    case {} then {};
    case (e, _)::rest
      equation
        cnew = applyModifier(comps, e, instance_name, counter);
        enew = Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords ,innerOuter, Absyn.COMPONENTS(attributes,tSpec, cnew), info , constrainClass));

        then enew::applyModifiers(comps, rest, instance_name, counter+1, finalPrefix,redeclareKeywords ,innerOuter, info , constrainClass, attributes,tSpec);
    case _::rest
        then applyModifiers(comps, rest, instance_name, counter, finalPrefix,redeclareKeywords ,innerOuter, info , constrainClass, attributes,tSpec);
   end matchcontinue;
end applyModifiers;

protected function applyModifier
  input list<Absyn.ComponentItem> comps;
  input Absyn.Exp  exp;
  input String instance_name;
  input Integer counter;
  output list<Absyn.ComponentItem> out_comps;
  algorithm
  out_comps := matchcontinue(comps)
   local
     list<Absyn.ComponentItem> rest;
    Absyn.ComponentItem cnew;
    Option<Absyn.ComponentCondition> condition "condition" ;
    Option<Absyn.Comment> comment "comment" ;
     Absyn.Ident name, new_name ;

    Absyn.ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Absyn.Modification> modification "Optional modification" ;
    case {} then {};
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name, arrayDim, _), condition, comment)::_
      equation
       // print("-------------------- applying modifier\n");
        new_name = name + "_autogen_bind_" + intString(counter);
        cnew = Absyn.COMPONENTITEM(Absyn.COMPONENT(new_name, arrayDim,
        SOME(Absyn.CLASSMOD({Absyn.MODIFICATION(false, Absyn.NON_EACH(),
          Absyn.IDENT(instance_name), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(exp, Absyn.dummyInfo))), NONE(), Absyn.dummyInfo)}, Absyn.NOMOD()))), condition, comment);
        then {cnew};
    case _::rest
        then applyModifier(rest, exp, instance_name, counter);
   end matchcontinue;
end applyModifier;

protected function parseAggregator
  input Absyn.Exp  in_eq;
  input Absyn.FunctionArgs fargs;
  output Absyn.Exp  out_eq;
algorithm
  out_eq := match(in_eq)
    local
      Integer int;
      Real rl;
      Absyn.ComponentRef crf, new_crf;
      String str;
      Boolean bool;
      Absyn.Exp exp1, exp2, nexp1, nexp2, ife, nife;
      Absyn.Operator op;
      list<Absyn.EquationItem> eqs1, eqs2, eqs3, eqs4;
      list<Absyn.ElementItem> elems1, elems2, elems3, elems4;
      Integer count, count2, count3, count4;
      list<tuple<Absyn.Exp, Absyn.Exp>> elif, nelif;

    case(Absyn.BINARY(exp1, op, exp2))
      equation
        nexp1 =  parseAggregator(exp1, fargs);
        nexp2 =  parseAggregator(exp2, fargs);
      then Absyn.BINARY(nexp1, op, nexp2);

    case(Absyn.LBINARY(exp1, op, exp2))
      equation
       nexp1 =  parseAggregator(exp1, fargs);
        nexp2 =  parseAggregator(exp2, fargs);
      then (Absyn.LBINARY(nexp1, op, nexp2));
     case(Absyn.RELATION(exp1, op, exp2))
      equation
      nexp1 =  parseAggregator(exp1, fargs);
        nexp2 =  parseAggregator(exp2, fargs);
      then (Absyn.RELATION(nexp1, op, nexp2));
    case(Absyn.UNARY(op, exp2))
      equation
         nexp1 =  parseAggregator(exp2, fargs);
      then (Absyn.UNARY(op, nexp1));

     case(Absyn.LUNARY(op, exp2))
      equation
         nexp1 =  parseAggregator(exp2, fargs);
      then (Absyn.LUNARY(op, nexp1));

    case(Absyn.IFEXP(ife, exp1, exp2, elif))
      equation
         nife =  parseAggregator(ife, fargs);
         nexp1 =  parseAggregator(exp1, fargs);
         nexp2 = parseAggregator(exp2, fargs);
        //(nelif, eqs4, elems4, count4) = parseExpressionTuple(elif, defs, eqs3, elems3, count3);
      then (Absyn.IFEXP(nife, nexp1, nexp2, elif));
    case(Absyn.CALL(crf, _))
      equation
       // print("CALL...."  + "\n");
       // print(Dump.dumpExpStr(Absyn.CALL(crf, fargs)) + "\n");
      then (Absyn.CALL(crf, fargs));
     case(_)
       equation
        //  print(Dump.dumpExpStr(in_eq) + "\n");
       then (in_eq);
  end match;
end parseAggregator;


public function getProviders
input list<Provider> providers;
input Absyn.Class vmodel;
input Absyn.Program env;
input list<tuple<Absyn.Exp, String>>  in_es;
output list<tuple<Absyn.Exp, String>>  out_es;
 algorithm
   out_es := match(providers)
   local
     Provider pr;
     list<Provider> rest;
     String className, instance, template;
     Absyn.Program upd_env;
     list<tuple<list<Absyn.ComponentItem>, String>> comps;
     list<tuple<Absyn.Exp, String>>  exps, new_es;
     list<Absyn.ElementItem> mlist;
     Absyn.Exp exp;
    case {} then in_es;
    case PROVIDER(className, instance, template)::rest // TODO fix handling instance
      equation
        mlist = Absyn.getElementItemsInClass(vmodel);
        comps = getAllProviderInstances(className, template, mlist, env, {}, "");
        //print("WILL parse provider: "+ className + " with template: " + template + "\n");
        GlobalScript.ISTMTS({GlobalScript.IEXP(exp, _)}, _) = Parser.parsestringexp(template);
        // print(Dump.dumpExpStr(exp) + "\n");
        exps = applyTemplate(exp, comps, {});
        new_es = listAppend(exps, in_es);
        then getProviders(rest, vmodel, env, new_es);
   end match;
end getProviders;

protected function applyTemplate
  input Absyn.Exp  exp;
  input list<tuple<list<Absyn.ComponentItem>, String>> comps;
  input list<tuple<Absyn.Exp, String>>  in_es;
  output list<tuple<Absyn.Exp, String>>  out_es;
  algorithm
  out_es := matchcontinue(comps)
   local
     list<Absyn.ComponentItem> clist;
     list<tuple<list<Absyn.ComponentItem>, String>>  rest;
     Absyn.Ident name;
     list<tuple<Absyn.Exp, String>> new_es;
     String pathInClass;
    case {}
       equation
      then in_es;
    case (clist, pathInClass)::rest
      equation
        new_es = applyTemplate2(exp,  clist, in_es,pathInClass);
        then applyTemplate(exp, rest, new_es);
    case _::rest
       equation
        then applyTemplate(exp, rest, in_es);
   end matchcontinue;
end applyTemplate;

protected function applyTemplate2
  input Absyn.Exp  exp;
  input list<Absyn.ComponentItem> comps;
  input list<tuple<Absyn.Exp, String>>  in_es;
  input String pathInClass;
  output list<tuple<Absyn.Exp, String>>  out_es;
  algorithm
  out_es := matchcontinue(comps)
   local
     list<Absyn.ComponentItem> rest;
     Absyn.Ident name, newName;
    case {}
       equation
        //print("EMPTY COMPONENT MATCH\n");
      then in_es;
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name, _, _), _, _)::rest
      equation
        newName = if(pathInClass == "") then name else pathInClass + "." + name;
       // print("Applying template to" + newName + "\n");
        then applyTemplate2(exp, rest, (parseExpression(exp, newName), newName)::in_es, pathInClass);
    case _::rest
       equation
        //print("NO COMPONENT MATCH\n");
        then applyTemplate2(exp, rest, in_es, pathInClass);
   end matchcontinue;
end applyTemplate2;

protected function parseExpression
  input Absyn.Exp  in_eq;
  input Absyn.Ident fargs;
  output Absyn.Exp  out_eq;
algorithm
  out_eq := match(in_eq)
    local
      Integer int;
      Real rl;
      Absyn.ComponentRef crf, new_crf;
      String str;
      Boolean bool;
      Absyn.Exp exp1, exp2, nexp1, nexp2, ife, nife;
      Absyn.Operator op;
      list<Absyn.EquationItem> eqs1, eqs2, eqs3, eqs4;
      list<Absyn.ElementItem> elems1, elems2, elems3, elems4;
      Integer count, count2, count3, count4;
      list<tuple<Absyn.Exp, Absyn.Exp>> elif, nelif;

    case(Absyn.BINARY(exp1, op, exp2))
      equation
        nexp1 =  parseExpression(exp1, fargs);
        nexp2 =  parseExpression(exp2, fargs);
      then Absyn.BINARY(nexp1, op, nexp2);

    case(Absyn.LBINARY(exp1, op, exp2))
      equation
        nexp1 =  parseExpression(exp1, fargs);
        nexp2 = parseExpression(exp2, fargs);
      then (Absyn.LBINARY(nexp1, op, nexp2));
     case(Absyn.RELATION(exp1, op, exp2))
      equation
        nexp1 =  parseExpression(exp1, fargs);
        nexp2 = parseExpression(exp2, fargs);
      then (Absyn.RELATION(nexp1, op, nexp2));
    case(Absyn.UNARY(op, exp2))
      equation
         nexp1 =  parseExpression(exp2, fargs);
      then (Absyn.UNARY(op, nexp1));

     case(Absyn.LUNARY(op, exp2))
      equation
         nexp1 =  parseExpression(exp2, fargs);
      then (Absyn.LUNARY(op, nexp1));

    case(Absyn.IFEXP(ife, exp1, exp2, elif))
      equation
         nife =  parseExpression(ife, fargs);
         nexp1 =  parseExpression(exp1, fargs);
         nexp2 = parseExpression(exp2, fargs);
        //(nelif, eqs4, elems4, count4) = parseExpressionTuple(elif, defs, eqs3, elems3, count3);
      then (Absyn.IFEXP(nife, nexp1, nexp2, elif));
    case(Absyn.CREF(crf))
      equation
        new_crf = updateCRF(crf, fargs);
      then (Absyn.CREF(new_crf));
     case(_)
       equation
         // print(Dump.dumpExpStr(in_eq) + "\n");
       then (in_eq);
  end match;
end parseExpression;

protected function updateCRF
  input Absyn.ComponentRef componentRef;
  input Absyn.Ident name;
  output Absyn.ComponentRef out_componentRef;
  algorithm
  out_componentRef := matchcontinue(componentRef)
  local
     Absyn.ComponentRef cRef, new_cRef;
     list<Absyn.Subscript> subscripts;
     Absyn.Ident id;
  case (Absyn.CREF_FULLYQUALIFIED(cRef)) then updateCRF(cRef, name);
  case (Absyn.CREF_QUAL("getPath", subscripts, cRef))
    then Absyn.CREF_QUAL(name, subscripts, cRef);
  case (Absyn.CREF_QUAL(id, subscripts, cRef))
    equation
      new_cRef = updateCRF(cRef, name);
       then Absyn.CREF_QUAL(id, subscripts, new_cRef);
  case (Absyn.CREF_IDENT("getPath", subscripts)) then Absyn.CREF_IDENT(name, subscripts);
  case _ then    componentRef;
  end matchcontinue;
end updateCRF;

protected function getAllProviderInstances
input String className;
input String template;
input list<Absyn.ElementItem> e_items;
input Absyn.Program env;
input list<tuple<list<Absyn.ComponentItem>, String>> in_components;
input String pathInClass;
output list<tuple<list<Absyn.ComponentItem>, String>> out_components;
algorithm
  out_components := matchcontinue(e_items)
   local
   Absyn.ElementItem e_item;
   list<Absyn.ElementItem> rest, re_items;
   list<Absyn.ComponentItem> components;
   list<tuple<list<Absyn.ComponentItem>, String>> cnew, cnew2;
   TypeSpec typeSpec;
   Path path;
   Absyn.Class def;
   list<Client_e> l1, l2;
   Boolean isCl;
   List<Mediator> m;
   case {}
     then in_components;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_, Absyn.COMPONENTS(_,typeSpec, components), _, _))::rest)
      algorithm
          path := Absyn.typeSpecPath(typeSpec);
         // print ("TESTING PROVIDERS ... ");
         // print(Dump.unparseTypeSpec(typeSpec));
         // print ("... \n");
          //if Interactive.isPrimitive(Absyn.pathToCref(path), env) then fail(); end if;
          def := Interactive.getPathedClassInProgram(path,env); // load the element
          if (Absyn.typeSpecPathString(typeSpec) == className) then
         // print("... found provider " + className + "\n");
          cnew := (components, pathInClass)::in_components;
          else
          cnew := in_components;
          end if;

          re_items := Absyn.getElementItemsInClass(def);
          cnew2 := parseComponents(className, template, re_items, env,  components, cnew, pathInClass);
      then getAllProviderInstances(className, template, rest, env, cnew2, pathInClass);
    case (_::rest)
        then getAllProviderInstances(className, template, rest, env, in_components, pathInClass);
  end matchcontinue;
end getAllProviderInstances;


protected function parseComponents
input String className;
input String template;
input list<Absyn.ElementItem> e_items;
input Absyn.Program env;
input list<Absyn.ComponentItem> components;
input list<tuple<list<Absyn.ComponentItem>, String>> in_components;
input String pathInClass;
output list<tuple<list<Absyn.ComponentItem>, String>> out_components;
algorithm
  out_components:= matchcontinue(components)
   local
    list<Absyn.ComponentItem> rest;
    Absyn.ComponentItem cnew;
    Option<Absyn.ComponentCondition> condition "condition" ;
    Option<Absyn.Comment> comment "comment" ;
     Absyn.Ident name, new_name ;
     list<tuple<list<Absyn.ComponentItem>, String>> tmp;
     String newName;
    Absyn.ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Absyn.Modification> modification "Optional modification" ;
    case {} then in_components;
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name, _, _), _, _)::rest
      equation
        newName = if(pathInClass == "") then name else pathInClass + "." + name;
        tmp = getAllProviderInstances(className, template, e_items, env,  in_components, newName);
        then parseComponents(className, template, e_items, env, rest, tmp, pathInClass);
    case _::rest
        then parseComponents(className, template, e_items, env, rest, in_components, pathInClass);
   end matchcontinue;
end parseComponents;


protected function buildInstList "mark all the clients and providers in the model"
input Absyn.Class clazz;
input Absyn.Program env;
input Client_e predecessors;
input list<Mediator> mediators;
input list<Client_e> client_list_in;
//input list<Provider> providers;
output list<Client_e> client_list;
protected
 list<Absyn.ElementItem> e_items;
algorithm
 // print("Building instance list\n");
 // print("" + Dump.unparseClassStr(clazz) + "\n");
  e_items := Absyn.getElementItemsInClass(clazz);
  client_list := parseElementInstList(e_items, env, NO_PRED(), mediators, client_list_in);
  print("DONE Building instance list\n");
end buildInstList;


protected function parseElementInstList
input list<Absyn.ElementItem> e_items;
input Absyn.Program env;
input Client_e predecessors;
input list<Mediator> mediators;
input list<Client_e> in_client_list;
//input list<Provider> providers;
output list<Client_e> client_list;

algorithm
  (client_list) := matchcontinue(e_items)
   local
   Absyn.ElementItem e_item;
   list<Absyn.ElementItem> rest;
   list<Absyn.ComponentItem> components;
   TypeSpec typeSpec;
   Path path;
   String iname;
   Client_e new_predecessors;
   Absyn.Class def;
   list<Client_e> l1, l2;
   Boolean isCl;
   List<Mediator> m;
   case {}
     then in_client_list;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_, Absyn.COMPONENTS(_,typeSpec, components), _, _))::rest)
      algorithm
          path := Absyn.typeSpecPath(typeSpec);
         // print ("TESTING in parseElementList ... ");
        //  print(Dump.unparseTypeSpec(typeSpec));
         // print ("... \n");
         // if Interactive.isPrimitive(Absyn.pathToCref(path), env) then fail(); end if;
         // print("HERE\n");
          def := Interactive.getPathedClassInProgram(path,env); // load the element
          (isCl, iname, m) := isClient(Absyn.typeSpecPathString(typeSpec), mediators, {});
          //print("HERE" + iname + "\n");
           if(isCl) then
             new_predecessors := CLIENT_E(components, typeSpec, def, iname, predecessors, m);
             l2 := new_predecessors::in_client_list;
           else
             new_predecessors := predecessors;
             l2 := in_client_list;
           end if;
           l1 := buildInstList(def, env, new_predecessors,  mediators, l2);
      then parseElementInstList(rest, env, predecessors, mediators, l1);
    case (_::rest)
      equation
        //print("parseElementInstList unmatched pattern\n");
        then parseElementInstList(rest, env, predecessors, mediators, in_client_list);
  end matchcontinue;
end parseElementInstList;

protected function isClient
input String ci_name ;
input list<Mediator> mediators;
input List<Mediator> in_m;
output Boolean isClient;
output String iname;
output List<Mediator> m;
algorithm
  (isClient, iname, m) := matchcontinue(mediators)
   local
     String name, nm;
     String mType;
     String template;
     list<Client> clients;
     list<Provider> providers;
     list<Mediator> rest;
     list<Preferred> preferred;
    case {} then (false, "", in_m);
    case MEDIATOR(mType, template, clients, providers, preferred)::_
      equation
        //print("Testing mediator : " + mType + "\n");
        (true, nm) = isClientInMediator(ci_name, clients);
       // print("... found client : "+ ci_name +"\n");
        then (true, nm, MEDIATOR(mType, template, clients, providers, preferred)::in_m);
    case _::rest
      equation
       // print("REST\n");
        then isClient(ci_name, rest, in_m);
   end matchcontinue;
end isClient;

protected function isClientInMediator
input String ci_name ;
input list<Client> clients;
output Boolean isClient;
output String iname;
algorithm

  (isClient, iname) := matchcontinue(clients)
   local
      list<Absyn.Class> parents;
     Absyn.Class current_ci;
     String name, inst, tmp;
     list<Client> rest;
     Boolean isM;
    case {} then (false, "");
    case CLIENT(name, inst, _, _)::_
      equation
        // print("Testing mediator for names: " + name + " " + ci_name + "\n");
        true = (name == ci_name);
        then (true, inst);
    case _::rest
      equation
       // print("REST\n");
        then isClientInMediator(ci_name, rest);
   end matchcontinue;
end isClientInMediator;


protected function getMediatorDefsElements "extracts the mediator infomration from SCODE"
input list<SCode.Element> mediator_defs;
input List<Mediator>  mediators_in;
output List<Mediator> mediators_out;
  algorithm
  mediators_out := match(mediator_defs)
   local
     list<SCode.Element> rest;
     SCode.Element el;
     List<Mediator>  m;
    case {} then mediators_in;
    case el::rest
      equation
        m = listAppend(getMediatorDefsElement(el), mediators_in);
        then getMediatorDefsElements(rest, m);
   end match;
end getMediatorDefsElements;

protected function getMediatorDefsElement
input SCode.Element el;
output List<Mediator> mediator;
algorithm
  mediator := matchcontinue(el)
  local
    Absyn.Ident n;
    list<SCode.Element> elist;
    SCode.Mod mod, clientMod, providerMod;
    list<Absyn.Exp> cMod, pMod, prMod;
    String template, mType, name, str1, str2;
    Absyn.FunctionArgs pArgs, cArgs;
    list<Client> cls;
    list<Provider> prvs;
    list<Preferred> pref;
    case SCode.CLASS(_, _, _, _, SCode.R_PACKAGE(), SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)
      then getMediatorDefsElements(elist, {});
    case SCode.CLASS(_, _, _, _, SCode.R_RECORD(_), SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)
      equation
        (true, SOME(mod)) = isMediator(elist);
        Absyn.STRING(template) = getValue(mod, "template", "string");
         str1 = System.stringReplace(template, "%", "");
         str2 = System.stringReplace(str1, ":", "all");
        Absyn.STRING(mType) = getValue(mod, "mType", "string");

      // build clients
        Absyn.ARRAY(cMod) =  getValue(mod, "clients", "array");
        cls = getClientList(cMod, {});
      // build providers
        Absyn.ARRAY(pMod) =  getValue(mod, "providers", "array");
        prvs = getProviderList(pMod, {});

      // build preferred
         Absyn.ARRAY(prMod) =  getValue(mod, "preferred", "array");
         pref = getPreferredList(prMod, {});

      then {MEDIATOR(mType,str2, cls, prvs, pref)};
    case _
    equation print("noName\n");
     // print(SCodeDump.unparseElementStr(el));
      then {};
   end matchcontinue;
end getMediatorDefsElement;

protected function getPreferredList
input  list<Absyn.Exp> e;
input  list<Preferred> val;
output  list<Preferred> n_val;
  algorithm
  n_val := match(e)
   local
     Absyn.FunctionArgs fArgs;
     list<SCode.SubMod>  smod;
     list<Absyn.NamedArg> argNames;
     list<Absyn.Exp> rest;
     String clientInstancePath;
     String providerInstancePath;
    case {}
        then val;
    case Absyn.CALL(_, Absyn.FUNCTIONARGS(_, argNames))::rest
        equation
          clientInstancePath = getArg(argNames, "clientInstancePath");
            print ("clientInstancePath " +  clientInstancePath + "\n");
          providerInstancePath = getArg(argNames, "providerInstancePath");
           print ("providerInstancePath " +  providerInstancePath + "\n");
        then getPreferredList(rest, PREFERRED(clientInstancePath, providerInstancePath)::val);
   end match;
end getPreferredList;

protected function getClientList
input  list<Absyn.Exp> e;
input  list<Client> val;
output  list<Client> n_val;
  algorithm
  n_val := match(e)
   local
     Absyn.FunctionArgs fArgs;
     list<SCode.SubMod>  smod;
     list<Absyn.NamedArg> argNames;
     list<Absyn.Exp> rest;
     String className, instance, template, isM;
     Boolean isMandatory;
    case {}
        then val;
    case Absyn.CALL(_, Absyn.FUNCTIONARGS(_, argNames))::rest
        equation
          print ("gettingClients\n");
          className = getArg(argNames, "modelID");
           print ("className " +  className + "\n");
          instance = getArg(argNames, "component");
           print ("instance " +  instance + "\n");
           template = getArg(argNames, "template");
           print ("providerTemplate " +  template + "\n");
         isM = getArg(argNames, "isMandatory");
         if(isM == "true")
            then isMandatory = true; else isMandatory = false; end if;
        then getClientList(rest, CLIENT(className, instance, template, isMandatory)::val);
   end match;
end getClientList;

protected function getProviderList
input  list<Absyn.Exp> e;
input  list<Provider> val;
output  list<Provider> n_val;
  algorithm
  n_val := match(e)
   local
     Absyn.FunctionArgs fArgs;
     list<SCode.SubMod>  smod;
     list<Absyn.NamedArg> argNames;
     list<Absyn.Exp> rest;
     String className, providerTemplate, instance;

    case {}
        then val;
    case Absyn.CALL(_, Absyn.FUNCTIONARGS(_, argNames))::rest
        equation
          className = getArg(argNames, "modelID");
            print ("className " +  className + "\n");
          instance = getArg(argNames, "component");
           print ("instance " +  instance + "\n");
          providerTemplate = getArg(argNames, "template");
            print ("providerTemplate " +  providerTemplate + "\n");
        then getProviderList(rest, PROVIDER(className, instance, providerTemplate)::val);
   end match;
end getProviderList;

protected function getArg
input  list<Absyn.NamedArg> argNames;
input  String name;
output  String val;
  algorithm
  val := matchcontinue(argNames)
   local
    String str, nname, str1, str2;
     list<Absyn.NamedArg> rest;
   case {}
        then "";
    case Absyn.NAMEDARG(nname, Absyn.STRING(str))::_
        equation
         // print("Comparing: " + name + "      "  +nname + "\n");
         str1 = System.stringReplace(str, "%", "");
         str2 = System.stringReplace(str1, ":", "all");
         //print("Updated string from " +  str + " to " + str2 + "\n");
           true = (nname == name);
        then str2;
    case _::rest
        then getArg(rest, name);
   end matchcontinue;
end getArg;


protected function isMediator
input list<SCode.Element> elems;
output Boolean result;
output Option<SCode.Mod> mods;
  algorithm
  (result, mods) := matchcontinue(elems)
   local
     list<SCode.Element> rest;
     SCode.Element el;
     Mediator m;
     Absyn.Ident id;
     SCode.Mod mod;
    case {} then (false, NONE());
    case SCode.EXTENDS(Absyn.IDENT("Mediator"), _, mod, _, _)::_
        then (true, SOME(mod));
    case _::rest
        then isMediator(rest);
   end matchcontinue;
end isMediator;

protected function getValue
input  SCode.Mod mod;
input Ident name "name of argument";
input String retype "type of argument";
output  Absyn.Exp val;
  algorithm
  val := match (mod)
   local
     list<SCode.SubMod>  smod;
    case SCode.MOD(_,_, smod, _, _)
        then getValueR(smod, name, retype);
   end match;
end getValue;

protected function getValueR
input list<SCode.SubMod> smod;
input Ident name;
input String retype "type of argument";
output Absyn.Exp val;
  algorithm
  val := matchcontinue(smod, retype)
   local
     SCode.Mod mod;
     Absyn.Exp eval;
     Ident n;
     list<SCode.SubMod> rest;
   case ({}, "bool")
       then Absyn.BOOL(false); // client not mandatory by default
   case ({}, "array")
       then Absyn.ARRAY({});
   case ({}, "string")
       then Absyn.STRING("");
   case (SCode.NAMEMOD(n, SCode.MOD(_,_,_, SOME((eval)), _))::_, _)
        equation
          if(n <> name) then fail(); end if;
        then eval;
    case (_::rest, _)
        then getValueR(rest, name, retype);
   end matchcontinue;
end getValueR;

annotation(__OpenModelica_Interface="backend");
end Binding;