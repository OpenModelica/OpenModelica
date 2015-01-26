encapsulated package OpenModelicaScriptingAPI

import Absyn;
import CevalScript;
import GlobalScript;
import Parser;

protected

import Values;
import ValuesUtil;
constant Absyn.Msg dummyMsg = Absyn.MSG(SOURCEINFO("<interactive>",false,1,1,1,1,0.0));

public

function generateScriptingAPI
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res1;
  output String res2;
  output String res3;
  output String res4;
algorithm
  (_,Values.TUPLE({Values.BOOL(res1), Values.STRING(res2), Values.STRING(res3), Values.STRING(res4)}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateScriptingAPI", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end generateScriptingAPI;

function getClassInformation
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output String res1;
  output String res2;
  output Boolean res3;
  output Boolean res4;
  output Boolean res5;
  output String res6;
  output Boolean res7;
  output Integer res8;
  output Integer res9;
  output Integer res10;
  output Integer res11;
  output list<String> res12;
protected
  Values.Value res12_arr;
algorithm
  (_,Values.TUPLE({Values.STRING(res1), Values.STRING(res2), Values.BOOL(res3), Values.BOOL(res4), Values.BOOL(res5), Values.STRING(res6), Values.BOOL(res7), Values.INTEGER(res8), Values.INTEGER(res9), Values.INTEGER(res10), Values.INTEGER(res11), res12_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getClassInformation", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
  res12 := list(match res12_arr_iter case Values.STRING() then res12_arr_iter.string; end match for res12_arr_iter in ValuesUtil.arrayValues(res12_arr));
end getClassInformation;

function sortStrings
  input GlobalScript.SymbolTable st;
  input list<String> arr;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "sortStrings", {ValuesUtil.makeArray(list(Values.STRING(arr_iter) for arr_iter in arr))}, st, dummyMsg);
end sortStrings;

function checkInterfaceOfPackages
  input GlobalScript.SymbolTable st;
  input String cl;
  input list<list<String>> dependencyMatrix;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "checkInterfaceOfPackages", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl))), ValuesUtil.makeArray(list(ValuesUtil.makeArray(list(Values.STRING(dependencyMatrix_iter_iter) for dependencyMatrix_iter_iter in dependencyMatrix_iter)) for dependencyMatrix_iter in dependencyMatrix))}, st, dummyMsg);
end checkInterfaceOfPackages;

function GC_expand_hp
  input GlobalScript.SymbolTable st;
  input Integer size;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "GC_expand_hp", {Values.INTEGER(size)}, st, dummyMsg);
end GC_expand_hp;

function GC_gcollect_and_unmap
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
algorithm
  (_,Values.NORETCALL(),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "GC_gcollect_and_unmap", {}, st, dummyMsg);
end GC_gcollect_and_unmap;

function getMemorySize
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Real res;
algorithm
  (_,Values.REAL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getMemorySize", {}, st, dummyMsg);
end getMemorySize;

function threadWorkFailed
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
algorithm
  (_,Values.NORETCALL(),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "threadWorkFailed", {}, st, dummyMsg);
end threadWorkFailed;

function exit
  input GlobalScript.SymbolTable st;
  input Integer status;
  output GlobalScript.SymbolTable outSymTab;
algorithm
  (_,Values.NORETCALL(),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "exit", {Values.INTEGER(status)}, st, dummyMsg);
end exit;

function runScriptParallel
  input GlobalScript.SymbolTable st;
  input list<String> scripts;
  input Integer numThreads;
  input Boolean useThreads;
  output GlobalScript.SymbolTable outSymTab;
  output list<Boolean> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "runScriptParallel", {ValuesUtil.makeArray(list(Values.STRING(scripts_iter) for scripts_iter in scripts)), Values.INTEGER(numThreads), Values.BOOL(useThreads)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.BOOL() then res_arr_iter.boolean; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end runScriptParallel;

function numProcessors
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "numProcessors", {}, st, dummyMsg);
end numProcessors;

function generateEntryPoint
  input GlobalScript.SymbolTable st;
  input String fileName;
  input String entryPoint;
  input String url;
  output GlobalScript.SymbolTable outSymTab;
algorithm
  (_,Values.NORETCALL(),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateEntryPoint", {Values.STRING(fileName), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(entryPoint))), Values.STRING(url)}, st, dummyMsg);
end generateEntryPoint;

function getDerivedClassModifierValue
  input GlobalScript.SymbolTable st;
  input String className;
  input String modifierName;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getDerivedClassModifierValue", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(modifierName)))}, st, dummyMsg);
end getDerivedClassModifierValue;

function getDerivedClassModifierNames
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getDerivedClassModifierNames", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getDerivedClassModifierNames;

function getUses
  input GlobalScript.SymbolTable st;
  input String pack;
  output GlobalScript.SymbolTable outSymTab;
  output list<list<String>> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getUses", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(pack)))}, st, dummyMsg);
  res := list(list(match res_arr_iter_iter case Values.STRING() then res_arr_iter_iter.string; end match for res_arr_iter_iter in ValuesUtil.arrayValues(res_arr_iter)) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getUses;

function getAvailableLibraries
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAvailableLibraries", {}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getAvailableLibraries;

function searchClassNames
  input GlobalScript.SymbolTable st;
  input String searchText;
  input Boolean findInText;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "searchClassNames", {Values.STRING(searchText), Values.BOOL(findInText)}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end searchClassNames;

function extendsFrom
  input GlobalScript.SymbolTable st;
  input String className;
  input String baseClassName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "extendsFrom", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(baseClassName)))}, st, dummyMsg);
end extendsFrom;

function getBooleanClassAnnotation
  input GlobalScript.SymbolTable st;
  input String className;
  input String annotationName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getBooleanClassAnnotation", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(annotationName)))}, st, dummyMsg);
end getBooleanClassAnnotation;

function classAnnotationExists
  input GlobalScript.SymbolTable st;
  input String className;
  input String annotationName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "classAnnotationExists", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(annotationName)))}, st, dummyMsg);
end classAnnotationExists;

function getSimulationOptions
  input GlobalScript.SymbolTable st;
  input String name;
  input Real defaultStartTime;
  input Real defaultStopTime;
  input Real defaultTolerance;
  input Integer defaultNumberOfIntervals;
  input Real defaultInterval;
  output GlobalScript.SymbolTable outSymTab;
  output Real res1;
  output Real res2;
  output Real res3;
  output Integer res4;
  output Real res5;
algorithm
  (_,Values.TUPLE({Values.REAL(res1), Values.REAL(res2), Values.REAL(res3), Values.INTEGER(res4), Values.REAL(res5)}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getSimulationOptions", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(name))), Values.REAL(defaultStartTime), Values.REAL(defaultStopTime), Values.REAL(defaultTolerance), Values.INTEGER(defaultNumberOfIntervals), Values.REAL(defaultInterval)}, st, dummyMsg);
end getSimulationOptions;

function isExperiment
  input GlobalScript.SymbolTable st;
  input String name;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isExperiment", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(name)))}, st, dummyMsg);
end isExperiment;

function getBuiltinType
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getBuiltinType", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end getBuiltinType;

function isProtectedClass
  input GlobalScript.SymbolTable st;
  input String cl;
  input String c2;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isProtectedClass", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl))), Values.STRING(c2)}, st, dummyMsg);
end isProtectedClass;

function isOperatorFunction
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isOperatorFunction", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end isOperatorFunction;

function isOperatorRecord
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isOperatorRecord", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end isOperatorRecord;

function isOperator
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isOperator", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end isOperator;

function isModel
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isModel", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end isModel;

function isPartial
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isPartial", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end isPartial;

function isPackage
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isPackage", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end isPackage;

function basename
  input GlobalScript.SymbolTable st;
  input String path;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "basename", {Values.STRING(path)}, st, dummyMsg);
end basename;

function dirname
  input GlobalScript.SymbolTable st;
  input String path;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "dirname", {Values.STRING(path)}, st, dummyMsg);
end dirname;

function getClassComment
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getClassComment", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end getClassComment;

function typeNameStrings
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "typeNameStrings", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end typeNameStrings;

function typeNameString
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "typeNameString", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end typeNameString;

function stringTypeName
  input GlobalScript.SymbolTable st;
  input String str;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
protected
  Absyn.Path res_path;
algorithm
  (_,Values.CODE(Absyn.C_TYPENAME(path=res_path)),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "stringTypeName", {Values.STRING(str)}, st, dummyMsg);
  res := Absyn.pathString(res_path);
end stringTypeName;

function getTimeStamp
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output Real res1;
  output String res2;
algorithm
  (_,Values.TUPLE({Values.REAL(res1), Values.STRING(res2)}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getTimeStamp", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end getTimeStamp;

function setDocumentationAnnotation
  input GlobalScript.SymbolTable st;
  input String class_;
  input String info;
  input String revisions;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setDocumentationAnnotation", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.STRING(info), Values.STRING(revisions)}, st, dummyMsg);
end setDocumentationAnnotation;

function getDocumentationAnnotation
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getDocumentationAnnotation", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getDocumentationAnnotation;

function iconv
  input GlobalScript.SymbolTable st;
  input String string;
  input String from;
  input String to;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "iconv", {Values.STRING(string), Values.STRING(from), Values.STRING(to)}, st, dummyMsg);
end iconv;

function getNthImport
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthImport", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getNthImport;

function getImportCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getImportCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getImportCount;

function getNthAnnotationString
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthAnnotationString", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthAnnotationString;

function getAnnotationCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAnnotationCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getAnnotationCount;

function getNthInitialEquationItem
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthInitialEquationItem", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthInitialEquationItem;

function getInitialEquationItemsCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getInitialEquationItemsCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getInitialEquationItemsCount;

function getNthEquationItem
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthEquationItem", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthEquationItem;

function getEquationItemsCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getEquationItemsCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getEquationItemsCount;

function getNthInitialEquation
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthInitialEquation", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthInitialEquation;

function getInitialEquationCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getInitialEquationCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getInitialEquationCount;

function getNthEquation
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthEquation", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthEquation;

function getEquationCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getEquationCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getEquationCount;

function getNthInitialAlgorithmItem
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthInitialAlgorithmItem", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthInitialAlgorithmItem;

function getInitialAlgorithmItemsCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getInitialAlgorithmItemsCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getInitialAlgorithmItemsCount;

function getNthAlgorithmItem
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthAlgorithmItem", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthAlgorithmItem;

function getAlgorithmItemsCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAlgorithmItemsCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getAlgorithmItemsCount;

function getNthInitialAlgorithm
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthInitialAlgorithm", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthInitialAlgorithm;

function getInitialAlgorithmCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getInitialAlgorithmCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getInitialAlgorithmCount;

function getNthAlgorithm
  input GlobalScript.SymbolTable st;
  input String class_;
  input Integer index;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNthAlgorithm", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.INTEGER(index)}, st, dummyMsg);
end getNthAlgorithm;

function getAlgorithmCount
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAlgorithmCount", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getAlgorithmCount;

function closeSimulationResultFile
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "closeSimulationResultFile", {}, st, dummyMsg);
end closeSimulationResultFile;

function checkCodeGraph
  input GlobalScript.SymbolTable st;
  input String graphfile;
  input String codefile;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "checkCodeGraph", {Values.STRING(graphfile), Values.STRING(codefile)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end checkCodeGraph;

function checkTaskGraph
  input GlobalScript.SymbolTable st;
  input String filename;
  input String reffilename;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "checkTaskGraph", {Values.STRING(filename), Values.STRING(reffilename)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end checkTaskGraph;

function diffSimulationResultsHtml
  input GlobalScript.SymbolTable st;
  input String var;
  input String actualFile;
  input String expectedFile;
  input Real relTol;
  input Real relTolDiffMinMax;
  input Real rangeDelta;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "diffSimulationResultsHtml", {Values.STRING(var), Values.STRING(actualFile), Values.STRING(expectedFile), Values.REAL(relTol), Values.REAL(relTolDiffMinMax), Values.REAL(rangeDelta)}, st, dummyMsg);
end diffSimulationResultsHtml;

function diffSimulationResults
  input GlobalScript.SymbolTable st;
  input String actualFile;
  input String expectedFile;
  input String diffPrefix;
  input Real relTol;
  input Real relTolDiffMinMax;
  input Real rangeDelta;
  input list<String> vars;
  input Boolean keepEqualResults;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res1;
  output list<String> res2;
protected
  Values.Value res2_arr;
algorithm
  (_,Values.TUPLE({Values.BOOL(res1), res2_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "diffSimulationResults", {Values.STRING(actualFile), Values.STRING(expectedFile), Values.STRING(diffPrefix), Values.REAL(relTol), Values.REAL(relTolDiffMinMax), Values.REAL(rangeDelta), ValuesUtil.makeArray(list(Values.STRING(vars_iter) for vars_iter in vars)), Values.BOOL(keepEqualResults)}, st, dummyMsg);
  res2 := list(match res2_arr_iter case Values.STRING() then res2_arr_iter.string; end match for res2_arr_iter in ValuesUtil.arrayValues(res2_arr));
end diffSimulationResults;

function compareSimulationResults
  input GlobalScript.SymbolTable st;
  input String filename;
  input String reffilename;
  input String logfilename;
  input Real relTol;
  input Real absTol;
  input list<String> vars;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "compareSimulationResults", {Values.STRING(filename), Values.STRING(reffilename), Values.STRING(logfilename), Values.REAL(relTol), Values.REAL(absTol), ValuesUtil.makeArray(list(Values.STRING(vars_iter) for vars_iter in vars))}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end compareSimulationResults;

function readSimulationResultVars
  input GlobalScript.SymbolTable st;
  input String fileName;
  input Boolean readParameters;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "readSimulationResultVars", {Values.STRING(fileName), Values.BOOL(readParameters)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end readSimulationResultVars;

function readSimulationResultSize
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "readSimulationResultSize", {Values.STRING(fileName)}, st, dummyMsg);
end readSimulationResultSize;

function visualize
  input GlobalScript.SymbolTable st;
  input String className;
  input Boolean externalWindow;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "visualize", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.BOOL(externalWindow), Values.STRING(fileName)}, st, dummyMsg);
end visualize;

function plotAll
  input GlobalScript.SymbolTable st;
  input Boolean externalWindow;
  input String fileName;
  input String title;
  input String grid;
  input Boolean logX;
  input Boolean logY;
  input String xLabel;
  input String yLabel;
  input list<Real> xRange;
  input list<Real> yRange;
  input Real curveWidth;
  input Integer curveStyle;
  input String legendPosition;
  input String footer;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res1;
  output list<String> res2;
protected
  Values.Value res2_arr;
algorithm
  (_,Values.TUPLE({Values.BOOL(res1), res2_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "plotAll", {Values.BOOL(externalWindow), Values.STRING(fileName), Values.STRING(title), Values.STRING(grid), Values.BOOL(logX), Values.BOOL(logY), Values.STRING(xLabel), Values.STRING(yLabel), ValuesUtil.makeArray(list(Values.REAL(xRange_iter) for xRange_iter in xRange)), ValuesUtil.makeArray(list(Values.REAL(yRange_iter) for yRange_iter in yRange)), Values.REAL(curveWidth), Values.INTEGER(curveStyle), Values.STRING(legendPosition), Values.STRING(footer)}, st, dummyMsg);
  res2 := list(match res2_arr_iter case Values.STRING() then res2_arr_iter.string; end match for res2_arr_iter in ValuesUtil.arrayValues(res2_arr));
end plotAll;

function getPlotSilent
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getPlotSilent", {}, st, dummyMsg);
end getPlotSilent;

function getPackages
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getPackages", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getPackages;

function getUsedClassNames
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getUsedClassNames", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getUsedClassNames;

function getClassNames
  input GlobalScript.SymbolTable st;
  input String class_;
  input Boolean recursive;
  input Boolean qualified;
  input Boolean sort;
  input Boolean builtin;
  input Boolean showProtected;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getClassNames", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.BOOL(recursive), Values.BOOL(qualified), Values.BOOL(sort), Values.BOOL(builtin), Values.BOOL(showProtected)}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getClassNames;

function setClassComment
  input GlobalScript.SymbolTable st;
  input String class_;
  input String filename;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setClassComment", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.STRING(filename)}, st, dummyMsg);
end setClassComment;

function isShortDefinition
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "isShortDefinition", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end isShortDefinition;

function setSourceFile
  input GlobalScript.SymbolTable st;
  input String class_;
  input String filename;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setSourceFile", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_))), Values.STRING(filename)}, st, dummyMsg);
end setSourceFile;

function getSourceFile
  input GlobalScript.SymbolTable st;
  input String class_;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getSourceFile", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(class_)))}, st, dummyMsg);
end getSourceFile;

function copyClass
  input GlobalScript.SymbolTable st;
  input String className;
  input String newClassName;
  input String withIn;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "copyClass", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.STRING(newClassName), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(withIn)))}, st, dummyMsg);
end copyClass;

function moveClass
  input GlobalScript.SymbolTable st;
  input String className;
  input String direction;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "moveClass", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.STRING(direction)}, st, dummyMsg);
end moveClass;

function translateModelFMU
  input GlobalScript.SymbolTable st;
  input String className;
  input String version;
  input String fileNamePrefix;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "translateModelFMU", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.STRING(version), Values.STRING(fileNamePrefix)}, st, dummyMsg);
end translateModelFMU;

function importFMU
  input GlobalScript.SymbolTable st;
  input String filename;
  input String workdir;
  input Integer loglevel;
  input Boolean fullPath;
  input Boolean debugLogging;
  input Boolean generateInputConnectors;
  input Boolean generateOutputConnectors;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "importFMU", {Values.STRING(filename), Values.STRING(workdir), Values.INTEGER(loglevel), Values.BOOL(fullPath), Values.BOOL(debugLogging), Values.BOOL(generateInputConnectors), Values.BOOL(generateOutputConnectors)}, st, dummyMsg);
end importFMU;

function getLoadedLibraries
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output list<list<String>> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getLoadedLibraries", {}, st, dummyMsg);
  res := list(list(match res_arr_iter_iter case Values.STRING() then res_arr_iter_iter.string; end match for res_arr_iter_iter in ValuesUtil.arrayValues(res_arr_iter)) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end getLoadedLibraries;

function rewriteBlockCall
  input GlobalScript.SymbolTable st;
  input String className;
  input String inDefs;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "rewriteBlockCall", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(inDefs)))}, st, dummyMsg);
end rewriteBlockCall;

function exportToFigaro
  input GlobalScript.SymbolTable st;
  input String path;
  input String database;
  input String mode;
  input String options;
  input String processor;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "exportToFigaro", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(path))), Values.STRING(database), Values.STRING(mode), Values.STRING(options), Values.STRING(processor)}, st, dummyMsg);
end exportToFigaro;

function stringReplace
  input GlobalScript.SymbolTable st;
  input String str;
  input String source;
  input String target;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "stringReplace", {Values.STRING(str), Values.STRING(source), Values.STRING(target)}, st, dummyMsg);
end stringReplace;

function strtok
  input GlobalScript.SymbolTable st;
  input String string;
  input String token;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "strtok", {Values.STRING(string), Values.STRING(token)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end strtok;

function listVariables
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "listVariables", {}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end listVariables;

function convertUnits
  input GlobalScript.SymbolTable st;
  input String s1;
  input String s2;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res1;
  output Real res2;
  output Real res3;
  output Real res4;
  output Real res5;
algorithm
  (_,Values.TUPLE({Values.BOOL(res1), Values.REAL(res2), Values.REAL(res3), Values.REAL(res4), Values.REAL(res5)}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "convertUnits", {Values.STRING(s1), Values.STRING(s2)}, st, dummyMsg);
end convertUnits;

function dumpXMLDAE
  input GlobalScript.SymbolTable st;
  input String className;
  input String translationLevel;
  input Boolean addOriginalIncidenceMatrix;
  input Boolean addSolvingInfo;
  input Boolean addMathMLCode;
  input Boolean dumpResiduals;
  input String fileNamePrefix;
  input String rewriteRulesFile;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res1;
  output String res2;
algorithm
  (_,Values.TUPLE({Values.BOOL(res1), Values.STRING(res2)}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "dumpXMLDAE", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.STRING(translationLevel), Values.BOOL(addOriginalIncidenceMatrix), Values.BOOL(addSolvingInfo), Values.BOOL(addMathMLCode), Values.BOOL(dumpResiduals), Values.STRING(fileNamePrefix), Values.STRING(rewriteRulesFile)}, st, dummyMsg);
end dumpXMLDAE;

function translateGraphics
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "translateGraphics", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end translateGraphics;

function save
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "save", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end save;

function saveTotalModel
  input GlobalScript.SymbolTable st;
  input String fileName;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "saveTotalModel", {Values.STRING(fileName), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end saveTotalModel;

function saveModel
  input GlobalScript.SymbolTable st;
  input String fileName;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "saveModel", {Values.STRING(fileName), Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end saveModel;

function deleteFile
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "deleteFile", {Values.STRING(fileName)}, st, dummyMsg);
end deleteFile;

function loadModel
  input GlobalScript.SymbolTable st;
  input String className;
  input list<String> priorityVersion;
  input Boolean notify;
  input String languageStandard;
  input Boolean requireExactVersion;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "loadModel", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), ValuesUtil.makeArray(list(Values.STRING(priorityVersion_iter) for priorityVersion_iter in priorityVersion)), Values.BOOL(notify), Values.STRING(languageStandard), Values.BOOL(requireExactVersion)}, st, dummyMsg);
end loadModel;

function generateCode
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateCode", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end generateCode;

function runOpenTURNSPythonScript
  input GlobalScript.SymbolTable st;
  input String pythonScriptFile;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "runOpenTURNSPythonScript", {Values.STRING(pythonScriptFile)}, st, dummyMsg);
end runOpenTURNSPythonScript;

function buildOpenTURNSInterface
  input GlobalScript.SymbolTable st;
  input String className;
  input String pythonTemplateFile;
  input Boolean showFlatModelica;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "buildOpenTURNSInterface", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.STRING(pythonTemplateFile), Values.BOOL(showFlatModelica)}, st, dummyMsg);
end buildOpenTURNSInterface;

function instantiateModel
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "instantiateModel", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end instantiateModel;

function checkAllModelsRecursive
  input GlobalScript.SymbolTable st;
  input String className;
  input Boolean checkProtected;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "checkAllModelsRecursive", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.BOOL(checkProtected)}, st, dummyMsg);
end checkAllModelsRecursive;

function checkModel
  input GlobalScript.SymbolTable st;
  input String className;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "checkModel", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className)))}, st, dummyMsg);
end checkModel;

function remove
  input GlobalScript.SymbolTable st;
  input String newDirectory;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "remove", {Values.STRING(newDirectory)}, st, dummyMsg);
end remove;

function mkdir
  input GlobalScript.SymbolTable st;
  input String newDirectory;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "mkdir", {Values.STRING(newDirectory)}, st, dummyMsg);
end mkdir;

function cd
  input GlobalScript.SymbolTable st;
  input String newWorkingDirectory;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "cd", {Values.STRING(newWorkingDirectory)}, st, dummyMsg);
end cd;

function getAstAsCorbaString
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAstAsCorbaString", {Values.STRING(fileName)}, st, dummyMsg);
end getAstAsCorbaString;

function getLanguageStandard
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getLanguageStandard", {}, st, dummyMsg);
end getLanguageStandard;

function getOrderConnections
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getOrderConnections", {}, st, dummyMsg);
end getOrderConnections;

function getShowAnnotations
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getShowAnnotations", {}, st, dummyMsg);
end getShowAnnotations;

function setShowAnnotations
  input GlobalScript.SymbolTable st;
  input Boolean show;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setShowAnnotations", {Values.BOOL(show)}, st, dummyMsg);
end setShowAnnotations;

function getDefaultOpenCLDevice
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getDefaultOpenCLDevice", {}, st, dummyMsg);
end getDefaultOpenCLDevice;

function getVectorizationLimit
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getVectorizationLimit", {}, st, dummyMsg);
end getVectorizationLimit;

function setNoSimplify
  input GlobalScript.SymbolTable st;
  input Boolean noSimplify;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setNoSimplify", {Values.BOOL(noSimplify)}, st, dummyMsg);
end setNoSimplify;

function getNoSimplify
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getNoSimplify", {}, st, dummyMsg);
end getNoSimplify;

function getAnnotationVersion
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAnnotationVersion", {}, st, dummyMsg);
end getAnnotationVersion;

function getClassesInModelicaPath
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getClassesInModelicaPath", {}, st, dummyMsg);
end getClassesInModelicaPath;

function echo
  input GlobalScript.SymbolTable st;
  input Boolean setEcho;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "echo", {Values.BOOL(setEcho)}, st, dummyMsg);
end echo;

function runScript
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "runScript", {Values.STRING(fileName)}, st, dummyMsg);
end runScript;

function clearMessages
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "clearMessages", {}, st, dummyMsg);
end clearMessages;

function countMessages
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res1;
  output Integer res2;
  output Integer res3;
algorithm
  (_,Values.TUPLE({Values.INTEGER(res1), Values.INTEGER(res2), Values.INTEGER(res3)}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "countMessages", {}, st, dummyMsg);
end countMessages;

function getMessagesString
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getMessagesString", {}, st, dummyMsg);
end getMessagesString;

function getErrorString
  input GlobalScript.SymbolTable st;
  input Boolean warningsAsErrors;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getErrorString", {Values.BOOL(warningsAsErrors)}, st, dummyMsg);
end getErrorString;

function readFileNoNumeric
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "readFileNoNumeric", {Values.STRING(fileName)}, st, dummyMsg);
end readFileNoNumeric;

function alarm
  input GlobalScript.SymbolTable st;
  input Integer seconds;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "alarm", {Values.INTEGER(seconds)}, st, dummyMsg);
end alarm;

function compareFiles
  input GlobalScript.SymbolTable st;
  input String file1;
  input String file2;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "compareFiles", {Values.STRING(file1), Values.STRING(file2)}, st, dummyMsg);
end compareFiles;

function compareFilesAndMove
  input GlobalScript.SymbolTable st;
  input String newFile;
  input String oldFile;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "compareFilesAndMove", {Values.STRING(newFile), Values.STRING(oldFile)}, st, dummyMsg);
end compareFilesAndMove;

function writeFile
  input GlobalScript.SymbolTable st;
  input String fileName;
  input String data;
  input Boolean append;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "writeFile", {Values.STRING(fileName), Values.STRING(data), Values.BOOL(append)}, st, dummyMsg);
end writeFile;

function readFile
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "readFile", {Values.STRING(fileName)}, st, dummyMsg);
end readFile;

function getVersion
  input GlobalScript.SymbolTable st;
  input String cl;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getVersion", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(cl)))}, st, dummyMsg);
end getVersion;

function clearCommandLineOptions
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "clearCommandLineOptions", {}, st, dummyMsg);
end clearCommandLineOptions;

function getConfigFlagValidOptions
  input GlobalScript.SymbolTable st;
  input String flag;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res1;
  output String res2;
  output list<String> res3;
protected
  Values.Value res1_arr;
  Values.Value res3_arr;
algorithm
  (_,Values.TUPLE({res1_arr, Values.STRING(res2), res3_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getConfigFlagValidOptions", {Values.STRING(flag)}, st, dummyMsg);
  res1 := list(match res1_arr_iter case Values.STRING() then res1_arr_iter.string; end match for res1_arr_iter in ValuesUtil.arrayValues(res1_arr));
  res3 := list(match res3_arr_iter case Values.STRING() then res3_arr_iter.string; end match for res3_arr_iter in ValuesUtil.arrayValues(res3_arr));
end getConfigFlagValidOptions;

function setCommandLineOptions
  input GlobalScript.SymbolTable st;
  input String option;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCommandLineOptions", {Values.STRING(option)}, st, dummyMsg);
end setCommandLineOptions;

function getAvailableTearingMethods
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res1;
  output list<String> res2;
protected
  Values.Value res1_arr;
  Values.Value res2_arr;
algorithm
  (_,Values.TUPLE({res1_arr, res2_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAvailableTearingMethods", {}, st, dummyMsg);
  res1 := list(match res1_arr_iter case Values.STRING() then res1_arr_iter.string; end match for res1_arr_iter in ValuesUtil.arrayValues(res1_arr));
  res2 := list(match res2_arr_iter case Values.STRING() then res2_arr_iter.string; end match for res2_arr_iter in ValuesUtil.arrayValues(res2_arr));
end getAvailableTearingMethods;

function getTearingMethod
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getTearingMethod", {}, st, dummyMsg);
end getTearingMethod;

function getAvailableIndexReductionMethods
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res1;
  output list<String> res2;
protected
  Values.Value res1_arr;
  Values.Value res2_arr;
algorithm
  (_,Values.TUPLE({res1_arr, res2_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAvailableIndexReductionMethods", {}, st, dummyMsg);
  res1 := list(match res1_arr_iter case Values.STRING() then res1_arr_iter.string; end match for res1_arr_iter in ValuesUtil.arrayValues(res1_arr));
  res2 := list(match res2_arr_iter case Values.STRING() then res2_arr_iter.string; end match for res2_arr_iter in ValuesUtil.arrayValues(res2_arr));
end getAvailableIndexReductionMethods;

function getIndexReductionMethod
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getIndexReductionMethod", {}, st, dummyMsg);
end getIndexReductionMethod;

function getAvailableMatchingAlgorithms
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res1;
  output list<String> res2;
protected
  Values.Value res1_arr;
  Values.Value res2_arr;
algorithm
  (_,Values.TUPLE({res1_arr, res2_arr}),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getAvailableMatchingAlgorithms", {}, st, dummyMsg);
  res1 := list(match res1_arr_iter case Values.STRING() then res1_arr_iter.string; end match for res1_arr_iter in ValuesUtil.arrayValues(res1_arr));
  res2 := list(match res2_arr_iter case Values.STRING() then res2_arr_iter.string; end match for res2_arr_iter in ValuesUtil.arrayValues(res2_arr));
end getAvailableMatchingAlgorithms;

function getMatchingAlgorithm
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getMatchingAlgorithm", {}, st, dummyMsg);
end getMatchingAlgorithm;

function clearDebugFlags
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "clearDebugFlags", {}, st, dummyMsg);
end clearDebugFlags;

function setCompilerFlags
  input GlobalScript.SymbolTable st;
  input String compilerFlags;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCompilerFlags", {Values.STRING(compilerFlags)}, st, dummyMsg);
end setCompilerFlags;

function getModelicaPath
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getModelicaPath", {}, st, dummyMsg);
end getModelicaPath;

function setModelicaPath
  input GlobalScript.SymbolTable st;
  input String modelicaPath;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setModelicaPath", {Values.STRING(modelicaPath)}, st, dummyMsg);
end setModelicaPath;

function getInstallationDirectoryPath
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getInstallationDirectoryPath", {}, st, dummyMsg);
end getInstallationDirectoryPath;

function setInstallationDirectoryPath
  input GlobalScript.SymbolTable st;
  input String installationDirectoryPath;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setInstallationDirectoryPath", {Values.STRING(installationDirectoryPath)}, st, dummyMsg);
end setInstallationDirectoryPath;

function setEnvironmentVar
  input GlobalScript.SymbolTable st;
  input String var;
  input String value;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setEnvironmentVar", {Values.STRING(var), Values.STRING(value)}, st, dummyMsg);
end setEnvironmentVar;

function getEnvironmentVar
  input GlobalScript.SymbolTable st;
  input String var;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getEnvironmentVar", {Values.STRING(var)}, st, dummyMsg);
end getEnvironmentVar;

function getTempDirectoryPath
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getTempDirectoryPath", {}, st, dummyMsg);
end getTempDirectoryPath;

function setTempDirectoryPath
  input GlobalScript.SymbolTable st;
  input String tempDirectoryPath;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setTempDirectoryPath", {Values.STRING(tempDirectoryPath)}, st, dummyMsg);
end setTempDirectoryPath;

function setPlotCommand
  input GlobalScript.SymbolTable st;
  input String plotCommand;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setPlotCommand", {Values.STRING(plotCommand)}, st, dummyMsg);
end setPlotCommand;

function setCompileCommand
  input GlobalScript.SymbolTable st;
  input String compileCommand;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCompileCommand", {Values.STRING(compileCommand)}, st, dummyMsg);
end setCompileCommand;

function getCompileCommand
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getCompileCommand", {}, st, dummyMsg);
end getCompileCommand;

function setCompilerPath
  input GlobalScript.SymbolTable st;
  input String compilerPath;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCompilerPath", {Values.STRING(compilerPath)}, st, dummyMsg);
end setCompilerPath;

function verifyCompiler
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "verifyCompiler", {}, st, dummyMsg);
end verifyCompiler;

function setCXXCompiler
  input GlobalScript.SymbolTable st;
  input String compiler;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCXXCompiler", {Values.STRING(compiler)}, st, dummyMsg);
end setCXXCompiler;

function getCXXCompiler
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getCXXCompiler", {}, st, dummyMsg);
end getCXXCompiler;

function getCFlags
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getCFlags", {}, st, dummyMsg);
end getCFlags;

function setCFlags
  input GlobalScript.SymbolTable st;
  input String inString;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCFlags", {Values.STRING(inString)}, st, dummyMsg);
end setCFlags;

function setCompiler
  input GlobalScript.SymbolTable st;
  input String compiler;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setCompiler", {Values.STRING(compiler)}, st, dummyMsg);
end setCompiler;

function getCompiler
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getCompiler", {}, st, dummyMsg);
end getCompiler;

function setLinkerFlags
  input GlobalScript.SymbolTable st;
  input String linkerFlags;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setLinkerFlags", {Values.STRING(linkerFlags)}, st, dummyMsg);
end setLinkerFlags;

function getLinkerFlags
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getLinkerFlags", {}, st, dummyMsg);
end getLinkerFlags;

function setLinker
  input GlobalScript.SymbolTable st;
  input String linker;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "setLinker", {Values.STRING(linker)}, st, dummyMsg);
end setLinker;

function getLinker
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "getLinker", {}, st, dummyMsg);
end getLinker;

function generateSeparateCodeDependenciesMakefile
  input GlobalScript.SymbolTable st;
  input String filename;
  input String directory;
  input String suffix;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateSeparateCodeDependenciesMakefile", {Values.STRING(filename), Values.STRING(directory), Values.STRING(suffix)}, st, dummyMsg);
end generateSeparateCodeDependenciesMakefile;

function generateSeparateCodeDependencies
  input GlobalScript.SymbolTable st;
  input String stampSuffix;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateSeparateCodeDependencies", {Values.STRING(stampSuffix)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.STRING() then res_arr_iter.string; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end generateSeparateCodeDependencies;

function generateSeparateCode
  input GlobalScript.SymbolTable st;
  input String className;
  input Boolean cleanCache;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateSeparateCode", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(className))), Values.BOOL(cleanCache)}, st, dummyMsg);
end generateSeparateCode;

function generateHeader
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "generateHeader", {Values.STRING(fileName)}, st, dummyMsg);
end generateHeader;

function clearVariables
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "clearVariables", {}, st, dummyMsg);
end clearVariables;

function clearProgram
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "clearProgram", {}, st, dummyMsg);
end clearProgram;

function clear
  input GlobalScript.SymbolTable st;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "clear", {}, st, dummyMsg);
end clear;

function help
  input GlobalScript.SymbolTable st;
  input String topic;
  output GlobalScript.SymbolTable outSymTab;
  output String res;
algorithm
  (_,Values.STRING(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "help", {Values.STRING(topic)}, st, dummyMsg);
end help;

function saveAll
  input GlobalScript.SymbolTable st;
  input String fileName;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "saveAll", {Values.STRING(fileName)}, st, dummyMsg);
end saveAll;

function system_parallel
  input GlobalScript.SymbolTable st;
  input list<String> callStr;
  input Integer numThreads;
  output GlobalScript.SymbolTable outSymTab;
  output list<Integer> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "system_parallel", {ValuesUtil.makeArray(list(Values.STRING(callStr_iter) for callStr_iter in callStr)), Values.INTEGER(numThreads)}, st, dummyMsg);
  res := list(match res_arr_iter case Values.INTEGER() then res_arr_iter.integer; end match for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end system_parallel;

function system
  input GlobalScript.SymbolTable st;
  input String callStr;
  input String outputFile;
  output GlobalScript.SymbolTable outSymTab;
  output Integer res;
algorithm
  (_,Values.INTEGER(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "system", {Values.STRING(callStr), Values.STRING(outputFile)}, st, dummyMsg);
end system;

function loadFileInteractive
  input GlobalScript.SymbolTable st;
  input String filename;
  input String encoding;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "loadFileInteractive", {Values.STRING(filename), Values.STRING(encoding)}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end loadFileInteractive;

function loadFileInteractiveQualified
  input GlobalScript.SymbolTable st;
  input String filename;
  input String encoding;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "loadFileInteractiveQualified", {Values.STRING(filename), Values.STRING(encoding)}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end loadFileInteractiveQualified;

function parseFile
  input GlobalScript.SymbolTable st;
  input String filename;
  input String encoding;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "parseFile", {Values.STRING(filename), Values.STRING(encoding)}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end parseFile;

function parseString
  input GlobalScript.SymbolTable st;
  input String data;
  input String filename;
  output GlobalScript.SymbolTable outSymTab;
  output list<String> res;
protected
  Values.Value res_arr;
algorithm
  (_,res_arr,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "parseString", {Values.STRING(data), Values.STRING(filename)}, st, dummyMsg);
  res := list(ValuesUtil.valString(res_arr_iter) for res_arr_iter in ValuesUtil.arrayValues(res_arr));
end parseString;

function loadString
  input GlobalScript.SymbolTable st;
  input String data;
  input String filename;
  input String encoding;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "loadString", {Values.STRING(data), Values.STRING(filename), Values.STRING(encoding)}, st, dummyMsg);
end loadString;

function reloadClass
  input GlobalScript.SymbolTable st;
  input String name;
  input String encoding;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "reloadClass", {Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(name))), Values.STRING(encoding)}, st, dummyMsg);
end reloadClass;

function loadFiles
  input GlobalScript.SymbolTable st;
  input list<String> fileNames;
  input String encoding;
  input Integer numThreads;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "loadFiles", {ValuesUtil.makeArray(list(Values.STRING(fileNames_iter) for fileNames_iter in fileNames)), Values.STRING(encoding), Values.INTEGER(numThreads)}, st, dummyMsg);
end loadFiles;

function loadFile
  input GlobalScript.SymbolTable st;
  input String fileName;
  input String encoding;
  input Boolean uses;
  output GlobalScript.SymbolTable outSymTab;
  output Boolean res;
algorithm
  (_,Values.BOOL(res),outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "loadFile", {Values.STRING(fileName), Values.STRING(encoding), Values.BOOL(uses)}, st, dummyMsg);
end loadFile;

annotation(__OpenModelica_Interface="backend");
end OpenModelicaScriptingAPI;
