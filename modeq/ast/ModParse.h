/*
 * ModParse: P a r s e r  H e a d e r 
 *
 * Generated from: modgram.g
 *
 * Terence Parr, Russell Quong, Will Cohen, and Hank Dietz: 1989-1995
 * Parr Research Corporation
 * with Purdue University Electrical Engineering
 * with AHPCRC, University of Minnesota
 * ANTLR Version 1.33
 */

#ifndef ModParse_h
#define ModParse_h
class ASTBase;
#include "AParser.h"



#include "parser.h"
// #include "comments.h"
#include "modAST.h"

#ifndef __GNUG__
#include "bool.h"
#endif

#ifdef _WIN32
extern "C" {
	int getopt(int nargc, char **nargv, char *ostr);
	extern int optind;
	extern char *optarg;
	char *__progname;
}
#endif


extern Comment *newComment;

  
class ModParse : public ANTLRParser {
protected:
	static ANTLRChar *_token_tbl[];
private:
	static SetWordType err1[12];
	static SetWordType err2[12];
	static SetWordType err3[12];
	static SetWordType setwd1[82];
	static SetWordType err4[12];
	static SetWordType setwd2[82];
	static SetWordType setwd3[82];
	static SetWordType err5[12];
	static SetWordType err6[12];
	static SetWordType setwd4[82];
	static SetWordType err7[12];
	static SetWordType err8[12];
	static SetWordType setwd5[82];
	static SetWordType setwd6[82];
	static SetWordType ASSIGN_set[12];
	static SetWordType err10[12];
	static SetWordType err11[12];
	static SetWordType setwd7[82];
	static SetWordType err12[12];
	static SetWordType err13[12];
	static SetWordType REL_OP_set[12];
	static SetWordType setwd8[82];
	static SetWordType ADD_OP_set[12];
	static SetWordType err16[12];
	static SetWordType MUL_OP_set[12];
	static SetWordType err18[12];
	static SetWordType err19[12];
	static SetWordType setwd9[82];
	static SetWordType err20[12];
	static SetWordType setwd10[82];
	static SetWordType setwd11[82];
private:
	void zzdflthandlers( int _signal, int *_retsignal );

public:
	ModParse(ANTLRTokenBuffer *input);
	void model_specification(ASTBase **_root);
	void import_statement(ASTBase **_root);
	void class_definition(ASTBase **_root, bool is_virtual,bool is_final );
	void composition(ASTBase **_root);
	void default_public(ASTBase **_root);
	void public_elements(ASTBase **_root);
	void protected_elements(ASTBase **_root);
	void element_list(ASTBase **_root, bool is_protected );
	void element(ASTBase **_root);
	void extends_clause(ASTBase **_root);
	void component_clause(ASTBase **_root, NodeType nt );
	void type_prefix(ASTBase **_root);
	void type_specifier(ASTBase **_root);
	void component_list(ASTBase **_root, NodeType nt );
	void component_declaration(ASTBase **_root, NodeType nt );
	void declaration(ASTBase **_root, NodeType nt );
	void array_decl(ASTBase **_root);
	void subscript_list(ASTBase **_root);
	void subscript(ASTBase **_root);
	void specialization(ASTBase **_root, char *tr );
	void class_specialization(ASTBase **_root);
	void argument_list(ASTBase **_root);
	void argument(ASTBase **_root);
	void element_modification(ASTBase **_root);
	void element_redeclaration(ASTBase **_root);
	void component_clause1(ASTBase **_root, NodeType nt );
	void equation_clause(ASTBase **_root);
	void algorithm_clause(ASTBase **_root);
	void equation(ASTBase **_root);
	void conditional_equation(ASTBase **_root);
	void for_clause(ASTBase **_root);
	void while_clause(ASTBase **_root);
	void equation_list(ASTBase **_root);
	void expression(ASTBase **_root);
	void simple_expression(ASTBase **_root);
	void logical_term(ASTBase **_root);
	void logical_factor(ASTBase **_root);
	void relation(ASTBase **_root);
	void arithmetic_expression(ASTBase **_root);
	void unary_arithmetic_expression(ASTBase **_root);
	void term(ASTBase **_root);
	void factor(ASTBase **_root);
	void primary(ASTBase **_root);
	void name_path_function_arguments(ASTBase **_root);
	void name_path(ASTBase **_root);
	void new_component_reference(ASTBase **_root);
	void member_list(ASTBase **_root);
	void comp_ref(ASTBase **_root);
	void array_op(ASTBase **_root);
	void component_reference(ASTBase **_root);
	 bool   column_expression(ASTBase **_root);
	void row_expression(ASTBase **_root);
	void function_arguments(ASTBase **_root);
	void comment(ASTBase **_root);
	void annotation(ASTBase **_root);
};

#endif /* ModParse_h */
