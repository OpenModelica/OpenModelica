encapsulated package Binding "Binding generation support."

// Imports
public import Absyn;
public import Error;
public import SCode;
public import System;
public import SCodeDump;
public import Dump;
public import Print;

protected import SCodeUtil;
protected import Interactive;
protected import Parser;
protected import GlobalScript;

// Aliases
public type Ident = Absyn.Ident;
public type Path = Absyn.Path;
public type TypeSpec = Absyn.TypeSpec;

// Types
public uniontype Mediator
 record MEDIATOR
   String name;
   String mType;
   String template;
   list<Client> clients;
   list<Provider> providers;
 end MEDIATOR;
end Mediator;

public uniontype Client
 record CLIENT
   String className;
   String instance;
 end CLIENT;
end Client;

public uniontype Provider
 record PROVIDER
   String className;
   String template;
 end PROVIDER;
end Provider;

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
input Absyn.Path model_path;
input Absyn.Program env;
output Absyn.Program out_model_def;
protected
  list<Mediator> ms;
  Absyn.Class model_def;
  list<SCode.Element> scode_def;
  SCode.Element scode_model;
  list<Client_e> client_list;
  list<Absyn.ElementItem> vmodel;
  Absyn.Class out_vmodel;
algorithm
  model_def := Interactive.getPathedClassInProgram(model_path, env);
  scode_def := SCodeUtil.translateAbsyn2SCode(env);
  //print(SCodeDump.programStr(scode_def));
  ms := getMediatorDefsElements(scode_def, {});
  client_list := buildInstList(model_def, env, NO_PRED(), ms, {});
  //vmodel := Absyn.getElementItemsInClass(model_def);
  out_vmodel := inferBindingClientList(client_list, model_def, env);
  print(Dump.unparseClassStr(out_vmodel));
  out_model_def := Interactive.updateProgram(Absyn.PROGRAM({out_vmodel}, Interactive.buildWithin(model_path)), env);
end inferBindings;

protected function inferBindingClientList
input list<Client_e> client_list "list of nodes for which the binding is inferred";
input Absyn.Class vmodel;
input Absyn.Program env;
output Absyn.Class out_vmodel;
//output String bindingExpression;
 algorithm
  out_vmodel := matchcontinue(client_list)
   local
     Client_e ce;
     list<Client_e> rest;
     Absyn.Class upd_vmodel;
    case {} then vmodel;
    case ce::rest
      equation
         upd_vmodel = inferBindingClient(ce, vmodel, env);
        then inferBindingClientList(rest, upd_vmodel, env);
   end matchcontinue;
end inferBindingClientList;

protected function inferBindingClient
input Client_e client_e;
input Absyn.Class vmodel;
input Absyn.Program env;
output Absyn.Class out_vmodel;
 algorithm
   out_vmodel := matchcontinue(client_e)
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
   list<Absyn.Exp>  out_es;
   Absyn.Exp exp, new_exp;
   Absyn.Class  out_class;
    case CLIENT_E(components, typeSpec, def, iname, predecessors,
      MEDIATOR(name, mType, template, clients, providers)::_)
      equation
        out_es = getProviders(providers, vmodel, env, {});
        GlobalScript.ISTMTS({GlobalScript.IEXP(exp, _)}, _) = Parser.parsestringexp(template);
       //  print("TEMPLATE : " + Dump.dumpExpStr(exp) + "\n");

         new_exp = parseAggregator(exp, Absyn.FUNCTIONARGS({Absyn.LIST(out_es)}, {}));
         out_class = updateClass(vmodel, typeSpec, new_exp, iname, env);
        then  out_class;
    case NO_PRED()
      then vmodel;
   end matchcontinue;
end inferBindingClient;

public function updateClass
  input Absyn.Class  in_class;
  input TypeSpec typeSpec;
  input Absyn.Exp exp;
  input String instance_name;
  input Absyn.Program defs;

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
        nbody = parseClassDef(body, defs, typeSpec, exp, instance_name);
      then
        Absyn.CLASS(name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction, nbody, info);
  end match;
end updateClass;

protected function parseClassDef
  input Absyn.ClassDef  in_def;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input Absyn.Exp exp;
  input String instance_name;

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
        (nclsp) = parseClassParts(classParts, defs, typeSpec, exp, instance_name);
      then
        Absyn.PARTS(typeVars, classAttrs, nclsp, ann, comment);
  end match;
end parseClassDef;

protected function parseClassParts
  input list<Absyn.ClassPart>  classes;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input Absyn.Exp exp;
  input String instance_name;
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
        (n_cls) = parseClassPart(cls, defs, typeSpec, exp, instance_name);
        (nr_classes) = parseClassParts(r_classes, defs, typeSpec, exp, instance_name);
           then
        (n_cls :: nr_classes);
  end match;
end parseClassParts;

protected function parseClassPart
  input Absyn.ClassPart  in_def;
  input Absyn.Program defs;
  input TypeSpec typeSpec;
  input Absyn.Exp exp;
  input String instance_name;
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
        elems1 = parseElems(elems, defs, typeSpec, exp, instance_name);
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
  input Absyn.Exp exp;
  input String instance_name;
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
   list<Absyn.ElementItem> rest, re_items;
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
          path := Absyn.typeSpecPath(typeSpec);
        /*  print ("TESTING PROVIDERS ... ");
          print(Dump.unparseTypeSpec(typeSpec));
          print ("... \n"); */
          if Interactive.isPrimitive(Absyn.pathToCref(path), defs) then fail(); end if;

          if (Absyn.typeSpecPathString(typeSpec) == Absyn.typeSpecPathString(tSpec)) then
          cnew := applyModifier(components, exp, instance_name);

          else
          cnew := components;
          end if;

          e_new := Absyn.ELEMENTITEM(Absyn.ELEMENT(finalPrefix,redeclareKeywords ,innerOuter, Absyn.COMPONENTS(attributes,tSpec, cnew), info , constrainClass));

      then e_new::parseElems(rest, defs, typeSpec, exp, instance_name);
    case (e_item::rest)
        then e_item::parseElems(rest, defs, typeSpec, exp, instance_name);
  end matchcontinue;
end parseElems;

protected function applyModifier
  input list<Absyn.ComponentItem> comps;
  input Absyn.Exp  exp;
  input String instance_name;
  output list<Absyn.ComponentItem> out_comps;
  algorithm
  out_comps := matchcontinue(comps)
   local
     list<Absyn.ComponentItem> rest;
    Absyn.ComponentItem cnew;
    Option<Absyn.ComponentCondition> condition "condition" ;
    Option<Absyn.Comment> comment "comment" ;
     Absyn.Ident name "name" ;
    Absyn.ArrayDim arrayDim "Array dimensions, if any" ;
    Option<Absyn.Modification> modification "Optional modification" ;
    case {} then {};
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name, arrayDim, modification), condition, comment)::rest
      equation
        cnew = Absyn.COMPONENTITEM(Absyn.COMPONENT(name, arrayDim,
        SOME(Absyn.CLASSMOD({Absyn.MODIFICATION(false, Absyn.NON_EACH(),
          Absyn.IDENT(instance_name), SOME(Absyn.CLASSMOD({}, Absyn.EQMOD(exp, Absyn.dummyInfo))), NONE(), Absyn.dummyInfo)}, Absyn.NOMOD()))), condition, comment);
        then cnew::applyModifier(rest, exp, instance_name);
    case _::rest
        then applyModifier(rest, exp, instance_name);
   end matchcontinue;
end applyModifier;


/*
Absyn.EQMOD(Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT(instance_name, {})), Absyn.EQUAL(), exp), Absyn.dummyInfo))))
record MODIFICATION
    Boolean finalPrefix "final prefix";
    Each eachPrefix "each";
    Path path;
    Option<Modification> modification "modification";
    Option<String> comment "comment";
    Info info;
  end MODIFICATION;
  SOME(Absyn.EQMOD(exp, Absyn.dummyInfo))
 */

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
     //   print("CALL...."  + "\n");
     //   print(Dump.dumpExpStr(Absyn.CALL(crf, fargs)) + "\n");
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
input list<Absyn.Exp>  in_es;
output list<Absyn.Exp>  out_es;
 algorithm
   out_es := matchcontinue(providers)
   local
     Provider pr;
     list<Provider> rest;
     String className;
     String template;
     Absyn.Program upd_env;
     list<Absyn.ComponentItem> comps;
     list<Absyn.Exp>  exps, new_es;
     list<Absyn.ElementItem> mlist;
     Absyn.Exp exp;
    case {} then in_es;
    case PROVIDER(className, template)::rest
      equation
        mlist = Absyn.getElementItemsInClass(vmodel);
        comps = getAllProviderInstances(className, template, mlist, env, {});
        GlobalScript.ISTMTS({GlobalScript.IEXP(exp, _)}, _) = Parser.parsestringexp(template);
        exps = applyTemplate(exp, comps, {});
        new_es = listAppend(exps, in_es);
        then getProviders(rest, vmodel, env, new_es);
   end matchcontinue;
end getProviders;

protected function applyTemplate
  input Absyn.Exp  exp;
  input list<Absyn.ComponentItem> comps;
  input list<Absyn.Exp>  in_es;
  output list<Absyn.Exp>  out_es;
  algorithm
  out_es := matchcontinue(comps)
   local
     list<Absyn.ComponentItem> rest;
     Absyn.Ident name;
    case {} then in_es;
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name, _, _), _, _)::rest
      equation
        then applyTemplate(exp, rest, parseExpression(exp, name)::in_es);
    case _::rest
        then applyTemplate(exp, rest, in_es);
   end matchcontinue;
end applyTemplate;

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
input list<Absyn.ComponentItem> in_components;
output list<Absyn.ComponentItem> out_components;
algorithm
  out_components := matchcontinue(e_items)
   local
   Absyn.ElementItem e_item;
   list<Absyn.ElementItem> rest, re_items;
   list<Absyn.ComponentItem> components, cnew, cnew2;
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
        /*  print ("TESTING PROVIDERS ... ");
          print(Dump.unparseTypeSpec(typeSpec));
          print ("... \n"); */
          if Interactive.isPrimitive(Absyn.pathToCref(path), env) then fail(); end if;
          def := Interactive.getPathedClassInProgram(path,env); // load the element
          if (Absyn.typeSpecPathString(typeSpec) == className) then
          print("... found provider " + className + "\n");
          cnew := listAppend(components, in_components);
          else
          cnew := in_components;
          end if;

          re_items := Absyn.getElementItemsInClass(def);
          cnew2 := getAllProviderInstances(className, template, re_items, env, cnew);
      then getAllProviderInstances(className, template, rest, env, cnew2);
    case (_::rest)
        then getAllProviderInstances(className, template, rest, env, in_components);
  end matchcontinue;
end getAllProviderInstances;


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
  e_items := Absyn.getElementItemsInClass(clazz);
  client_list := parseElementInstList(e_items, env, NO_PRED(), mediators, client_list_in);
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
          /* print ("TESTING ... ");
          print(Dump.unparseTypeSpec(typeSpec));
          print ("... \n"); */
          if Interactive.isPrimitive(Absyn.pathToCref(path), env) then fail(); end if;
          def := Interactive.getPathedClassInProgram(path,env); // load the element
          (isCl, iname, m) := isClient(Absyn.typeSpecPathString(typeSpec), mediators, {});
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
    case {} then (false, "", in_m);
    case MEDIATOR(name, mType, template, clients, providers)::rest
      equation
        (true, nm) = isClientInMediator(ci_name, clients);
        print("... found client : "+ ci_name +"\n");
        then (true, nm, MEDIATOR(name, mType, template, clients, providers)::in_m);
    case _::rest
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
     String name, inst;
     list<Client> rest;
    case {} then (false, "");
    case CLIENT(name, inst)::rest
      equation
        true = (name == ci_name);
        then (true, inst);
    case _::rest
        then isClientInMediator(ci_name, rest);
   end matchcontinue;
end isClientInMediator;



protected function specifiesBindingFor
input Ident name;
input list<Client> clients;
output Boolean isM;
  algorithm
 isM := matchcontinue(clients)
   local
     String className;
   String instance;
   list<Client> rest;
    case {} then false;
    case CLIENT(className, instance)::rest
      equation
       className = name;
        then true;
    case _::rest
        then specifiesBindingFor(name, rest);
   end matchcontinue;
end specifiesBindingFor;


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
    list<Absyn.Exp> cMod, pMod;
    String template, mType, name;
    Absyn.FunctionArgs pArgs, cArgs;
    list<Client> cls;
    list<Provider> prvs;
    case SCode.CLASS(n, _, _, _, SCode.R_PACKAGE(), SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)

      then getMediatorDefsElements(elist, {});
    case SCode.CLASS(n, _, _, _, SCode.R_RECORD(_), SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)
      equation

        (true, SOME(mod)) = isMediator(elist);
        Absyn.STRING(template) = getValue(mod, "template");

        Absyn.STRING(name) = getValue(mod, "name");

        Absyn.STRING(mType) = getValue(mod, "mType");

      // build clients
        Absyn.ARRAY(cMod) =  getValue(mod, "clients");
        cls = getClientList(cMod, {});
      // build providers
        Absyn.ARRAY(pMod) =  getValue(mod, "providers");
        prvs = getProviderList(pMod, {});
      then {MEDIATOR(name,mType,template, cls, prvs)};
    case _
   /* equation print("noName\n");
      print(SCodeDump.unparseElementStr(el)); */
      then {};
   end matchcontinue;
end getMediatorDefsElement;

protected function getClientList
input  list<Absyn.Exp> e;
input  list<Client> val;
output  list<Client> n_val;
  algorithm
  n_val := matchcontinue(e)
   local
     Absyn.FunctionArgs fArgs;
     list<SCode.SubMod>  smod;
     list<Absyn.NamedArg> argNames;
     list<Absyn.Exp> rest;
     String className, instance;
    case {}
        then val;
    case Absyn.CALL(_, Absyn.FUNCTIONARGS(_, argNames))::rest
        equation
         // print ("gettingClients\n");
          className = getArg(argNames, "className");
           // print ("className " +  className + "\n");
          instance = getArg(argNames, "instance");
          // print ("instance " +  instance + "\n");
        then getClientList(rest, CLIENT(className, instance)::val);
   end matchcontinue;
end getClientList;

protected function getProviderList
input  list<Absyn.Exp> e;
input  list<Provider> val;
output  list<Provider> n_val;
  algorithm
  n_val := matchcontinue(e)
   local
     Absyn.FunctionArgs fArgs;
     list<SCode.SubMod>  smod;
     list<Absyn.NamedArg> argNames;
     list<Absyn.Exp> rest;
     String className, providerTemplate;
    case {}
        then val;
    case Absyn.CALL(_, Absyn.FUNCTIONARGS(_, argNames))::rest
        equation
          className = getArg(argNames, "className");
            // print ("className " +  className + "\n");
          providerTemplate = getArg(argNames, "template");
               // print ("providerTemplate " +  providerTemplate + "\n");
        then getProviderList(rest, PROVIDER(className, providerTemplate)::val);
   end matchcontinue;
end getProviderList;

protected function getArg
input  list<Absyn.NamedArg> argNames;
input  String name;
output  String val;
  algorithm
  val := matchcontinue(argNames)
   local
    String str, nname;
     list<Absyn.NamedArg> rest;
    case {}
        then "";
    case Absyn.NAMEDARG(nname, Absyn.STRING(str))::rest
        equation
           true = (nname == name);
        then str;
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
    case SCode.EXTENDS(Absyn.IDENT("Mediator"), _, mod, _, _)::rest
        then (true, SOME(mod));
    case el::rest
        then isMediator(rest);
   end matchcontinue;
end isMediator;

protected function getValue
input  SCode.Mod mod;
input  Absyn.Ident name;
output  Absyn.Exp val;
  algorithm
  val := matchcontinue(mod)
   local
     list<SCode.SubMod>  smod;
    case SCode.MOD(_,_, smod, _, _)
        then getValueR(smod, name);
   end matchcontinue;
end getValue;

protected function getValueR
input list<SCode.SubMod> smod;
input  Absyn.Ident name;
output Absyn.Exp val;
  algorithm
  val := matchcontinue(smod)
   local
     SCode.Mod mod;
     Absyn.Exp eval;
     Absyn.Ident n;
     list<SCode.SubMod> rest;
   case SCode.NAMEMOD(n, SCode.MOD(_,_,_, SOME((eval)), _))::rest
        equation
          if(n <> name) then fail(); end if;
        then eval;
    case  _::rest
        then getValueR(rest, name);
   end matchcontinue;
end getValueR;

protected function getMod
input  SCode.Mod mod;
input  Absyn.Ident name;
output  SCode.Mod val;
  algorithm
  val := matchcontinue(mod)
   local
     list<SCode.SubMod>  smod;
    case SCode.MOD(_,_, smod, _, _)
        then getModR(smod, name);
   end matchcontinue;
end getMod;

protected function getModR
input list<SCode.SubMod> smod;
input  Absyn.Ident name;
output SCode.Mod val;
  algorithm
  val := matchcontinue(smod)
   local
     SCode.Mod nmod;
     Absyn.Exp eval;
     Absyn.Ident n;
     list<SCode.SubMod> rest;
    case SCode.NAMEMOD(n, nmod)::rest
        equation
          if(n <> name) then fail(); end if;
        then nmod;
    case  _::rest
        then getModR(rest, name);
   end matchcontinue;
end getModR;

annotation(__OpenModelica_Interface="backend");
end Binding;
