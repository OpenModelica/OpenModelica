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

  RCS: $Id: DumpHTML.mo 14019 2012-11-22 13:31:15Z jfrenkel $
"

protected import List;
protected import System;

/*************************************************
 * types
 ************************************************/

public type Style = list<tuple<String,String>>;

public uniontype Tag
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
    Style style;
    Tags tags;
  end DIVISION;
  record SCRIPT
    String type_;
    String text;
  end SCRIPT;
end Tag;

public type Tags = list<Tag>;

public uniontype Document
  record DOCUMENT
    String docType;
    Tags head "because of performance issues tags in reverse order";
    Tags body "because of performance issues tags in reverse order";
  end DOCUMENT;
end Document;

public constant Document emptyDocument = DOCUMENT("",{},{});

/*************************************************
 * public
 ************************************************/

public function emtypDocumentWithToggleFunktion
"author Frenkel TUD 2012-11"
  output Document outDoc;
algorithm
  outDoc := addScript("text/Javascript",
    "function toggle(name) {\n   var element = document.getElementById(name);\n   if (element.style.display == \"none\") {\n      // show the div\n      element.style.display = \"block\";   \n   } else {\n      // hide the div\n      element.style.display = \"none\";\n      // reset element\n      element.reset();\n   }\n}\n\nfunction show(name) {\n   var element = document.getElementById(name);\n   if (element.style.display == \"none\") {\n      // show the div\n      element.style.display = \"block\";   \n   }\n   return true;\n}\n",
    emptyDocument);
end emtypDocumentWithToggleFunktion;

public function setDocType
"set the doctype of the document.
  author Frenkel TUD 2012-11"
  input String docType;
  input Document inDoc;
  output Document outDoc;
protected
  Tags head,body;
algorithm
  DOCUMENT(head=head,body=body) := inDoc;
  outDoc := DOCUMENT(docType,head,body);
end setDocType;

public function addScript
"add a script to the head of the document.
  author Frenkel TUD 2012-11"
  input String type_;
  input String script;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addHeadTag(SCRIPT(type_,script),inDoc);
end addScript;

public function addHeading
"add a heading to the body of the document.
  author Frenkel TUD 2012-11"
  input Integer stage;
  input String text;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(HEADING(stage,text),inDoc);
end addHeading;

public function addHeadingTag
"add a heading to the body of the document.
  author Frenkel TUD 2012-11"
  input Integer stage;
  input String text;
  input Tags inTags;
  output Tags outTags;
algorithm
  outTags := HEADING(stage,text)::inTags;
end addHeadingTag;

public function addHyperLink
"add a hyperlink to the body of the document.
  author Frenkel TUD 2012-11"
  input String href "#anker or javascript:toggle";
  input String title;
  input String text;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(HYPERLINK(href,title,text),inDoc);
end addHyperLink;

public function addHyperLinkTag
"add a hyperlink to the body of the document.
  author Frenkel TUD 2012-11"
  input String href "#anker or javascript:toggle";
  input String title;
  input String text;
  input Tags inTags;
  output Tags outTags;
algorithm
  outTags := HYPERLINK(href,title,text)::inTags;
end addHyperLinkTag;

public function addAnker
"add a anker to the body of the document.
  author Frenkel TUD 2012-11"
  input String name;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(ANKER(name),inDoc);
end addAnker;

public function addAnkerTag
"add a anker to the body of the document.
  author Frenkel TUD 2012-11"
  input String name;
  input Tags inTags;
  output Tags outTags;
algorithm
  outTags := ANKER(name)::inTags;
end addAnkerTag;

public function addLine
"add a line to the body of the document.
  author Frenkel TUD 2012-11"
  input String text;
  input Document inDoc;
  output Document outDoc;
algorithm
  outDoc := addBodyTag(LINE(text),inDoc);
end addLine;

public function addLineTag
"add a line to the body of the document.
  author Frenkel TUD 2012-11"
  input String text;
  input Tags inTags;
  output Tags outTags;
algorithm
  outTags := LINE(text)::inTags;
end addLineTag;

public function addDivision
"add a hyperlink to the body of the document.
  author Frenkel TUD 2012-11"
  input String id;
  input Style style;
  input Tags tags;
  input Document inDoc;
  output Document outDoc;
protected
  Tags t;
algorithm
  t := listReverse(tags);
  outDoc := addBodyTag(DIVISION(id,style,t),inDoc);
end addDivision;

public function addDivisionTag
"add a hyperlink to the body of the document.
  author Frenkel TUD 2012-11"
  input String id;
  input Style style;
  input Tags tags;
  input Tags inTags;
  output Tags outTags;
protected
  Tags t;
algorithm
  t := listReverse(tags);
  outTags := DIVISION(id,style,t)::inTags;
end addDivisionTag;

public function addBodyTags
"add a body tag in the document.
  author Frenkel TUD 2012-11"
  input Tags tags;
  input Document inDoc;
  output Document outDoc;
protected
  String docType;
  Tags head,body,t;
algorithm
  t := listReverse(tags);
  DOCUMENT(docType=docType,head=head,body=body) := inDoc;
  body := listAppend(body,t);
  outDoc := DOCUMENT(docType,head,body);
end addBodyTags;

public function dumpDocument
" author: Frenkel TUD 2011-08
 print the dokument to file"
  input Document inDoc;
  input String name;
protected
  String str;
  Tags head,body;
algorithm
  DOCUMENT(docType=str,head=head,body=body) := inDoc;
  str := str +& "\n<html>\n<head>";
  str := List.fold(listReverse(head),dumpTag,str);
  str := str +& "\n</head>";
  str := str +& "\n<body>";
  str := List.fold(listReverse(body),dumpTag,str);
  str := str +& "\n</body>\n</html>";
  System.writeFile(name,str);
end dumpDocument;

/*************************************************
 * protected
 ************************************************/

protected function addHeadTag
"add a head tag in the document.
  author Frenkel TUD 2012-11"
  input Tag tag;
  input Document inDoc;
  output Document outDoc;
protected
  String docType;
  Tags head,body;
algorithm
  DOCUMENT(docType=docType,head=head,body=body) := inDoc;
  outDoc := DOCUMENT(docType,tag::head,body);
end addHeadTag;

protected function addBodyTag
"add a body tag in the document.
  author Frenkel TUD 2012-11"
  input Tag tag;
  input Document inDoc;
  output Document outDoc;
protected
  String docType;
  Tags head,body;
algorithm
  DOCUMENT(docType=docType,head=head,body=body) := inDoc;
  outDoc := DOCUMENT(docType,head,tag::body);
end addBodyTag;

protected function dumpTag
"appends a tag to the buffer string.
  author Frenkel TUD 2012-11"
   input Tag tag;
   input String iBuffer;
   output String oBuffer;
algorithm
  oBuffer := match(tag,iBuffer)
    local
      Integer i;
      String t,t1,t2,str;
      Style style;
      Tags tags;
    case (HEADING(stage=i,text=t),_)
      equation
        str = iBuffer +& "\n<h" +& intString(i) +& ">" +& t +& "</h" +& intString(i) +& ">";
      then
        str;
    case (HYPERLINK(href=t,title=t1,text=t2),_)
      equation
        str = iBuffer +& "\n<a href=\"" +& t +& "\" title=\"" +& t1 +& "\">" +& t2 +& "</a>";
      then
        str;
    case (ANKER(name=t),_)
      equation
        str = iBuffer +& "\n<a name=\"" +& t +& "\"/>";
      then
        str;
    case (LINE(text=t),_)
      equation
        str = iBuffer +& "\n" +& t +& "<br>";
      then
        str;
    case (DIVISION(id=t,style=style,tags=tags),_)
      equation
        t1 = stringDelimitList(List.map(style,dumpStyle),"; ");
        t2 = List.fold(tags,dumpTag,"");
        str = iBuffer +& "\n<div id=\"" +& t +& "\" style=\"" +& t1 +& "\">\n" +& t2 +& "\n</div>";
      then
        str;
    case (SCRIPT(type_=t1,text=t2),_)
      equation
        str = iBuffer +& "\n<script type=\"" +& t1 +& "\">\n" +& t2 +& "\n</script>";
      then
        str;
  end match;
end dumpTag;

protected function dumpStyle
"appends a style to the buffer string.
  author Frenkel TUD 2012-11"
   input tuple<String,String> st;
   output String oBuffer;
protected
  String name,value;
algorithm
  (name,value) := st;
  oBuffer := name +& ": " +& value;
end dumpStyle;


end DumpHTML;
