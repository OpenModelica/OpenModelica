/* lexer.h */

extern int yylineno;
extern void lexerror(const char *fmt, ...);
extern const char *lex_token_to_string(int token);
#ifdef LEXDEBUG
extern int lexdebug;
#endif
extern int yylex(void);
