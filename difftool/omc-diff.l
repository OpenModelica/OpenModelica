/* 123 -123 123.456 123.45e23 123.45e-23 10e5 */
%{
#define T_EOF 0
#define T_TEXT 1
#define T_REAL 2
#define T_NEWLINE 3
char* yylval;

%}

digit           [0-9]
letter          [^0-9\-\n\r]


%%

"\r\n"|"\n\r"|"\n"|"\r" return T_NEWLINE;
"-"?{digit}+("."({digit}+))?(("e"|"E")("-"|"+")?{digit}+)?  return T_REAL;
"-"?{letter}+    return T_TEXT;

%%

#include <string.h>
#include <math.h>

int yywrap (void ) {
  return 1;
}

#define VERSION_STRING "-v1.4"

int usage(char* exe, char* s1,char* s2) {
  printf("Error: %s%s.\n", s1, s2);
  printf("Usage (Normal): %s epsilon $file_expected $file_actual\n",exe);
  printf("  Compares two files. Floating point numbers are parsed.\n");
  printf("  A maximum error of 0.0 < epsilon < 1.0 is tolerated when comparing.\n");
  printf("Usage (Version test): %s %s\n", exe, VERSION_STRING);
  printf("  Returns exit code 0.\n");
  return 2;
}

static inline const char* consume_whitespace(const char *str)
{
  while ((*str == ' ') || (*str == '\t')) str++;
  return str;
}

int strcmp_omc_diff(const char* s1, const char* s2) {
  s1 = consume_whitespace(s1);
  s2 = consume_whitespace(s2);
  while (*s1 && *s2) {
    if ((*s1 == ' ' || *s1 == '\t') && (*s2 == ' ' || *s2 == '\t')) {
      s1 = consume_whitespace(s1);
      s2 = consume_whitespace(s2);
    }
    if (*s1 && *s2) {
      if (*s1 != *s2) {
        printf("Failed '%c' '%c'\n", *s1, *s2);
        return *s1 > *s2 ? 1 : -1;
      }
      s1++;
      s2++;
    }
  }
  s1 = consume_whitespace(s1);
  s2 = consume_whitespace(s2);
  return *s1 == *s2 ? 0 : *s1 > *s2 ? 1 : -1;
}

int lex_main(double eps, FILE* f1, FILE* f2) {
  YY_BUFFER_STATE y1 = yy_create_buffer(f1,YY_BUF_SIZE);
  YY_BUFFER_STATE y2 = yy_create_buffer(f2,YY_BUF_SIZE);
  int v1,v2;
  char *s1,*s2;
  int line = 1;

  while (1) {
    yy_switch_to_buffer(y1);
    v1 = yylex();
    s1 = strdup(yytext);

    yy_switch_to_buffer(y2);
    v2 = yylex();
    s2 = yytext;

    if (T_EOF == v1 && T_EOF == v2)
      return 0;
    if (T_EOF == v1) {
      printf("Line %d: Actual file has more input than expected.\n", line);
      return 1;
    }
    if (T_EOF == v2) {
      printf("Line %d: Expected file has more input than actual.\n", line);
      return 1;
    }

    if (v1 != v2) {
      printf("Line %d: Lexical token differs:\nexpected: %s\ngot:      %s\n", line, s1, s2);
      return 1;
    }

    switch (v1) {
    case T_NEWLINE:
      line++;
      break;
    case T_TEXT:
      if (strcmp_omc_diff(s1,s2)) {
        printf("Line %d: Text differs:\nexpected: %s\ngot:      %s\n", line, s1, s2);
        return 1;
      }
      break;
    case T_REAL: {
      char *end1, *end2;
      long l1 = strtol(s1, &end1, 10);
      long l2 = strtol(s2, &end2, 10);

      if(*end1 == '\0' && *end2 == '\0') {
        if (l1 != l2) {
          printf("Line %d: Integer %s != %s\n", line, s1, s2);
          return 1;
        }
      }
      else {
        double d1 = strtod(s1,NULL);
        double d2 = strtod(s2,NULL);
        // We should check also for a relative error
        // otherwise some tests need to many adjustments
        double err = fabs(d2-d1);
        if (err > eps*fabs(d2)+eps) {
          printf("Line %d: Real %s != %s\n  eps: %f, actual diff: %f\n",
                 line, s1, s2, eps, fabs(d2-d1));
          return 1;
        }
      }
      break;
      };
    }
    free(s1);
  }
}

int main(int argc, char** argv) {
  int retval;
  int line = 1;
  FILE *f1, *f2;
  char* endptr;
  double eps;
  if (argc == 2 && 0 == strcmp(argv[1], VERSION_STRING))
    exit(0);
  if (argc != 4)
    exit(usage(argv[0],"Wrong number of arguments",""));
  eps = strtod(argv[1],&endptr);
  if (endptr == argv[1] || endptr[0] != '\0' || eps < 0.0 || eps > 1.0)
    exit(usage(argv[0],"Failed to convert epsilon ",argv[1]));
  f1 = fopen(argv[2],"r");
  if (f1 == NULL)
    exit(usage(argv[0],"Failed to open file ",argv[2]));
  f2 = fopen(argv[3],"r");
  if (f2 == NULL)
    exit(usage(argv[0],"Failed to open file ",argv[3]));

  return lex_main(eps,f1,f2);
}
