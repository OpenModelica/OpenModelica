#ifndef _MODPARSETOKEN_H_

#define _MODPARSETOKEN_H_

#include <iostream.h>
#include "tokens.h"
#include "AToken.h"

class ModParseToken : public ANTLRRefCountToken {

protected:
  ANTLRTokenType _type;

public:
  int _line;
  int serial;
  static int counter;

  ModParseToken(ANTLRTokenType t, ANTLRChar *text, int line);
  ModParseToken(ANTLRTokenType t);
  ModParseToken(ANTLRTokenType t, ANTLRChar *text);
  ModParseToken();
  virtual ~ModParseToken();
  ModParseToken(const ModParseToken &);
  ModParseToken & operator = (const ModParseToken &);
  ANTLRTokenType getType() { return _type; }
  void setType(ANTLRTokenType t) { _type=t; }
  virtual int getLine() { return _line; }
  void setLine(int line) { _line=line; }
  virtual ANTLRChar *getText() { return pText; }
  virtual ANTLRAbstractToken *makeToken(ANTLRTokenType t, ANTLRChar *text, int line);
  virtual void setText(ANTLRChar *s);
  ANTLRChar *pText;
  int col;
  void convertFloat();
};

ostream &operator<<(ostream &,ModParseToken *);

#endif
