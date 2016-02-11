/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package DumpHTML
" file:        DumpHTML.mo
  package:     DumpHTML
  description: Generate HTML documents for Dump Issues

"

public import BackendDAE;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import List;
protected import System;

// =============================================================================
// types
//
// =============================================================================

protected
uniontype Style
  record STYLE
    String name;
    String value;
  end STYLE;
end Style;

protected
uniontype Tag
  record HEADING
    Integer stage;
    String text;
  end HEADING;

  record HYPERLINK
    String href "#anker or javascript:toggle";
    String title;
    String text;
  end HYPERLINK;

  record ANKER
    String name;
  end ANKER;

  record LINE
    String text;
  end LINE;

  record DIVISION
    String id;
    list<Style> style;
    list<Tag> tags;
  end DIVISION;

  record SCRIPT
    String type_;
    String text;
  end SCRIPT;
end Tag;

protected
uniontype Document
  record DOCUMENT
    String docType;
    list<Tag> head "because of performance issues tags in reverse order";
    list<Tag> body "because of performance issues tags in reverse order";
  end DOCUMENT;
end Document;

protected constant Document emptyDocument = DOCUMENT("", {}, {});

protected function emtypDocumentWithToggleFunktion "author Frenkel TUD 2012-11"
  output Document outDoc;
algorithm
  outDoc := addScript("text/Javascript",
    "function toggle(name) {\n   var element = document.getElementById(name);\n   if (element.style.display == \"none\") {\n      // show the div\n      element.style.display = \"block\";   \n   } else {\n      // hide the div\n      element.style.display = \"none\";\n      // reset element\n      element.reset();\n   }\n}\n\nfunction show(name) {\n   var element = document.getElementById(name);\n   if (element.style.display == \"none\") {\n      // show the div\n      element.style.display = \"block\";   \n   }\n   return true;\n}\n",
    emptyDocument);
end emtypDocumentWithToggleFunktion;

protected function addScript "add a script to the head of the document.
  author Frenkel TUD 2012-11"
  input String type_;
  input String script;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addHeadTag(SCRIPT(type_, script), inDoc);
end addScript;

protected function addHeading "add a heading to the body of the document.
  author Frenkel TUD 2012-11"
  input Integer stage;
  input String text;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(HEADING(stage, text), inDoc);
end addHeading;

protected function addHeadingTag "add a heading to the body of the document.
  author Frenkel TUD 2012-11"
  input Integer stage;
  input String text;
  input list<Tag> inTags;
  output list<Tag> outTags;
algorithm
  outTags := HEADING(stage, text)::inTags;
end addHeadingTag;

protected function addHyperLink "add a hyperlink to the body of the document.
  author Frenkel TUD 2012-11"
  input String href "#anker or javascript:toggle";
  input String title;
  input String text;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(HYPERLINK(href, title, text), inDoc);
end addHyperLink;

protected function addHyperLinkTag "add a hyperlink to the body of the document.
  author Frenkel TUD 2012-11"
  input String href "#anker or javascript:toggle";
  input String title;
  input String text;
  input list<Tag> inTags;
  output list<Tag> outTags;
algorithm
  outTags := HYPERLINK(href, title, text)::inTags;
end addHyperLinkTag;

protected function addAnkerTag "add a anker to the body of the document.
  author Frenkel TUD 2012-11"
  input String name;
  input list<Tag> inTags;
  output list<Tag> outTags;
algorithm
  outTags := ANKER(name)::inTags;
end addAnkerTag;

protected function addLine "add a line to the body of the document.
  author Frenkel TUD 2012-11"
  input String text;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(LINE(text), inDoc);
end addLine;

protected function addLineTag "add a line to the body of the document.
  author Frenkel TUD 2012-11"
  input String text;
  input list<Tag> inTags;
  output list<Tag> outTags;
algorithm
  outTags := LINE(text)::inTags;
end addLineTag;

protected function addDivision "add a hyper-link to the body of the document.
  author Frenkel TUD 2012-11"
  input String id;
  input list<Style> style;
  input list<Tag> tags;
  input Document inDoc;
  output Document outDoc;
protected
  list<Tag> t;
algorithm
  t := listReverse(tags);
  outDoc := addBodyTag(DIVISION(id, style, t), inDoc);
end addDivision;

protected function addDivisionTag "add a hyper-link to the body of the document.
  author Frenkel TUD 2012-11"
  input String id;
  input list<Style> style;
  input list<Tag> tags;
  input list<Tag> inTags;
  output list<Tag> outTags;
protected
  list<Tag> t;
algorithm
  t := listReverse(tags);
  outTags := DIVISION(id, style, t)::inTags;
end addDivisionTag;

protected function addBodyTags "add a body tag in the document.
  author Frenkel TUD 2012-11"
  input list<Tag> tags;
  input Document inDoc;
  output Document outDoc;
protected
  String docType;
  list<Tag> head, body, t;
algorithm
  t := listReverse(tags);
  DOCUMENT(docType=docType, head=head, body=body) := inDoc;
  body := listAppend(body, t);
  outDoc := DOCUMENT(docType, head, body);
end addBodyTags;

protected function dumpDocument " author: Frenkel TUD 2011-08
  print the document to file"
  input Document inDoc;
  input String name;
protected
  String str;
  list<Tag> head, body;
algorithm
  DOCUMENT(docType=str, head=head, body=body) := inDoc;
  str := str + "\n<html>\n<head>";
  str := List.fold(listReverse(head), dumpTag, str);
  str := str + "\n</head>";
  str := str + "\n<body>";
  str := List.fold(listReverse(body), dumpTag, str);
  str := str + "\n</body>\n</html>";
  System.writeFile(name, str);
end dumpDocument;

protected function addHeadTag "add a head tag in the document.
  author Frenkel TUD 2012-11"
  input Tag tag;
  input Document inDoc;
  output Document outDoc;
protected
  String docType;
  list<Tag> head, body;
algorithm
  DOCUMENT(docType=docType, head=head, body=body) := inDoc;
  outDoc := DOCUMENT(docType, tag::head, body);
end addHeadTag;

protected function addBodyTag "add a body tag in the document.
  author Frenkel TUD 2012-11"
  input Tag tag;
  input Document inDoc;
  output Document outDoc;
protected
  String docType;
  list<Tag> head, body;
algorithm
  DOCUMENT(docType=docType, head=head, body=body) := inDoc;
  outDoc := DOCUMENT(docType, head, tag::body);
end addBodyTag;

protected function dumpTag "appends a tag to the buffer string.
  author Frenkel TUD 2012-11"
  input Tag tag;
  input String iBuffer;
  output String oBuffer;
algorithm
  oBuffer := match(tag, iBuffer)
    local
      Integer i;
      String t, t1, t2, str;
      list<Style> style;
      list<Tag> tags;
    case (HEADING(stage=i, text=t), _)
      equation
        str = iBuffer + "\n<h" + intString(i) + ">" + t + "</h" + intString(i) + ">";
      then
        str;
    case (HYPERLINK(href=t, title=t1, text=t2), _)
      equation
        str = iBuffer + "\n<a href=\"" + t + "\" title=\"" + t1 + "\">" + t2 + "</a>";
      then
        str;
    case (ANKER(name=t), _)
      equation
        str = iBuffer + "\n<a name=\"" + t + "\"/>";
      then
        str;
    case (LINE(text=t), _)
      equation
        str = iBuffer + "\n" + t + "<br>";
      then
        str;
    case (DIVISION(id=t, style=style, tags=tags), _)
      equation
        t1 = stringDelimitList(List.map(style, dumpStyle), "; ");
        t2 = List.fold(tags, dumpTag, "");
        str = iBuffer + "\n<div id=\"" + t + "\" style=\"" + t1 + "\">\n" + t2 + "\n</div>";
      then
        str;
    case (SCRIPT(type_=t1, text=t2), _)
      equation
        str = iBuffer + "\n<script type=\"" + t1 + "\">\n" + t2 + "\n</script>";
      then
        str;
  end match;
end dumpTag;

protected function dumpStyle "appends a style to the buffer string.
  author Frenkel TUD 2012-11"
  input Style inStyle;
  output String outBuffer;
protected
  String name, value;
algorithm
  STYLE(name, value) := inStyle;
  outBuffer := name + ": " + value;
end dumpStyle;

public function dumpDAE
  input BackendDAE.BackendDAE inDAE;
  input String inHeader;
  input String inFilename;
protected
  Document doc;
  String str;
  BackendDAE.EqSystems eqs;
algorithm
  BackendDAE.DAE(eqs=eqs) := inDAE;
  doc := emtypDocumentWithToggleFunktion();
  doc := addHeading(1, inHeader, doc);
  str := intString(realInt(System.time()));
  ((doc, _)) := List.fold1(eqs, dumpEqSystem, str, (doc, 1));
  dumpDocument(doc, str + inFilename);
end dumpDAE;

protected function dumpEqSystem "dumps the BackendDAE.EqSystem"
  input BackendDAE.EqSystem inEqSystem;
  input String inPrefixIdstr;
  input tuple<Document, Integer> inTpl;
  output tuple<Document, Integer> outTpl;
protected
  list<BackendDAE.Var> vars;
  Integer eqnlen, eqnssize, i;
  String varlen_str, eqnlen_str, prefixIdstr, prefixId;
  list<BackendDAE.Equation> eqnsl;
  BackendDAE.Variables vars1;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrix> mT;
  BackendDAE.Matching matching;
  Document doc;
  list<Tag> tags;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars1, orderedEqs=eqns, m=m, mT=mT, matching=matching) := inEqSystem;
  (doc, i) := inTpl;
  prefixId := inPrefixIdstr + "_" + intString(i);
  vars := BackendVariable.varList(vars1);
  varlen_str := "Variables (" + intString(listLength(vars)) + ")";
  tags := addHeadingTag(2, varlen_str, {});
  tags := printVarList(vars, prefixId, tags);
  eqnsl := BackendEquation.equationList(eqns);
  eqnlen_str := "Equations (" + intString(listLength(eqnsl)) + ", " + intString(BackendDAEUtil.equationSize(eqns)) + ")";
  tags := addHeadingTag(2, eqnlen_str, tags);
  tags := dumpEqns(eqnsl, prefixId, tags);
  //dumpOption(m, dumpIncidenceMatrix);
  //dumpOption(mT, dumpIncidenceMatrixT);
  tags := dumpFullMatching(matching, prefixId, tags);
//  doc := addBodyTags(tags, doc);
  doc := addLine("<hr>", doc);
  doc := addHyperLink("javascript:toggle('" + prefixId + "system')", "show system", "show/hide system " + intString(i), doc);
  doc := addDivision(prefixId + "system", {STYLE("display", "none")}, tags, doc);
  outTpl := (doc, i+1);
end dumpEqSystem;

protected function printVarList
  input list<BackendDAE.Var> vars;
  input String prefixId;
  input list<Tag> inTags;
  output list<Tag> outTags;
protected
  list<Tag> tags;
algorithm
  ((tags, _)) := List.fold1(vars, dumpVar, prefixId, ({}, 1));
  outTags := addHyperLinkTag("javascript:toggle('" + prefixId + "variables')", "show variables", "show/hide variables", inTags);
  outTags := addDivisionTag(prefixId + "variables", {STYLE("background", "#FFFFCC"), STYLE("display", "none")}, tags, outTags);
end printVarList;

protected function dumpVar
  input BackendDAE.Var inVar;
  input String prefixId;
  input tuple<list<Tag>, Integer> inTpl;
  output tuple<list<Tag>, Integer> oTpl;
protected
  list<Tag> tags;
  Integer i;
  String ln, istr;
algorithm
  (tags, i) := inTpl;
  istr := intString(i);
  ln := prefixId + "varanker" + istr;
  tags := addAnkerTag(ln, tags);
  ln := istr + ": " + BackendDump.varString(inVar);
  tags := addLineTag(ln, tags);
  oTpl := (tags, i+1);
end dumpVar;

protected function dumpEqns
  input list<BackendDAE.Equation> eqns;
  input String prefixId;
  input list<Tag> inTags;
  output list<Tag> outTags;
protected
  list<Tag> tags;
algorithm
  ((tags, _)) := List.fold1(eqns, dumpEqn, prefixId, ({}, 1));
  outTags := addHyperLinkTag("javascript:toggle('" + prefixId + "equations')", "show equations", "show/hide equations", inTags);
  outTags := addDivisionTag(prefixId + "equations", {STYLE("background", "#C0C0C0"), STYLE("display", "none")}, tags, outTags);
end dumpEqns;

protected function dumpEqn
  input BackendDAE.Equation inEquation;
  input String prefixId;
  input tuple<list<Tag>, Integer> inTpl;
  output tuple<list<Tag>, Integer> oTpl;
protected
  list<Tag> tags;
  Integer i;
  String ln, istr;
algorithm
  (tags, i) := inTpl;
  istr := intString(i);
  ln := prefixId + "eqanker" + istr;
  tags := addAnkerTag(ln, tags);
  ln := istr + " (" + intString(BackendEquation.equationSize(inEquation)) + "): " + BackendDump.equationString(inEquation);
  tags := addLineTag(ln, tags);
  oTpl := (tags, i+1);
end dumpEqn;

protected function dumpFullMatching
  input BackendDAE.Matching inMatch;
  input String prefixId;
  input list<Tag> inTags;
  output list<Tag> outTags;
algorithm
  outTags := match(inMatch)
    local
      array<Integer> ass1;
      list<Tag> tags;
      //BackendDAE.StrongComponents comps;

    case (BackendDAE.NO_MATCHING()) then inTags;
    case (BackendDAE.MATCHING(ass1, _, _)) equation
      tags = dumpMatching(ass1, prefixId, inTags);
      //dumpComponents(comps);
    then tags;
  end match;
end dumpFullMatching;

protected function dumpMatching "author: Frenkel TUD 2012-11
  prints the matching information"
  input array<Integer> v;
  input String prefixId;
  input list<Tag> inTags;
  output list<Tag> outTags;
protected
  Integer len;
  String len_str;
  list<Tag> tags;
algorithm
  outTags := addHeadingTag(2, "Matching", inTags);
  len := arrayLength(v);
  len_str := intString(len) + " variables and equations\n";
  outTags := addLineTag(len_str, outTags);
  tags := dumpMatching2(v, 1, len, prefixId, {});
  outTags := addHyperLinkTag("javascript:toggle('" + prefixId + "matching')", "show matching", "show/hide matching", outTags);
  outTags := addDivisionTag(prefixId + "matching", {STYLE("background", "#339966"), STYLE("display", "none")}, tags, outTags);
end dumpMatching;

protected function dumpMatching2 "author: PA
  Helper function to dumpMatching."
  input array<Integer> v;
  input Integer i;
  input Integer len;
  input String prefixId;
  input list<Tag> inTags;
  output list<Tag> outTags;
protected
  Integer eqn;
  String s, s2;
algorithm
  try
    true := intLe(i, len);
    s := intString(i);
    eqn := v[i];
    s2 := intString(eqn);
    s := "Variable <a href=\"#" + prefixId + "varanker" + s + "\" onclick=\"return show('" + prefixId + "variables');\">" + s + "</a> is solved in equation  <a href=\"#" + prefixId + "eqanker" + s2 + "\" onclick=\"return show('" + prefixId + "equations');\">" + s2 + "</a>";
    outTags := dumpMatching2(v, i+1, len, prefixId, LINE(s)::inTags);
  else
    outTags := inTags;
  end try;
end dumpMatching2;

annotation(__OpenModelica_Interface="backend");
end DumpHTML;
