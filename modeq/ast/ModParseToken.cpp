
#include <string.h>
#include <stdio.h>

#include "ModParseToken.h"
#include "parser.h"
#include "comments.h"
#include "bool.h"

extern int splitcells;

ostream &indent(ostream &stream);

char *replaceUnderscore(char *s); // currently in modAST.cpp

extern int currentLine;
extern Comment *pendingComment;
extern char commentBuffer[4096];

ostream &operator<<(ostream &stream, ModParseToken *t) {

  char *r;
  int newLine=t->getLine();
  Comment *cm;

//   cout << "modparse\n";
//   cout << "newLine=" << newLine << "\n";
//   cout << "commentBuffer=" << (void *) commentBuffer << "\n";
  

  if (newLine && (newLine>currentLine)) {
    stream << " " << commentBuffer << "\n";
    *commentBuffer='\0';
    currentLine=newLine;
    pendingComment=pendingComment->printToLine(stream,currentLine);
    stream << indent;
  }

  if (t->getText()) {
    r=replaceUnderscore(t->getText());
    char * text = r;
    while (*text != 0) {
      if (splitcells && ((*text == '"') || (*text == '\\'))) {
	  stream << "\\";
      }
      stream << *text;
      text++;
    }
    // stream << r;
    free(r);
  }

  if (newLine && (cm=findComment(newLine,EOL)))
    strcat(commentBuffer,cm->getText());

  return stream;
}

ModParseToken::ModParseToken(ANTLRTokenType t) {

  // Constructor

  pText=0;
  serial=++counter;
  setType(t);
  setText(NULL);
  _line=0;
}

ModParseToken::ModParseToken(ANTLRTokenType t,ANTLRChar *text) {

  // Constructor

  pText=0;
  serial=++counter;
  setType(t);
  _line=0;
  setText(text);
}

ModParseToken::ModParseToken() {

  // Constructor

  pText=0;
  serial=++counter;
  setType((ANTLRTokenType)0);
  _line=0;
}

ModParseToken::~ModParseToken() {

  // Destructor

  delete [] pText;
  pText=0;
}

ModParseToken::ModParseToken(ANTLRTokenType t, ANTLRChar *text, int line) {

  // Constructor;

  pText=0;
  setType(t);
  setLine(line);
  setText(text);
}

ModParseToken::ModParseToken(const ModParseToken &from) {

  // Copy constructor
  // Copies contents of pText

  this->ANTLRRefCountToken::operator = (from);
  if (this != &from) {
    setText(from.pText);
  }
}

void ModParseToken::setText(ANTLRChar *s) {

  // No range checking on string copy

  if (pText!=NULL) delete [] pText;
  if (s != NULL) {
    pText=new char [strlen(s)+1];
    strcpy(pText,s);
  } else pText=NULL;
}

void ModParseToken::convertFloat() {

  bool fl=false;
  static char buf[256];
  char *p2=strpbrk(pText,"eE");
  if (p2) {
    if (strchr(pText,'.')) fl=true;
    *p2++=0;
    sprintf(buf,"%s%s*^%s",pText,fl? "" : ".",p2);
    setText(buf);
  }
}


ANTLRAbstractToken *ModParseToken::makeToken(ANTLRTokenType t,
					     ANTLRChar *text,
					     int line) {

  return new ModParseToken(t,text,line);
}

int ModParseToken::counter=0;


