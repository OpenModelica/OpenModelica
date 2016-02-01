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
   Client_e predecessors;
   list<Mediator> mediator;
 end CLIENT_E;

 record NO_PRED end NO_PRED;
end Client_e;

public function inferBindings "@autor lenab : root function called from API "
input Absyn.Class model_def;
input Absyn.Program env;
protected
  list<Mediator> ms;
  list<SCode.Element> scode_def;
  SCode.Element scode_model;
  list<Client_e> client_list;
algorithm
  scode_def := SCodeUtil.translateAbsyn2SCode(env);
  //print(SCodeDump.programStr(scode_def));
  ms := getMediatorDefsElements(scode_def, {});
  scode_model := SCodeUtil.translateClass(model_def);
  client_list := buildInstList(model_def, env, NO_PRED(), ms, {});

end inferBindings;

protected function inferBindingClientList
input list<Client_e> client_list "list of nodes for which the binding is inferred";
input SCode.Program vmodel;
input Absyn.Program env;
output Boolean isBindingPossible;
//output String bindingExpression;
 algorithm
  isBindingPossible := matchcontinue(client_list)
   local
     Client_e ce;
     list<Client_e> rest;
    case {} then true;
    case ce::rest
      equation
       // inferBindingClient(ce);
        then inferBindingClientList(rest, vmodel, env);
   end matchcontinue;
end inferBindingClientList;

/* function parseAscendants
  input list<Absyn.Class> ascendants;
  input list<Mediator> mediators;
  input String in_dataset;
  output Boolean isBindingPossible;
  //output String out_dataset;
algorithm
  (isBindingPossible) := match(ascendants, mediators)
   local
    Absyn.Class ci;
    list<Absyn.Class> rest;
    case ({}, _)
      then false;
    case (ci::rest, _)
      equation
        parseMediators(ci, mediators, in_dataset);
        parseAscendants(rest, mediators, in_dataset);
        then false;
  end match;
end parseAscendants;

function parseMediators
  input Absyn.Class client;
  input list<Absyn.Class> elems;
  input list<Mediator> mediators;
  input String in_dataset;
  output Boolean isBindingPossible;
  output String out_dataset= "";
algorithm
  (isBindingPossible) := match(client, mediators)
   local
    Mediator mediator;
    list<Mediator> rest;
    Ident cname;
     String name;
   String mType;
   String template;
   list<Client> clients;
   list<Provider> providers;
    case (_, {})
      then false;
    case (Absyn.CLASS(cname, _, _, _, _, _, _), MEDIATOR(name, mType, template, clients, providers)::rest)
      equation
        if specifiesBindingFor(cname, clients) then
          isBindingPossible = true;
          // get providers and mediator operation
         // getProviders(elems, providers);
        end if;
        parseMediators(client, elems, rest, in_dataset);
        then false;
  end match;
end parseMediators;

/*public function getProviders
input Ident name;
input list<Absyn.Class> elems;
output Boolean isM;
  algorithm
 isM := matchcontinue(clients)
   local
     String className;
   String instance;
   list<Client> rest;
    case {} then {};
    case CLIENT(className, instance)::rest
      equation
       className = name;
        then true;
    case _::rest
        then specifiesBindingFor(name, rest);
   end matchcontinue;
end getProviders; */

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
  client_list := parseElementInstList(e_items, env, NO_PRED(), mediators, {});
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
   Client_e new_predecessors;
   Absyn.Class def;
   list<Client_e> l1, l2;
   Boolean isCl;
   List<Mediator> m;
   case {}
     then predecessors::in_client_list;
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(_,_,_, Absyn.COMPONENTS(_,typeSpec, components), _, _))::rest)
      algorithm
          path := Absyn.typeSpecPath(typeSpec);
          print ("TESTING ... ");
          print(Dump.unparseTypeSpec(typeSpec));
          print ("... \n");
          if Interactive.isPrimitive(Absyn.pathToCref(path), env) then fail(); end if;
          def := Interactive.getPathedClassInProgram(path,env); // load the element
          (isCl, m) := isClient(Absyn.typeSpecPathString(typeSpec), mediators);
           if(isCl) then
             new_predecessors := CLIENT_E(components, typeSpec, def, predecessors, m);
           else
             new_predecessors := predecessors;
           end if;
         l1 := buildInstList(def, env, new_predecessors,  mediators, in_client_list);

      then parseElementInstList(rest, env, predecessors, mediators, listAppend(l1, in_client_list));
    case (_::rest)
        then parseElementInstList(rest, env, predecessors, mediators, in_client_list);
  end matchcontinue;
end parseElementInstList;

protected function isClient
input String ci_name ;
input list<Mediator> mediators;
output Boolean isClient;
output List<Mediator> m;
algorithm
  (isClient, m) := matchcontinue(mediators)
   local
     String name;
     String mType;
     String template;
     list<Client> clients;
     list<Provider> providers;
     list<Mediator> rest;
    case {} then (false, {});
    case MEDIATOR(name, mType, template, clients, providers)::rest
      equation
        true = isClientInMediator(ci_name, clients);
        print("... found client : "+ ci_name +"\n");
        then (true, {MEDIATOR(name, mType, template, clients, providers)});
    case _::rest
        then isClient(ci_name, rest);
   end matchcontinue;
end isClient;

protected function isClientInMediator
input String ci_name ;
input list<Client> clients;
output Boolean isClient;
algorithm

  isClient := matchcontinue(clients)
   local
      list<Absyn.Class> parents;
     Absyn.Class current_ci;
     String name;
     list<Client> rest;
    case {} then (false);
    case CLIENT(name, _)::rest
      equation
        true = (name == ci_name);
        then true;
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
      equation print("yesName " + n +" \n");

      then getMediatorDefsElements(elist, {});
    case SCode.CLASS(n, _, _, _, SCode.R_RECORD(_), SCode.PARTS(elist, _,_,_,_,_,_,_), _, _)
      equation
        print("TRY " + " \n");
        (true, SOME(mod)) = isMediator(elist);
        Absyn.STRING(template) = getValue(mod, "template");
        print(template + " TEMPLATE\n");
        Absyn.STRING(name) = getValue(mod, "name");
        print(name + " NAME\n");
        Absyn.STRING(mType) = getValue(mod, "mType");
        print(mType + " MTYPE\n");
      print("zingName " + n +" \n");
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
          print ("gettingClients\n");
          className = getArg(argNames, "className");
            print ("className " +  className + "\n");
          instance = getArg(argNames, "instance");
          print ("instance " +  instance + "\n");
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
          providerTemplate = getArg(argNames, "providerTemplate");
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
           nname = name;
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
