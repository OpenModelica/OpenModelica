
#include "modAST.h"
#include "ModParse.h"
#include "parser.h"

#include <iostream.h>

extern int splitcells;

class NodeInfo empty_ni={ NO_SPECIAL,0 };

static int strcount(char *s,char c) {
  int count=0;
  for (;*s;s++) if (*s==c) count++;
  return count;
}

char *replaceUnderscore(char *s) {

  static const char *replacement="$";
  int uscount=strcount(s,'_');
  char *newstr;
  char tmp[2];

  tmp[1]='\0';
  newstr=(char *) malloc(strlen(s)-uscount+strlen(replacement)*uscount+1);
  *newstr='\0';
  for (;*s;s++) {
    if (*s=='_') strcat(newstr,replacement);
    else {
      tmp[0]=*s;
      strcat(newstr,tmp);
    }
  }
  return newstr;
}

extern int currentLine;
extern Comment *pendingComment;
extern char commentBuffer[4096];

ostream &indent(ostream &stream);

ostream &operator<<(ostream &stream,AST *node) {

  ModParseToken *t=mytoken(node->pToken);
  int newLine=t->getLine();
  Comment *cm;

  //  cout << "modast\n";

  if (newLine && (newLine>currentLine)) {
    stream << " " << commentBuffer << "\n";
    *commentBuffer='\0';
    currentLine=newLine;
    pendingComment=pendingComment->printToLine(stream,currentLine);
    stream << indent;
  }

  if (node->getTranslation()) {
    char * text = node->getTranslation();
    while (*text != 0) {
      if (splitcells && ((*text == '"') || (*text == '\\'))) {
	  stream << "\\";
      }
      stream << *text;
      text++;
    }
  } else {
    stream << t;
  }


  if (newLine && (cm=findComment(newLine,EOL)))
    strcat(commentBuffer,cm->getText());

  return stream;
}

AST::AST() : pToken(0) { 
  expr_trans=0;
  optype=OP_INFIX;
  ni=empty_ni;
}

AST::~AST() { 
  pToken=0; 
  ni=empty_ni;
}

AST::AST(ANTLRTokenPtr newToken) : pToken(newToken) { 

  expr_trans=0;
  optype=OP_INFIX;
  ni=empty_ni;
}


AST::AST(ANTLRTokenType tokentype) { 

  ANTLRToken *token=new ANTLRToken(tokentype);

  expr_trans=0;
  optype=OP_INFIX;
  pToken=ANTLRTokenPtr(token);
  ni=empty_ni;
}

AST::AST(ANTLRTokenType tokentype,char *trans) { 
   ANTLRToken *token=new ANTLRToken(tokentype,trans);
   expr_trans=trans;
   optype=OP_INFIX;
   pToken=ANTLRTokenPtr(token);
   ni=empty_ni;
}

AST::AST(ANTLRTokenType tokentype,char *trans,opType t) { 

  ANTLRToken *token=new ANTLRToken(tokentype,trans);

  expr_trans=trans;
  optype=t;
  pToken=ANTLRTokenPtr(token);
  ni=empty_ni;
}

AST::AST(ANTLRTokenType tokentype,char *trans,opType t,char bal) { 

  ANTLRToken *token=new ANTLRToken(tokentype,trans);

  expr_trans=trans;
  optype=t;
  opbalancer=bal;
  pToken=ANTLRTokenPtr(token);
  ni=empty_ni;
}

void AST::preorder_action() {

  ANTLRChar *p=0;
  ANTLRToken *sven;
  int line;

  if (pToken== (ANTLRTokenPtr) NULL) {
    printf("<no token>");
  } else {
    sven=mytoken(pToken);
    p=sven->getText();
    line=sven->getLine();
    printf("%s ",p? p : "<no token name>");

  }
}

void AST::dumpTree() {

  AST *tree = this;
  char *downtext,*righttext;

  while ( tree!= NULL ) {
    downtext=tree->ASTdown()?mytoken((tree->ASTdown())->pToken)->getText():"NULL"; 
    righttext=tree->ASTright()?mytoken((tree->ASTright())->pToken)->getText():"NULL"; 

    //    cout << "At node: " << mytoken(tree->pToken) << " (nodetype: " << tree->ni.type << ", optype: " << tree->optype << " at " <<  ")\n";
    cout << "Down  -> " << (downtext? downtext : "NoName") << "\n";
    cout << "Right -> " << (righttext? righttext : "NoName") << "\n";

    if ( tree->ASTdown()!=NULL ) {
      tree->ASTdown()->dumpTree();
    }
    tree = tree->ASTright();
  }
}

void AST::setOpType(opType t) {

  optype=t;
}

void AST::setOpType(opType t,char b) {

  optype=t;
  opbalancer=b;
}

opType AST::getOpType() {

  return optype;
}

char AST::getBalancer() {

  return opbalancer;
}





