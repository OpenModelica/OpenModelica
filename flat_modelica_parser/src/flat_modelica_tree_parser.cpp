/* $ANTLR 2.7.1: "walker.g" -> "flat_modelica_tree_parser.cpp"$ */
#include "flat_modelica_tree_parser.hpp"
#include "antlr/Token.hpp"
#include "antlr/AST.hpp"
#include "antlr/NoViableAltException.hpp"
#include "antlr/MismatchedTokenException.hpp"
#include "antlr/SemanticException.hpp"
#include "antlr/BitSet.hpp"
#line 1 "walker.g"

#line 12 "flat_modelica_tree_parser.cpp"
flat_modelica_tree_parser::flat_modelica_tree_parser()
	: ANTLR_USE_NAMESPACE(antlr)TreeParser() {
	setTokenNames(_tokenNames);
}

void * flat_modelica_tree_parser::stored_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 61 "walker.g"
	void *ast;
#line 21 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST stored_definition_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 61 "walker.g"
	
	void *within = 0;
	void *class_def = 0;    
	//    l_stack el_stack;
	
	
#line 35 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t2 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp1_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp1_AST = astFactory.create(_t);
	tmp1_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp1_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST2 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,STORED_DEFINITION);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case WITHIN:
	{
		within=within_clause(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case FINAL:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==FINAL||_t->getType()==CLASS_DEFINITION)) {
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case FINAL:
			{
				f = _t;
				f_AST = astFactory.create(f);
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
				match(_t,FINAL);
				_t = _t->getNextSibling();
				break;
			}
			case CLASS_DEFINITION:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			class_def=class_definition(_t,f != NULL);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 73 "walker.g"
			
			if (class_def)
			{   
			//el_stack.push(class_def);
			}
			
#line 109 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop6;
		}
		
	}
	_loop6:;
	}
	currentAST = __currentAST2;
	_t = __t2;
	_t = _t->getNextSibling();
#line 81 "walker.g"
	
				//        if (within == 0) { within=Absyn__TOP; }
				//        ast = Absyn__PROGRAM(make_rml_list_from_stack(el_stack),within);
	
#line 126 "flat_modelica_tree_parser.cpp"
	stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = stored_definition_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::within_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 87 "walker.g"
	void *ast;
#line 136 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST within_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST within_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 87 "walker.g"
	
	void * name= 0;
	
#line 145 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t8 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp2_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp2_AST = astFactory.create(_t);
	tmp2_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp2_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST8 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WITHIN);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	{
		name=name_path(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST8;
	_t = __t8;
	_t = _t->getNextSibling();
#line 92 "walker.g"
	
	//ast = Absyn__WITHIN(name);
	
#line 187 "flat_modelica_tree_parser.cpp"
	within_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = within_clause_AST;
	_retTree = _t;
	return ast;
}

 void*  flat_modelica_tree_parser::class_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	bool final
) {
#line 97 "walker.g"
	 void* ast ;
#line 199 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST class_definition_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 97 "walker.g"
	
	void* restr = 0;
	void* class_spec = 0;
	
#line 215 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t11 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp3_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp3_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp3_AST = astFactory.create(_t);
	tmp3_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp3_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST11 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,CLASS_DEFINITION);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ENCAPSULATED:
	{
		e = _t;
		e_AST = astFactory.create(e);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		match(_t,ENCAPSULATED);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case PARTIAL:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case PARTIAL:
	{
		p = _t;
		p_AST = astFactory.create(p);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		match(_t,PARTIAL);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	restr=class_restriction(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	i = _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	class_spec=class_specifier(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST11;
	_t = __t11;
	_t = _t->getNextSibling();
#line 110 "walker.g"
	
	//             ast = Absyn__CLASS(
	//                 to_rml_str(i),
	//                 RML_PRIM_MKBOOL(p != 0),
	// 				RML_PRIM_MKBOOL(final),
	// 				RML_PRIM_MKBOOL(e != 0), 
	//                 restr,
	//                 class_spec
	//            );                
	
#line 314 "flat_modelica_tree_parser.cpp"
	class_definition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_definition_AST;
	_retTree = _t;
	return ast ;
}

void*  flat_modelica_tree_parser::name_path(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1459 "walker.g"
	void* ast;
#line 324 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1459 "walker.g"
	
		// void* str;
	
	
#line 340 "flat_modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		i = _t;
		i_AST = astFactory.create(i);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(_t,IDENT);
		_t = _t->getNextSibling();
#line 1466 "walker.g"
		
		variable_type = i->getText();
				// 	str = to_rml_str(i);
		// 			ast = Absyn__IDENT(str);
				
#line 358 "flat_modelica_tree_parser.cpp"
		name_path_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t280 = _t;
		d = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		d_AST = astFactory.create(d);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(d_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST280 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DOT);
		_t = _t->getFirstChild();
		i2 = _t;
		i2_AST = astFactory.create(i2);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
		match(_t,IDENT);
		_t = _t->getNextSibling();
		ast=name_path(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST280;
		_t = __t280;
		_t = _t->getNextSibling();
#line 1472 "walker.g"
		
		// 			str = to_rml_str(i2);
		// 			ast = Absyn__QUALIFIED(str, ast);
				
#line 389 "flat_modelica_tree_parser.cpp"
		name_path_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = name_path_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::class_restriction(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 122 "walker.g"
	void* ast;
#line 406 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST class_restriction_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_restriction_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp4_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp4_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp4_AST = astFactory.create(_t);
		tmp4_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp4_AST));
		match(_t,CLASS);
		_t = _t->getNextSibling();
#line 124 "walker.g"
		/*ast = Absyn__R_5fCLASS;*/
#line 427 "flat_modelica_tree_parser.cpp"
		break;
	}
	case MODEL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp5_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp5_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp5_AST = astFactory.create(_t);
		tmp5_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp5_AST));
		match(_t,MODEL);
		_t = _t->getNextSibling();
#line 125 "walker.g"
		/*ast = Absyn__R_5fMODEL;*/
#line 441 "flat_modelica_tree_parser.cpp"
		break;
	}
	case RECORD:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp6_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp6_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp6_AST = astFactory.create(_t);
		tmp6_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp6_AST));
		match(_t,RECORD);
		_t = _t->getNextSibling();
#line 126 "walker.g"
		/*ast = Absyn__R_5fRECORD;*/
#line 455 "flat_modelica_tree_parser.cpp"
		break;
	}
	case BLOCK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp7_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp7_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp7_AST = astFactory.create(_t);
		tmp7_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp7_AST));
		match(_t,BLOCK);
		_t = _t->getNextSibling();
#line 127 "walker.g"
		/*ast = Absyn__R_5fBLOCK;*/
#line 469 "flat_modelica_tree_parser.cpp"
		break;
	}
	case CONNECTOR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp8_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp8_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp8_AST = astFactory.create(_t);
		tmp8_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp8_AST));
		match(_t,CONNECTOR);
		_t = _t->getNextSibling();
#line 128 "walker.g"
		/*ast = Absyn__R_5fCONNECTOR;*/
#line 483 "flat_modelica_tree_parser.cpp"
		break;
	}
	case TYPE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp9_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp9_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp9_AST = astFactory.create(_t);
		tmp9_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
		match(_t,TYPE);
		_t = _t->getNextSibling();
#line 129 "walker.g"
		/*ast = Absyn__R_5fTYPE; */
#line 497 "flat_modelica_tree_parser.cpp"
		break;
	}
	case PACKAGE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp10_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp10_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp10_AST = astFactory.create(_t);
		tmp10_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
		match(_t,PACKAGE);
		_t = _t->getNextSibling();
#line 130 "walker.g"
		/*ast = Absyn__R_5fPACKAGE;*/
#line 511 "flat_modelica_tree_parser.cpp"
		break;
	}
	case FUNCTION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp11_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp11_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp11_AST = astFactory.create(_t);
		tmp11_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp11_AST));
		match(_t,FUNCTION);
		_t = _t->getNextSibling();
#line 131 "walker.g"
		/*ast = Absyn__R_5fFUNCTION;*/
#line 525 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	class_restriction_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_restriction_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::class_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 135 "walker.g"
	void* ast;
#line 543 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST class_specifier_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 135 "walker.g"
	
		void *comp = 0;
		void *cmt = 0;
	
#line 553 "flat_modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case 3:
	case ALGORITHM:
	case ANNOTATION:
	case EQUATION:
	case EXTENDS:
	case EXTERNAL:
	case IMPORT:
	case PROTECTED:
	case PUBLIC:
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	case STRING_COMMENT:
	{
		{
		{
		cmt=string_comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		comp=composition(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 143 "walker.g"
		
						//ast = Absyn__PARTS(comp,cmt ? mk_some(cmt) : mk_none());
					
#line 586 "flat_modelica_tree_parser.cpp"
		}
		class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case EQUALS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t19 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp12_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp12_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp12_AST = astFactory.create(_t);
		tmp12_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp12_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST19 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUALS);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			ast=derived_class(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case ENUMERATION:
		{
			ast=enumeration(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST19;
		_t = __t19;
		_t = _t->getNextSibling();
		class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = class_specifier_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::string_comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1637 "walker.g"
	void *ast;
#line 654 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST string_comment_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST string_comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING_COMMENT:
	{
#line 1638 "walker.g"
		
					void *cmt=0;
			  ast = 0;	   
			
#line 670 "flat_modelica_tree_parser.cpp"
		ANTLR_USE_NAMESPACE(antlr)RefAST __t319 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp13_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp13_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp13_AST = astFactory.create(_t);
		tmp13_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp13_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST319 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,STRING_COMMENT);
		_t = _t->getFirstChild();
		cmt=string_concatenation(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST319;
		_t = __t319;
		_t = _t->getNextSibling();
#line 1643 "walker.g"
		
					ast = cmt;
				
#line 692 "flat_modelica_tree_parser.cpp"
		string_comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case 3:
	case ALGORITHM:
	case ANNOTATION:
	case EQUATION:
	case EXTENDS:
	case EXTERNAL:
	case IMPORT:
	case PROTECTED:
	case PUBLIC:
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	{
#line 1647 "walker.g"
		
					ast = 0;
				
#line 714 "flat_modelica_tree_parser.cpp"
		string_comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = string_comment_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::composition(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 214 "walker.g"
	void* ast;
#line 731 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST composition_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST composition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 214 "walker.g"
	
	void* el = 0;
	//    l_stack el_stack;
	void * ann;	
	
#line 742 "flat_modelica_tree_parser.cpp"
	
	el=element_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 222 "walker.g"
	
	//  el_stack.push(Absyn__PUBLIC(el));
	
#line 751 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_0.member(_t->getType()))) {
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case PUBLIC:
			{
				el=public_element_list(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case PROTECTED:
			{
				el=protected_element_list(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case EQUATION:
			case INITIAL_EQUATION:
			{
				el=equation_clause(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case ALGORITHM:
			case INITIAL_ALGORITHM:
			{
				el=algorithm_clause(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
#line 232 "walker.g"
			
			//    el_stack.push(el);
			
#line 801 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop37;
		}
		
	}
	_loop37:;
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t39 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp14_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp14_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp14_AST = astFactory.create(_t);
		tmp14_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST39 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EXTERNAL);
		_t = _t->getFirstChild();
		{
		el=external_function_call(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case ANNOTATION:
		{
			ann=annotation(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 239 "walker.g"
		
						//	el_stack.push(el); 
							
						
#line 858 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST39;
		_t = __t39;
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 245 "walker.g"
	
	//            ast = make_rml_list_from_stack(el_stack);
	
#line 878 "flat_modelica_tree_parser.cpp"
	composition_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = composition_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::derived_class(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 151 "walker.g"
	void *ast;
#line 888 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST derived_class_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST derived_class_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 151 "walker.g"
	
		void *p = 0;
		void *as = 0;
		void *cmod = 0;
		void *cmt = 0;
	//	void *attr = 0;
		type_prefix_t pfx;
	
#line 902 "flat_modelica_tree_parser.cpp"
	
	{
	type_prefix(_t,pfx);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	p=name_path(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		as=array_subscripts(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case CLASS_MODIFICATION:
	case COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		cmod=class_modification(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 166 "walker.g"
	
	
	// 				if (as) { as = mk_some(as); }
	// 				else { as = mk_none(); }
	// 				if (!cmod) { cmod = mk_nil(); }
	// 				attr = Absyn__ATTR(
	// 				pfx.flow,
	// 				pfx.variability,
	// 				pfx.direction,
	//  				mk_nil());
	
	// 				ast = Absyn__DERIVED(p, as, attr, cmod, cmt? mk_some(cmt) : mk_none());
				
#line 991 "flat_modelica_tree_parser.cpp"
	}
	derived_class_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = derived_class_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::enumeration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 182 "walker.g"
	void* ast;
#line 1002 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 182 "walker.g"
	
	//	l_stack el_stack;
		void *el = 0;
		void *cmt = 0;
	
#line 1013 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t27 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp15_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp15_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp15_AST = astFactory.create(_t);
	tmp15_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp15_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST27 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ENUMERATION);
	_t = _t->getFirstChild();
	el=enumeration_literal(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 191 "walker.g"
	/*el_stack.push(el); */
#line 1031 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ENUMERATION_LITERAL)) {
			el=enumeration_literal(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 194 "walker.g"
			/*el_stack.push(el); */
#line 1042 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop29;
		}
		
	}
	_loop29:;
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST27;
	_t = __t27;
	_t = _t->getNextSibling();
#line 199 "walker.g"
	
		//		ast = Absyn__ENUMERATION(make_rml_list_from_stack(el_stack),
			//		cmt ? mk_some(cmt) : mk_none());
			
#line 1080 "flat_modelica_tree_parser.cpp"
	enumeration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = enumeration_AST;
	_retTree = _t;
	return ast;
}

void flat_modelica_tree_parser::type_prefix(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	type_prefix_t &prefix
) {
	ANTLR_USE_NAMESPACE(antlr)RefAST type_prefix_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_prefix_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FLOW:
	{
		f = _t;
		f_AST = astFactory.create(f);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(_t,FLOW);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DISCRETE:
	{
		d = _t;
		d_AST = astFactory.create(d);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(d_AST));
		match(_t,DISCRETE);
		_t = _t->getNextSibling();
		break;
	}
	case PARAMETER:
	{
		p = _t;
		p_AST = astFactory.create(p);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		match(_t,PARAMETER);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	{
		c = _t;
		c_AST = astFactory.create(c);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
		match(_t,CONSTANT);
		_t = _t->getNextSibling();
		break;
	}
	case INPUT:
	case OUTPUT:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case INPUT:
	{
		i = _t;
		i_AST = astFactory.create(i);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(_t,INPUT);
		_t = _t->getNextSibling();
		break;
	}
	case OUTPUT:
	{
		o = _t;
		o_AST = astFactory.create(o);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(o_AST));
		match(_t,OUTPUT);
		_t = _t->getNextSibling();
		break;
	}
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 536 "walker.g"
	
	
	
	if (f != NULL) { prefix.flow = 1; }
	else { prefix.flow = 0; }
	
	if (d != NULL) { prefix.variability = 0; }
	else if (p != NULL) { prefix.variability = 1; }
	else if (c != NULL) { prefix.variability = 2; }
	else { prefix.variability = 3; }
	
	if (i != NULL) { prefix.direction = 0; }
	else if (o != NULL) { prefix.direction = 1; }
	else { prefix.direction = 2; }
	
	
	
	// 			if (f != NULL) { prefix.flow = RML_PRIM_MKBOOL(1); }
	// 			else { prefix.flow = RML_PRIM_MKBOOL(0); }
	
	// 			if (d != NULL) { prefix.variability = Absyn__DISCRETE; }
	// 			else if (p != NULL) { prefix.variability = Absyn__PARAM; }
	// 			else if (c != NULL) { prefix.variability = Absyn__CONST; }
	// 			else { prefix.variability = Absyn__VAR; }
	
	// 			if (i != NULL) { prefix.direction = Absyn__INPUT; }
	// 			else if (o != NULL) { prefix.direction = Absyn__OUTPUT; }
	// 			else { prefix.direction = Absyn__BIDIR; }
			
#line 1243 "flat_modelica_tree_parser.cpp"
	type_prefix_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = type_prefix_AST;
	_retTree = _t;
}

void*  flat_modelica_tree_parser::array_subscripts(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1585 "walker.g"
	void* ast;
#line 1252 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST array_subscripts_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST array_subscripts_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1585 "walker.g"
	
	//	l_stack el_stack;
		void* s = 0;
	
#line 1262 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t310 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp16_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp16_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp16_AST = astFactory.create(_t);
	tmp16_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp16_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST310 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,LBRACK);
	_t = _t->getFirstChild();
	s=subscript(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1592 "walker.g"
	
		//			el_stack.push(s);
				
#line 1282 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_1.member(_t->getType()))) {
			s=subscript(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1596 "walker.g"
			
						//		el_stack.push(s);
							
#line 1295 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop312;
		}
		
	}
	_loop312:;
	}
	currentAST = __currentAST310;
	_t = __t310;
	_t = _t->getNextSibling();
#line 1600 "walker.g"
	
				//ast = make_rml_list_from_stack(el_stack);
			
#line 1311 "flat_modelica_tree_parser.cpp"
	array_subscripts_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = array_subscripts_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::class_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 647 "walker.g"
	void* ast;
#line 1321 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST class_modification_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 647 "walker.g"
	
		ast = 0;
	
#line 1330 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t114 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp17_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp17_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp17_AST = astFactory.create(_t);
	tmp17_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp17_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST114 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,CLASS_MODIFICATION);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ARGUMENT_LIST:
	{
		ast=argument_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST114;
	_t = __t114;
	_t = _t->getNextSibling();
#line 653 "walker.g"
	
	//			if (!ast) ast = mk_nil();
			
#line 1371 "flat_modelica_tree_parser.cpp"
	class_modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = class_modification_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1622 "walker.g"
	void* ast;
#line 1381 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST comment_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1622 "walker.g"
	
		void* ann=0;
		void* cmt=0;
	ast = 0;
	
#line 1392 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t316 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp18_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp18_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp18_AST = astFactory.create(_t);
	tmp18_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp18_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST316 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,COMMENT);
	_t = _t->getFirstChild();
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ANNOTATION:
	{
		ann=annotation(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST316;
	_t = __t316;
	_t = _t->getNextSibling();
#line 1629 "walker.g"
	
		  		//if (ann || cmt) {
				//	ast = Absyn__COMMENT(ann ? mk_some(ann) : mk_none(), 
			  	//						 cmt ? mk_some(cmt) : mk_none());
		  		//}
			
#line 1439 "flat_modelica_tree_parser.cpp"
	comment_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = comment_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::enumeration_literal(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 205 "walker.g"
	void *ast;
#line 1449 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_literal_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i1 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
#line 206 "walker.g"
	
	void *c1=0;
	
#line 1461 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST __t32 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp19_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp19_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp19_AST = astFactory.create(_t);
	tmp19_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp19_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST32 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ENUMERATION_LITERAL);
	_t = _t->getFirstChild();
	i1 = _t;
	i1_AST = astFactory.create(i1);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i1_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		c1=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST32;
	_t = __t32;
	_t = _t->getNextSibling();
#line 210 "walker.g"
	
			//	ast = Absyn__ENUMLITERAL(to_rml_str(i1),c1 ? mk_some(c1) : mk_none());
			
#line 1506 "flat_modelica_tree_parser.cpp"
	enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = enumeration_literal_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 315 "walker.g"
	void* ast;
#line 1516 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 315 "walker.g"
	
	void* e = 0;
	//el_stack el_stack;
	void *ann = 0;
	
#line 1527 "flat_modelica_tree_parser.cpp"
	
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXTENDS:
		case IMPORT:
		case DECLARATION:
		case DEFINITION:
		{
			{
			e=element(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 324 "walker.g"
			
			//            el_stack.push(Absyn__ELEMENTITEM(e));
			
#line 1547 "flat_modelica_tree_parser.cpp"
			}
			break;
		}
		case ANNOTATION:
		{
			{
			ann=annotation(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 328 "walker.g"
			
			//          el_stack.push(Absyn__ANNOTATIONITEM(ann));
			
#line 1561 "flat_modelica_tree_parser.cpp"
			}
			break;
		}
		default:
		{
			goto _loop59;
		}
		}
	}
	_loop59:;
	}
#line 333 "walker.g"
	
	//ast = make_rml_list_from_stack(el_stack);
	
#line 1577 "flat_modelica_tree_parser.cpp"
	element_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::public_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 250 "walker.g"
	void* ast;
#line 1587 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST public_element_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST public_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 250 "walker.g"
	
	void* el;    
	
#line 1598 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t43 = _t;
	p = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	p_AST = astFactory.create(p);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST43 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,PUBLIC);
	_t = _t->getFirstChild();
	el=element_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST43;
	_t = __t43;
	_t = _t->getNextSibling();
#line 259 "walker.g"
	
	//          ast = Absyn__PUBLIC(el);
	
#line 1619 "flat_modelica_tree_parser.cpp"
	public_element_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = public_element_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::protected_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 264 "walker.g"
	void* ast;
#line 1629 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST protected_element_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST protected_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 264 "walker.g"
	
	void* el;
	
#line 1640 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t45 = _t;
	p = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	p_AST = astFactory.create(p);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST45 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,PROTECTED);
	_t = _t->getFirstChild();
	el=element_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST45;
	_t = __t45;
	_t = _t->getNextSibling();
#line 273 "walker.g"
	
	//        ast = Absyn__PROTECTED(el);
	
#line 1661 "flat_modelica_tree_parser.cpp"
	protected_element_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = protected_element_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::equation_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 781 "walker.g"
	void* ast;
#line 1671 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 781 "walker.g"
	
		//el_stack el_stack;
		void *e = 0;
		void *ann = 0;
	
#line 1682 "flat_modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t138 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp20_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp20_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp20_AST = astFactory.create(_t);
		tmp20_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp20_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST138 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUATION);
		_t = _t->getFirstChild();
		{
		{
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EQUATION_STATEMENT:
			{
				e=equation(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 791 "walker.g"
				/*el_stack.push(e);*/
#line 1713 "flat_modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 792 "walker.g"
				/*el_stack.push(Absyn__EQUATIONITEMANN(ann)); */
#line 1723 "flat_modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop141;
			}
			}
		}
		_loop141:;
		}
		}
		currentAST = __currentAST138;
		_t = __t138;
		_t = _t->getNextSibling();
#line 797 "walker.g"
		
		
		
		//			ast = Absyn__EQUATIONS(make_rml_list_from_stack(el_stack));
				
#line 1744 "flat_modelica_tree_parser.cpp"
		equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case INITIAL_EQUATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t142 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp21_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp21_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp21_AST = astFactory.create(_t);
		tmp21_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp21_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST142 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,INITIAL_EQUATION);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t143 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp22_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp22_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp22_AST = astFactory.create(_t);
		tmp22_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp22_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST143 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUATION);
		_t = _t->getFirstChild();
		{
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EQUATION_STATEMENT:
			{
				e=equation(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 806 "walker.g"
				/*el_stack.push(e);*/
#line 1784 "flat_modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 807 "walker.g"
				/*el_stack.push(Absyn__EQUATIONITEMANN(ann)); */
#line 1794 "flat_modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop145;
			}
			}
		}
		_loop145:;
		}
		currentAST = __currentAST143;
		_t = __t143;
		_t = _t->getNextSibling();
#line 810 "walker.g"
		
		//				ast = Absyn__INITIALEQUATIONS(make_rml_list_from_stack(el_stack));
					
#line 1812 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST142;
		_t = __t142;
		_t = _t->getNextSibling();
		equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = equation_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::algorithm_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 816 "walker.g"
	void* ast;
#line 1832 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 816 "walker.g"
	
		//el_stack el_stack;
		void* e;
		void* ann;
	
#line 1843 "flat_modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ALGORITHM:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t147 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp23_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp23_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp23_AST = astFactory.create(_t);
		tmp23_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp23_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST147 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ALGORITHM);
		_t = _t->getFirstChild();
		{
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case ALGORITHM_STATEMENT:
			{
				e=algorithm(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 824 "walker.g"
				/*el_stack.push(e); */
#line 1873 "flat_modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 825 "walker.g"
				/*el_stack.push(Absyn__ALGORITHMITEMANN(ann));*/
#line 1883 "flat_modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop149;
			}
			}
		}
		_loop149:;
		}
		currentAST = __currentAST147;
		_t = __t147;
		_t = _t->getNextSibling();
#line 828 "walker.g"
		
		//			ast = Absyn__ALGORITHMS(make_rml_list_from_stack(el_stack));
				
#line 1901 "flat_modelica_tree_parser.cpp"
		algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case INITIAL_ALGORITHM:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t150 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp24_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp24_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp24_AST = astFactory.create(_t);
		tmp24_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp24_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST150 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,INITIAL_ALGORITHM);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t151 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp25_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp25_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp25_AST = astFactory.create(_t);
		tmp25_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp25_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST151 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ALGORITHM);
		_t = _t->getFirstChild();
		{
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case ALGORITHM_STATEMENT:
			{
				e=algorithm(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 834 "walker.g"
				/*el_stack.push(e); */
#line 1941 "flat_modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 835 "walker.g"
				/*el_stack.push(Absyn__ALGORITHMITEMANN(ann)); */
#line 1951 "flat_modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop153;
			}
			}
		}
		_loop153:;
		}
		currentAST = __currentAST151;
		_t = __t151;
		_t = _t->getNextSibling();
#line 838 "walker.g"
		
		//				ast = Absyn__INITIALALGORITHMS(make_rml_list_from_stack(el_stack));
					
#line 1969 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST150;
		_t = __t150;
		_t = _t->getNextSibling();
		algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = algorithm_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::external_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 278 "walker.g"
	void* ast;
#line 1989 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST external_function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 278 "walker.g"
	
		void* temp=0;
		void* temp2=0;
		void* temp3=0;
	//	void *lang;
		ast = 0;
	
#line 2010 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING:
	{
		s = _t;
		s_AST = astFactory.create(s);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s_AST));
		match(_t,STRING);
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ANNOTATION:
	case EXTERNAL_FUNCTION_CALL:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL_FUNCTION_CALL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t49 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp26_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp26_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp26_AST = astFactory.create(_t);
		tmp26_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp26_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST49 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EXTERNAL_FUNCTION_CALL);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case IDENT:
		{
			{
			i = _t;
			i_AST = astFactory.create(i);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
			match(_t,IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXPRESSION_LIST:
			{
				temp=expression_list(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			}
#line 291 "walker.g"
			
					// 				if (s != NULL) { lang = mk_some(to_rml_str(s)); } 
			// 						else { lang = mk_none(); }
			// 						if (!temp) { temp = mk_nil(); }
			// 						ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some(to_rml_str(i)),lang,mk_none(),temp));
								
#line 2095 "flat_modelica_tree_parser.cpp"
			break;
		}
		case EQUALS:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t53 = _t;
			e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
			e_AST = astFactory.create(e);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST53 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,EQUALS);
			_t = _t->getFirstChild();
			temp2=component_reference(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			i2 = _t;
			i2_AST = astFactory.create(i2);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
			match(_t,IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXPRESSION_LIST:
			{
				temp3=expression_list(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			currentAST = __currentAST53;
			_t = __t53;
			_t = _t->getNextSibling();
#line 298 "walker.g"
			
					// 				if (s != NULL) { lang = mk_some(to_rml_str(s)); } 
			// 						else { lang = mk_none(); }
			// 						if (!temp2) { temp2 = mk_nil(); }
			// 						ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some(to_rml_str(i2)),lang,mk_some(temp2),temp3));
								
#line 2148 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST49;
		_t = __t49;
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ANNOTATION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 306 "walker.g"
	
			// 	if (!ast) { 
	// 				if (s != NULL) { lang = mk_some(to_rml_str(s)); } 
	// 				else { lang = mk_none(); }
	// 				ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_none(),lang,mk_none(),mk_nil()));
			//	}
	
#line 2181 "flat_modelica_tree_parser.cpp"
	external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = external_function_call_AST;
	_retTree = _t;
	return ast;
}

 void * flat_modelica_tree_parser::annotation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1665 "walker.g"
	 void *ast;
#line 2191 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST annotation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST annotation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST a = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1665 "walker.g"
	
	void *cmod=0;
	
#line 2202 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t323 = _t;
	a = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	a_AST = astFactory.create(a);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(a_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST323 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ANNOTATION);
	_t = _t->getFirstChild();
	cmod=class_modification(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST323;
	_t = __t323;
	_t = _t->getNextSibling();
#line 1671 "walker.g"
	
	//ast = Absyn__ANNOTATION(cmod);
	
#line 2223 "flat_modelica_tree_parser.cpp"
	annotation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = annotation_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1546 "walker.g"
	void* ast;
#line 2233 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1546 "walker.g"
	
		//l_stack el_stack;
		void* e;
	
#line 2243 "flat_modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t301 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp27_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp27_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp27_AST = astFactory.create(_t);
	tmp27_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp27_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST301 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1553 "walker.g"
	/*el_stack.push(e); */
#line 2262 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1554 "walker.g"
			/*el_stack.push(e); */
#line 2273 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop303;
		}
		
	}
	_loop303:;
	}
	currentAST = __currentAST301;
	_t = __t301;
	_t = _t->getNextSibling();
	}
#line 1557 "walker.g"
	
			//	ast = make_rml_list_from_stack(el_stack);
			
#line 2290 "flat_modelica_tree_parser.cpp"
	expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = expression_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::component_reference(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1478 "walker.g"
	void* ast;
#line 2300 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1478 "walker.g"
	
		void* arr = 0;
	//	void* id = 0;
	
#line 2314 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t283 = _t;
		i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		i_AST = astFactory.create(i);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST283 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			arr=array_subscripts(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST283;
		_t = __t283;
		_t = _t->getNextSibling();
#line 1485 "walker.g"
		
		eq_stack.push(i->getText());
		// 				if (!arr) arr = mk_nil();
		// 				id = to_rml_str(i);
		// 				ast = Absyn__CREF_5fIDENT(
		// 					id,
		// 					arr);
		
					
#line 2365 "flat_modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t285 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp28_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp28_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp28_AST = astFactory.create(_t);
		tmp28_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp28_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST285 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DOT);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t286 = _t;
		i2 = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		i2_AST = astFactory.create(i2);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST286 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			arr=array_subscripts(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST286;
		_t = __t286;
		_t = _t->getNextSibling();
		ast=component_reference(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST285;
		_t = __t285;
		_t = _t->getNextSibling();
#line 1496 "walker.g"
		
				
#line 2423 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	component_reference_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_reference_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::element(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 340 "walker.g"
	void* ast;
#line 2441 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST fd = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST fd_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST id = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST id_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST od = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST od_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rd = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rd_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 340 "walker.g"
	
		void* class_def = 0;
		void* e_spec = 0;
	//	void* final = 0;
	//	void* innerouter = 0;
		void* constr = 0;
	
#line 2470 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IMPORT:
	{
		e_spec=import_clause(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 350 "walker.g"
		
						//ast = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,mk_scon("import"),e_spec,mk_none());
					
#line 2485 "flat_modelica_tree_parser.cpp"
		break;
	}
	case EXTENDS:
	{
		e_spec=extends_clause(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 354 "walker.g"
		
						//ast = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,mk_scon("extends"),e_spec,mk_none());
					
#line 2497 "flat_modelica_tree_parser.cpp"
		break;
	}
	case DECLARATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t62 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp29_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp29_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp29_AST = astFactory.create(_t);
		tmp29_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp29_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST62 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DECLARATION);
		_t = _t->getFirstChild();
		{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FINAL:
		{
			f = _t;
			f_AST = astFactory.create(f);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
			match(_t,FINAL);
			_t = _t->getNextSibling();
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INNER:
		case INPUT:
		case OUTER:
		case OUTPUT:
		case PARAMETER:
		case REPLACEABLE:
		case DOT:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 359 "walker.g"
		/*final = f!=NULL ? RML_TRUE : RML_FALSE;*/
#line 2549 "flat_modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INNER:
		{
			i = _t;
			i_AST = astFactory.create(i);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
			match(_t,INNER);
			_t = _t->getNextSibling();
			break;
		}
		case OUTER:
		{
			o = _t;
			o_AST = astFactory.create(o);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(o_AST));
			match(_t,OUTER);
			_t = _t->getNextSibling();
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case REPLACEABLE:
		case DOT:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 360 "walker.g"
		/*innerouter = make_inner_outer(i,o);*/
#line 2592 "flat_modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			e_spec=component_clause(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 362 "walker.g"
			
								//		ast = Absyn__ELEMENT(final,RML_FALSE,innerouter,
									//		mk_scon("component"),e_spec,mk_none());
									
#line 2614 "flat_modelica_tree_parser.cpp"
			break;
		}
		case REPLACEABLE:
		{
			r = _t;
			r_AST = astFactory.create(r);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r_AST));
			match(_t,REPLACEABLE);
			_t = _t->getNextSibling();
			e_spec=component_clause(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
			{
				constr=constraining_clause(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
#line 369 "walker.g"
			
									//	ast = Absyn__ELEMENT(final,
									//		r ? RML_TRUE : RML_FALSE,
									//		Absyn__UNSPECIFIED,
									//		mk_scon("replaceable_component"),e_spec,
									//		constr? mk_some(constr):mk_none());
									
#line 2656 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		}
		currentAST = __currentAST62;
		_t = __t62;
		_t = _t->getNextSibling();
		break;
	}
	case DEFINITION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t68 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp30_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp30_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp30_AST = astFactory.create(_t);
		tmp30_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp30_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST68 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DEFINITION);
		_t = _t->getFirstChild();
		{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FINAL:
		{
			fd = _t;
			fd_AST = astFactory.create(fd);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(fd_AST));
			match(_t,FINAL);
			_t = _t->getNextSibling();
			break;
		}
		case INNER:
		case OUTER:
		case REPLACEABLE:
		case CLASS_DEFINITION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 381 "walker.g"
		//final = fd!=NULL?RML_TRUE:RML_FALSE;
							
#line 2714 "flat_modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INNER:
		{
			id = _t;
			id_AST = astFactory.create(id);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(id_AST));
			match(_t,INNER);
			_t = _t->getNextSibling();
			break;
		}
		case OUTER:
		{
			od = _t;
			od_AST = astFactory.create(od);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(od_AST));
			match(_t,OUTER);
			_t = _t->getNextSibling();
			break;
		}
		case REPLACEABLE:
		case CLASS_DEFINITION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 383 "walker.g"
		//innerouter = make_inner_outer(i,o); 
							
#line 2751 "flat_modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,fd != NULL);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 387 "walker.g"
			
									// 	ast = Absyn__CLASSDEF(RML_PRIM_MKBOOL(0),
			// 								class_def);
			// 							ast = Absyn__ELEMENT(final,RML_FALSE,innerouter,mk_scon("??"),ast,mk_none());
			
									
#line 2768 "flat_modelica_tree_parser.cpp"
			break;
		}
		case REPLACEABLE:
		{
			{
			rd = _t;
			rd_AST = astFactory.create(rd);
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(rd_AST));
			match(_t,REPLACEABLE);
			_t = _t->getNextSibling();
			class_def=class_definition(_t,fd != NULL);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
			{
				constr=constraining_clause(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			}
#line 398 "walker.g"
			
			// 							ast = Absyn__CLASSDEF(rd ? RML_TRUE : RML_FALSE,
			// 								class_def);
			// 							ast = Absyn__ELEMENT(final,
			// 								rd ? RML_TRUE : RML_FALSE,innerouter,
			// 								mk_scon("??"),
			// 								ast,constr ? mk_some(constr) : mk_none());
									
#line 2813 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		}
		currentAST = __currentAST68;
		_t = __t68;
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	element_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::import_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 413 "walker.g"
	void* ast;
#line 2843 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST import_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST import_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 413 "walker.g"
	
		void* imp = 0;
		void* cmt = 0;
	
#line 2855 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t76 = _t;
	i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST76 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IMPORT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	{
		imp=explicit_import_name(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case QUALIFIED:
	case UNQUALIFIED:
	{
		imp=implicit_import_name(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST76;
	_t = __t76;
	_t = _t->getNextSibling();
#line 425 "walker.g"
	
	//			ast = Absyn__IMPORT(imp, cmt ? mk_some(cmt) : mk_none());
			
#line 2919 "flat_modelica_tree_parser.cpp"
	import_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = import_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::extends_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 463 "walker.g"
	void* ast;
#line 2929 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST extends_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST extends_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 463 "walker.g"
	
		void* path;
		void* mod = 0;
	
#line 2941 "flat_modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t87 = _t;
	e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	e_AST = astFactory.create(e);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST87 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EXTENDS);
	_t = _t->getFirstChild();
	path=name_path(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		mod=class_modification(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST87;
	_t = __t87;
	_t = _t->getNextSibling();
#line 473 "walker.g"
	
				// 	if (!mod) mod = mk_nil();
	// 				ast = Absyn__EXTENDS(path,mod);
				
#line 2985 "flat_modelica_tree_parser.cpp"
	}
	extends_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = extends_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::component_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 485 "walker.g"
	void* ast;
#line 2996 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 485 "walker.g"
	
		type_prefix_t pfx;
	//	void* pfx = 0;
	//	void* attr = 0;
		void* path = 0;
		void* arr = 0;
		void* comp_list = 0;
	
#line 3010 "flat_modelica_tree_parser.cpp"
	
	type_prefix(_t,pfx);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	path=type_specifier(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		arr=array_subscripts(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	comp_list=component_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 499 "walker.g"
	
	
	while( !(var_stack.empty()) ){
	modSimPackTest::FlatVariable(variable_type , // "Real"
	var_stack.top(),
	(int)(pfx.flow), 
	(int)(pfx.variability), 
	(int)(pfx.direction), 
	10.0);
	var_stack.pop();
	}
	
	// 			if (!arr)
	// 			{
	// 				arr = mk_nil();
	// 			}
	
	// 			attr = Absyn__ATTR(
	// 				pfx.flow,
	// 				pfx.variability,
	// 				pfx.direction,
	//  				arr);
	
	// 			ast = Absyn__COMPONENTS(attr, path, comp_list);
			
#line 3068 "flat_modelica_tree_parser.cpp"
	component_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_clause_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::constraining_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 480 "walker.g"
	void *ast;
#line 3078 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST constraining_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST constraining_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	ast=extends_clause(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	constraining_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = constraining_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::explicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 431 "walker.g"
	void* ast;
#line 3098 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST explicit_import_name_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST explicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 431 "walker.g"
	
		void* path;
	//	void* id;
	
#line 3110 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t80 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp31_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp31_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp31_AST = astFactory.create(_t);
	tmp31_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp31_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST80 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUALS);
	_t = _t->getFirstChild();
	i = _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	path=name_path(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST80;
	_t = __t80;
	_t = _t->getNextSibling();
#line 438 "walker.g"
	
		//		id = to_rml_str(i);
			//	ast = Absyn__NAMED_5fIMPORT(id,path);
			
#line 3139 "flat_modelica_tree_parser.cpp"
	explicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = explicit_import_name_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::implicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 444 "walker.g"
	void* ast;
#line 3149 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST implicit_import_name_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 444 "walker.g"
	
		void* path;
	
#line 3158 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNQUALIFIED:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t83 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp32_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp32_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp32_AST = astFactory.create(_t);
		tmp32_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp32_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST83 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,UNQUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST83;
		_t = __t83;
		_t = _t->getNextSibling();
#line 450 "walker.g"
		
					//	ast = Absyn__UNQUAL_5fIMPORT(path);
					
#line 3187 "flat_modelica_tree_parser.cpp"
		break;
	}
	case QUALIFIED:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t84 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp33_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp33_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp33_AST = astFactory.create(_t);
		tmp33_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp33_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST84 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,QUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST84;
		_t = __t84;
		_t = _t->getNextSibling();
#line 454 "walker.g"
		
						//ast = Absyn__QUAL_5fIMPORT(path);
					
#line 3213 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = implicit_import_name_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::type_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 568 "walker.g"
	void* ast;
#line 3231 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST type_specifier_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ast=name_path(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	type_specifier_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = type_specifier_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::component_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 574 "walker.g"
	void* ast;
#line 3249 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 574 "walker.g"
	
		//el_stack el_stack;
		void* e=0;
	
#line 3259 "flat_modelica_tree_parser.cpp"
	
	e=component_declaration(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 580 "walker.g"
	/*el_stack.push(e); */
#line 3266 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==IDENT)) {
			e=component_declaration(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 581 "walker.g"
			/*el_stack.push(e); */
#line 3277 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop100;
		}
		
	}
	_loop100:;
	}
#line 582 "walker.g"
	
	//			ast = make_rml_list_from_stack(el_stack);
			
#line 3290 "flat_modelica_tree_parser.cpp"
	component_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::component_declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 589 "walker.g"
	void* ast;
#line 3300 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_declaration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 589 "walker.g"
	
		void* cmt = 0;
		void* dec = 0;
	
	
#line 3311 "flat_modelica_tree_parser.cpp"
	
	{
	dec=declaration(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case EXTENDS:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 597 "walker.g"
	
		//		ast = Absyn__COMPONENTITEM(dec,cmt ? mk_some(cmt) : mk_none());
			
#line 3345 "flat_modelica_tree_parser.cpp"
	component_declaration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_declaration_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 604 "walker.g"
	void* ast;
#line 3355 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST declaration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 604 "walker.g"
	
		void* arr = 0;
		void* mod = 0;
	//	void* id = 0;
	
#line 3368 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t105 = _t;
	i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST105 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IDENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		arr=array_subscripts(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		mod=modification(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST105;
	_t = __t105;
	_t = _t->getNextSibling();
#line 612 "walker.g"
	
	var_stack.push( i->getText() );
	
	//i->getText()
	if (arr) {
	cerr << "Found array subscript which is not handeled yet";
	}
	
			// 	if (!arr) arr = mk_nil();
	// 			id = to_rml_str(i);
	// 			ast = Absyn__COMPONENT(id, arr, mod ? mk_some(mod) : mk_none());
	
			
#line 3443 "flat_modelica_tree_parser.cpp"
	declaration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = declaration_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 627 "walker.g"
	void* ast;
#line 3453 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST modification_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 627 "walker.g"
	
		void* e = 0;
		void* cm = 0;
	
#line 3463 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		cm=class_modification(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case AND:
		case END:
		case FALSE:
		case IF:
		case NOT:
		case OR:
		case TRUE:
		case UNSIGNED_REAL:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case STAR:
		case SLASH:
		case DOT:
		case LESS:
		case LESSEQ:
		case GREATER:
		case GREATEREQ:
		case EQEQ:
		case LESSGT:
		case POWER:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		case FUNCTION_CALL:
		case INITIAL_FUNCTION_CALL:
		case RANGE2:
		case RANGE3:
		case UNARY_MINUS:
		case UNARY_PLUS:
		{
			e=expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		case STRING_COMMENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		break;
	}
	case EQUALS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t111 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp34_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp34_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp34_AST = astFactory.create(_t);
		tmp34_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST111 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUALS);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST111;
		_t = __t111;
		_t = _t->getNextSibling();
		break;
	}
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t112 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp35_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp35_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp35_AST = astFactory.create(_t);
		tmp35_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp35_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST112 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ASSIGN);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST112;
		_t = __t112;
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 637 "walker.g"
	
	// 			if (!e) e = mk_none();
	// 			else e = mk_some(e);
	
	// 			if (!cm) cm = mk_nil();
	
	// 			ast = Absyn__CLASSMOD(cm, e);
			
#line 3586 "flat_modelica_tree_parser.cpp"
	modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = modification_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1195 "walker.g"
	void* ast;
#line 3596 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case END:
	case FALSE:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case RANGE2:
	case RANGE3:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=simple_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IF:
	{
		ast=if_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::argument_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 658 "walker.g"
	void* ast;
#line 3665 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 658 "walker.g"
	
		//el_stack el_stack;
		void* e;
	
#line 3675 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t117 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp36_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp36_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp36_AST = astFactory.create(_t);
	tmp36_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp36_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST117 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ARGUMENT_LIST);
	_t = _t->getFirstChild();
	e=argument(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 665 "walker.g"
	/*el_stack.push(e); */
#line 3693 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ELEMENT_MODIFICATION||_t->getType()==ELEMENT_REDECLARATION)) {
			e=argument(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 666 "walker.g"
			/*el_stack.push(e); */
#line 3704 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop119;
		}
		
	}
	_loop119:;
	}
	currentAST = __currentAST117;
	_t = __t117;
	_t = _t->getNextSibling();
#line 668 "walker.g"
	
		//		ast = make_rml_list_from_stack(el_stack);
			
#line 3720 "flat_modelica_tree_parser.cpp"
	argument_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = argument_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 673 "walker.g"
	void* ast;
#line 3730 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELEMENT_MODIFICATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t121 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp37_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp37_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp37_AST = astFactory.create(_t);
		tmp37_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp37_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST121 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ELEMENT_MODIFICATION);
		_t = _t->getFirstChild();
		ast=element_modification(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST121;
		_t = __t121;
		_t = _t->getNextSibling();
		argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case ELEMENT_REDECLARATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t122 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp38_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp38_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp38_AST = astFactory.create(_t);
		tmp38_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp38_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST122 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ELEMENT_REDECLARATION);
		_t = _t->getFirstChild();
		ast=element_redeclaration(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST122;
		_t = __t122;
		_t = _t->getNextSibling();
		argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = argument_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::element_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 680 "walker.g"
	void* ast;
#line 3796 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_modification_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 680 "walker.g"
	
		void* cref;
		void* mod;
	//	void* final;
	//	void* each;
		void* cmt=0;
	
#line 3813 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EACH:
	{
		e = _t;
		e_AST = astFactory.create(e);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		match(_t,EACH);
		_t = _t->getNextSibling();
		break;
	}
	case FINAL:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FINAL:
	{
		f = _t;
		f_AST = astFactory.create(f);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(_t,FINAL);
		_t = _t->getNextSibling();
		break;
	}
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	cref=component_reference(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	mod=modification(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 694 "walker.g"
	
			// 	final = f != NULL ? RML_TRUE : RML_FALSE;
	// 			each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH;
	// 			ast = Absyn__MODIFICATION(final, each, cref, mod, cmt ? mk_some(cmt) : mk_none());
			
#line 3879 "flat_modelica_tree_parser.cpp"
	element_modification_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_modification_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::element_redeclaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 701 "walker.g"
	void* ast;
#line 3889 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_redeclaration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_redeclaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST re = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST re_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 701 "walker.g"
	
		void* class_def = 0;
		void* e_spec; 
		void* constr = 0;
	//	void* final;
	//	void* each;
	
#line 3910 "flat_modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t128 = _t;
	r = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	r_AST = astFactory.create(r);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST128 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,REDECLARE);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EACH:
	{
		e = _t;
		e_AST = astFactory.create(e);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		match(_t,EACH);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FINAL:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case REPLACEABLE:
	case DOT:
	case IDENT:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FINAL:
	{
		f = _t;
		f_AST = astFactory.create(f);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(_t,FINAL);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case REPLACEABLE:
	case DOT:
	case IDENT:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case DOT:
	case IDENT:
	case CLASS_DEFINITION:
	{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,false);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 713 "walker.g"
			
				// 						e_spec = Absyn__CLASSDEF(RML_FALSE,class_def);
			// 							final = f != NULL ? RML_TRUE : RML_FALSE;
			// 							each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH;				
			// 							ast = Absyn__REDECLARATION(final, each, e_spec, mk_none());
									
#line 4017 "flat_modelica_tree_parser.cpp"
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			e_spec=component_clause1(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 720 "walker.g"
			
			// 							final = f != NULL ? RML_TRUE : RML_FALSE;
			// 							each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH;				
			// 							ast = Absyn__REDECLARATION(final, each, e_spec, mk_none());
									
#line 4038 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		break;
	}
	case REPLACEABLE:
	{
		{
		re = _t;
		re_AST = astFactory.create(re);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(re_AST));
		match(_t,REPLACEABLE);
		_t = _t->getNextSibling();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,false);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			e_spec=component_clause1(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXTENDS:
		{
			constr=constraining_clause(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 732 "walker.g"
			
		// 							if (class_def) 
		// 							{	
		// 								e_spec = Absyn__CLASSDEF(RML_TRUE, class_def);
		// 								final = f != NULL ? RML_TRUE : RML_FALSE;
		// 								each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH;				
		// 								ast = Absyn__REDECLARATION(final, each, e_spec,
		// 									constr ? mk_some(constr) : mk_none());
		// 							} else {
		// 								ast = Absyn__REDECLARATION(final, each, e_spec,
		// 									constr ? mk_some(constr) : mk_none());
		// 							}
								
#line 4123 "flat_modelica_tree_parser.cpp"
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST128;
	_t = __t128;
	_t = _t->getNextSibling();
	}
	element_redeclaration_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = element_redeclaration_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::component_clause1(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 751 "walker.g"
	void* ast;
#line 4146 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause1_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 751 "walker.g"
	
		type_prefix_t pfx;
	//	void* attr = 0;
		void* path = 0;
	//	void* arr = 0;
		void* comp_decl = 0;
	//	void* comp_list = 0;
	
#line 4160 "flat_modelica_tree_parser.cpp"
	
	type_prefix(_t,pfx);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	path=type_specifier(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	comp_decl=component_declaration(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 764 "walker.g"
	
	// 			if (!arr)
	// 			{
	// 				arr = mk_nil();
	// 			}
	// 			comp_list = mk_cons(comp_decl,mk_nil());
	// 			attr = Absyn__ATTR(
	// 				pfx.flow,
	// 				pfx.variability,
	// 				pfx.direction,
	// 				arr);
	
	// 			ast = Absyn__COMPONENTS(attr, path, comp_list);
			
#line 4186 "flat_modelica_tree_parser.cpp"
	component_clause1_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = component_clause1_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 844 "walker.g"
	void* ast;
#line 4196 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 844 "walker.g"
	
		void *cmt = 0;
	
#line 4205 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t155 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp39_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp39_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp39_AST = astFactory.create(_t);
	tmp39_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp39_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST155 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUATION_STATEMENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	{
		ast=equality_equation(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IF:
	{
		ast=conditional_equation_e(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case FOR:
	{
		ast=for_clause_e(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case WHEN:
	{
		ast=when_clause_e(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case CONNECT:
	{
		ast=connect_clause(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IDENT:
	{
		ast=equation_funcall(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 858 "walker.g"
	
		//			ast = Absyn__EQUATIONITEM(ast,cmt ? mk_some(cmt) : mk_none());
				
#line 4295 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST155;
	_t = __t155;
	_t = _t->getNextSibling();
	equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::algorithm(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 875 "walker.g"
	void* ast;
#line 4308 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 875 "walker.g"
	
		void* cref;
		void* expr;
		void* tuple;
		void* args;
		void* cmt;
	
#line 4321 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t160 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp40_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp40_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp40_AST = astFactory.create(_t);
	tmp40_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp40_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST160 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ALGORITHM_STATEMENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t162 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp41_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp41_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp41_AST = astFactory.create(_t);
		tmp41_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp41_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST162 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ASSIGN);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			expr=expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 887 "walker.g"
			
					//					ast = Absyn__ALG_5fASSIGN(cref,expr);
									
#line 4368 "flat_modelica_tree_parser.cpp"
			break;
		}
		case EXPRESSION_LIST:
		{
			{
			tuple=expression_list(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			cref=component_reference(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			args=function_call(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
#line 891 "walker.g"
			
						//				ast = Absyn__ALG_5fTUPLE_5fASSIGN(Absyn__TUPLE(tuple),Absyn__CALL(cref,args));
									
#line 4388 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST162;
		_t = __t162;
		_t = _t->getNextSibling();
		break;
	}
	case DOT:
	case IDENT:
	{
		ast=algorithm_function_call(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IF:
	{
		ast=conditional_equation_a(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case FOR:
	{
		ast=for_clause_a(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case WHILE:
	{
		ast=while_clause(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case WHEN:
	{
		ast=when_clause_a(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 903 "walker.g"
		
					//ast = Absyn__ALGORITHMITEM(ast, cmt ?  mk_some(cmt) : mk_none());
		  		
#line 4469 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST160;
	_t = __t160;
	_t = _t->getNextSibling();
	algorithm_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::equality_equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 921 "walker.g"
	void* ast;
#line 4482 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equality_equation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equality_equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 921 "walker.g"
	
		void* e1;
		void* e2;
	
#line 4492 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t168 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp42_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp42_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp42_AST = astFactory.create(_t);
	tmp42_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp42_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST168 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUALS);
	_t = _t->getFirstChild();
	e1=simple_expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	e2=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST168;
	_t = __t168;
	_t = _t->getNextSibling();
#line 928 "walker.g"
	
	eq_stack.push("EQUALS");
	//      eq_stack.pop(); //Fix to remove an extra EQUALS. Should be changed later.
	modSimPackTest::FlatEquation(eq_stack);
				//ast = Absyn__EQ_5fEQUALS(e1,e2);
			
#line 4521 "flat_modelica_tree_parser.cpp"
	equality_equation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equality_equation_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::conditional_equation_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 936 "walker.g"
	void* ast;
#line 4531 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 936 "walker.g"
	
		void* e1;
		void* then_b;
		void* else_b = 0;
	//	void* else_if_b;
		//el_stack el_stack;
		void* e;
	
#line 4545 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t170 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp43_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp43_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp43_AST = astFactory.create(_t);
	tmp43_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp43_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST170 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	then_b=equation_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ELSEIF)) {
			e=equation_elseif(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 949 "walker.g"
			/*el_stack.push(e);*/
#line 4574 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop172;
		}
		
	}
	_loop172:;
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp44_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp44_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp44_AST = astFactory.create(_t);
		tmp44_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp44_AST));
		match(_t,ELSE);
		_t = _t->getNextSibling();
		else_b=equation_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST170;
	_t = __t170;
	_t = _t->getNextSibling();
#line 952 "walker.g"
	
	// 			else_if_b = make_rml_list_from_stack(el_stack);
	// 			if (!else_b) else_b = mk_nil();
	// 			ast = Absyn__EQ_5fIF(e1, then_b, else_if_b, else_b);
			
#line 4620 "flat_modelica_tree_parser.cpp"
	conditional_equation_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = conditional_equation_e_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::for_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 982 "walker.g"
	void* ast;
#line 4630 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 982 "walker.g"
	
		void* e;
		void* eq;
	//	void* id;
	
#line 4643 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t180 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp45_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp45_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp45_AST = astFactory.create(_t);
	tmp45_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp45_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST180 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,FOR);
	_t = _t->getFirstChild();
	ANTLR_USE_NAMESPACE(antlr)RefAST __t181 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp46_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp46_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp46_AST = astFactory.create(_t);
	tmp46_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp46_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST181 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IN);
	_t = _t->getFirstChild();
	i = _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST181;
	_t = __t181;
	_t = _t->getNextSibling();
	eq=equation_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST180;
	_t = __t180;
	_t = _t->getNextSibling();
#line 994 "walker.g"
	
	// 			id = to_rml_str(i);
	// 			ast = Absyn__EQ_5fFOR(id,e,eq);
			
#line 4689 "flat_modelica_tree_parser.cpp"
	for_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_clause_e_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::when_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1031 "walker.g"
	void* ast;
#line 4699 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1031 "walker.g"
	
		//el_stack el_stack;
		void* e;
		void* body;
		void* el = 0;
	
#line 4711 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t188 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp47_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp47_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp47_AST = astFactory.create(_t);
	tmp47_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp47_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST188 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	body=equation_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ELSEWHEN)) {
			el=else_when_e(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1042 "walker.g"
			/*el_stack.push(el);*/
#line 4740 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop190;
		}
		
	}
	_loop190:;
	}
	currentAST = __currentAST188;
	_t = __t188;
	_t = _t->getNextSibling();
#line 1044 "walker.g"
	
		//		ast = Absyn__EQ_5fWHEN_5fE(e,body,make_rml_list_from_stack(el_stack));
			
#line 4756 "flat_modelica_tree_parser.cpp"
	when_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = when_clause_e_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::connect_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1144 "walker.g"
	void* ast;
#line 4766 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST connect_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connect_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1144 "walker.g"
	
		void* r1;
		void* r2;
	
#line 4776 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t210 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp48_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp48_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp48_AST = astFactory.create(_t);
	tmp48_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp48_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST210 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,CONNECT);
	_t = _t->getFirstChild();
	r1=connector_ref(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	r2=connector_ref(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST210;
	_t = __t210;
	_t = _t->getNextSibling();
#line 1154 "walker.g"
	
	//			ast = Absyn__EQ_5fCONNECT(r1,r2);
			
#line 4802 "flat_modelica_tree_parser.cpp"
	connect_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = connect_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::equation_funcall(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 864 "walker.g"
	void* ast;
#line 4812 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_funcall_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_funcall_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 864 "walker.g"
	
	void *fcall = 0;
	
#line 4823 "flat_modelica_tree_parser.cpp"
	
	i = _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	fcall=function_call(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 870 "walker.g"
	
				//ast = Absyn__EQ_5fNORETCALL(to_rml_str(i),fcall); 
			
#line 4837 "flat_modelica_tree_parser.cpp"
	equation_funcall_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_funcall_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1501 "walker.g"
	void* ast;
#line 4847 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1501 "walker.g"
	
	
	
#line 4856 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t289 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp49_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp49_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp49_AST = astFactory.create(_t);
	tmp49_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp49_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST289 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,FUNCTION_ARGUMENTS);
	_t = _t->getFirstChild();
#line 1506 "walker.g"
	
			
#line 4872 "flat_modelica_tree_parser.cpp"
	ast=function_arguments(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1508 "walker.g"
	
			
#line 4879 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST289;
	_t = __t289;
	_t = _t->getNextSibling();
	function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = function_call_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::algorithm_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 909 "walker.g"
	void* ast;
#line 4892 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 909 "walker.g"
	
		void* cref;
		void* args;
	
#line 4902 "flat_modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	args=function_call(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 916 "walker.g"
	
				//ast = Absyn__ALG_5fNORETCALL(cref,args);
			
#line 4914 "flat_modelica_tree_parser.cpp"
	algorithm_function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_function_call_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::conditional_equation_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 959 "walker.g"
	void* ast;
#line 4924 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 959 "walker.g"
	
		void* e1;
		void* then_b;
		void* else_b = 0;
	//	void* else_if_b;
		//el_stack el_stack;
		void* e;
	
#line 4938 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t175 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp50_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp50_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp50_AST = astFactory.create(_t);
	tmp50_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp50_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST175 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	then_b=algorithm_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ELSEIF)) {
			e=algorithm_elseif(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 972 "walker.g"
			/*el_stack.push(e);  */
#line 4967 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop177;
		}
		
	}
	_loop177:;
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp51_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp51_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp51_AST = astFactory.create(_t);
		tmp51_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp51_AST));
		match(_t,ELSE);
		_t = _t->getNextSibling();
		else_b=algorithm_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST175;
	_t = __t175;
	_t = _t->getNextSibling();
#line 975 "walker.g"
	
	// 			else_if_b = make_rml_list_from_stack(el_stack);
	// 			if (!else_b) else_b = mk_nil();
	// 			ast = Absyn__ALG_5fIF(e1, then_b, else_if_b, else_b);
			
#line 5013 "flat_modelica_tree_parser.cpp"
	conditional_equation_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = conditional_equation_a_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::for_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1000 "walker.g"
	void* ast;
#line 5023 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1000 "walker.g"
	
		void* e;
		void* eq;
	//	void* id;
	
#line 5036 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t183 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp52_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp52_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp52_AST = astFactory.create(_t);
	tmp52_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp52_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST183 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,FOR);
	_t = _t->getFirstChild();
	ANTLR_USE_NAMESPACE(antlr)RefAST __t184 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp53_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp53_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp53_AST = astFactory.create(_t);
	tmp53_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp53_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST184 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IN);
	_t = _t->getFirstChild();
	i = _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST184;
	_t = __t184;
	_t = _t->getNextSibling();
	eq=algorithm_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST183;
	_t = __t183;
	_t = _t->getNextSibling();
#line 1011 "walker.g"
	
	// 			id = to_rml_str(i);
	// 			ast = Absyn__ALG_5fFOR(id,e,eq);
			
#line 5082 "flat_modelica_tree_parser.cpp"
	for_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = for_clause_a_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::while_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1017 "walker.g"
	void* ast;
#line 5092 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST while_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST while_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1017 "walker.g"
	
		void* e;
		void* body;
	
#line 5102 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t186 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp54_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp54_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp54_AST = astFactory.create(_t);
	tmp54_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp54_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST186 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WHILE);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	body=algorithm_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST186;
	_t = __t186;
	_t = _t->getNextSibling();
#line 1026 "walker.g"
	
	//			ast = Absyn__ALG_5fWHILE(e,body);
			
#line 5128 "flat_modelica_tree_parser.cpp"
	while_clause_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = while_clause_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::when_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1062 "walker.g"
	void* ast;
#line 5138 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1062 "walker.g"
	
		//el_stack el_stack;
		void* e;
		void* body;
		void* el = 0;
	
#line 5150 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t194 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp55_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp55_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp55_AST = astFactory.create(_t);
	tmp55_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp55_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST194 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	body=algorithm_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ELSEWHEN)) {
			el=else_when_a(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1073 "walker.g"
			/*el_stack.push(el);*/
#line 5179 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop196;
		}
		
	}
	_loop196:;
	}
	currentAST = __currentAST194;
	_t = __t194;
	_t = _t->getNextSibling();
#line 1075 "walker.g"
	
				//ast = Absyn__ALG_5fWHEN_5fA(e,body,make_rml_list_from_stack(el_stack));
			
#line 5195 "flat_modelica_tree_parser.cpp"
	when_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = when_clause_a_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::simple_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1233 "walker.g"
	void* ast;
#line 5205 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST simple_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1233 "walker.g"
	
		void* e1;
		void* e2;
		void* e3;
	
#line 5216 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case RANGE3:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t231 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp56_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp56_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp56_AST = astFactory.create(_t);
		tmp56_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp56_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST231 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,RANGE3);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e3=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST231;
		_t = __t231;
		_t = _t->getNextSibling();
#line 1243 "walker.g"
		
			//			ast = Absyn__RANGE(e1,mk_some(e2),e3);
					
#line 5251 "flat_modelica_tree_parser.cpp"
		break;
	}
	case RANGE2:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t232 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp57_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp57_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp57_AST = astFactory.create(_t);
		tmp57_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp57_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST232 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,RANGE2);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e3=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST232;
		_t = __t232;
		_t = _t->getNextSibling();
#line 1247 "walker.g"
		
		
			//			ast = Absyn__RANGE(e1,mk_none(),e3);
					
#line 5281 "flat_modelica_tree_parser.cpp"
		break;
	}
	case AND:
	case END:
	case FALSE:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = simple_expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::equation_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1122 "walker.g"
	void* ast;
#line 5334 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1122 "walker.g"
	
		void* e;
	
#line 5343 "flat_modelica_tree_parser.cpp"
	
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==EQUATION_STATEMENT)) {
			e=equation(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1127 "walker.g"
			/*el_stack.push(e); */
#line 5355 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop205;
		}
		
	}
	_loop205:;
	}
#line 1128 "walker.g"
	
				//ast = make_rml_list_from_stack(el_stack);
			
#line 5368 "flat_modelica_tree_parser.cpp"
	equation_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::equation_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1092 "walker.g"
	void* ast;
#line 5378 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_elseif_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1092 "walker.g"
	
		void* e;
		void* eq;
	
#line 5388 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t200 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp58_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp58_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp58_AST = astFactory.create(_t);
	tmp58_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp58_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST200 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	eq=equation_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST200;
	_t = __t200;
	_t = _t->getNextSibling();
#line 1102 "walker.g"
	
				//ast = mk_box2(0,e,eq);
			
#line 5414 "flat_modelica_tree_parser.cpp"
	equation_elseif_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = equation_elseif_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::algorithm_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1133 "walker.g"
	void* ast;
#line 5424 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1133 "walker.g"
	
		void* e;
	
#line 5433 "flat_modelica_tree_parser.cpp"
	
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ALGORITHM_STATEMENT)) {
			e=algorithm(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1138 "walker.g"
			/*el_stack.push(e); */
#line 5445 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop208;
		}
		
	}
	_loop208:;
	}
#line 1139 "walker.g"
	
				//ast = make_rml_list_from_stack(el_stack);
			
#line 5458 "flat_modelica_tree_parser.cpp"
	algorithm_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::algorithm_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1107 "walker.g"
	void* ast;
#line 5468 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_elseif_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1107 "walker.g"
	
		void* e;
		void* body;
	
#line 5478 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t202 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp59_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp59_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp59_AST = astFactory.create(_t);
	tmp59_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp59_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST202 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	body=algorithm_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST202;
	_t = __t202;
	_t = _t->getNextSibling();
#line 1117 "walker.g"
	
				//ast = mk_box2(0,e,body);
			
#line 5504 "flat_modelica_tree_parser.cpp"
	algorithm_elseif_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = algorithm_elseif_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::else_when_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1050 "walker.g"
	void *ast;
#line 5514 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1050 "walker.g"
	
		void * expr;
		void * eqn;
	
#line 5526 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t192 = _t;
	e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	e_AST = astFactory.create(e);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST192 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	eqn=equation_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST192;
	_t = __t192;
	_t = _t->getNextSibling();
#line 1057 "walker.g"
	
			//	ast = mk_box2(0,expr,eqn);
			
#line 5550 "flat_modelica_tree_parser.cpp"
	else_when_e_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = else_when_e_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::else_when_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1080 "walker.g"
	void *ast;
#line 5560 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1080 "walker.g"
	
		void * expr;
		void * alg;
	
#line 5572 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t198 = _t;
	e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	e_AST = astFactory.create(e);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST198 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	alg=algorithm_list(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST198;
	_t = __t198;
	_t = _t->getNextSibling();
#line 1087 "walker.g"
	
				//ast = mk_box2(0,expr,alg);
			
#line 5596 "flat_modelica_tree_parser.cpp"
	else_when_a_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = else_when_a_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::connector_ref(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1159 "walker.g"
	void* ast;
#line 5606 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1159 "walker.g"
	
		void* as = 0;
	//	void* id = 0;
	
#line 5620 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t213 = _t;
		i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		i_AST = astFactory.create(i);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST213 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			as=array_subscripts(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST213;
		_t = __t213;
		_t = _t->getNextSibling();
#line 1166 "walker.g"
		
		// 				if (!as) as = mk_nil();
		// 				id = to_rml_str(i);
		// 				ast = Absyn__CREF_5fIDENT(id,as);
					
#line 5667 "flat_modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t215 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp60_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp60_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp60_AST = astFactory.create(_t);
		tmp60_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp60_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST215 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DOT);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t216 = _t;
		i2 = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		i2_AST = astFactory.create(i2);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST216 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			as=array_subscripts(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST216;
		_t = __t216;
		_t = _t->getNextSibling();
		ast=connector_ref_2(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST215;
		_t = __t215;
		_t = _t->getNextSibling();
#line 1173 "walker.g"
		
		// 				if (!as) as = mk_nil();
		// 				id = to_rml_str(i2);
		// 				ast = Absyn__CREF_5fQUAL(id,as,ast);
					
#line 5728 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	connector_ref_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = connector_ref_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::connector_ref_2(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1181 "walker.g"
	void* ast;
#line 5746 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_2_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connector_ref_2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1181 "walker.g"
	
		void* as = 0;
	//	void* id;
	
#line 5758 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t219 = _t;
	i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST219 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IDENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		as=array_subscripts(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST219;
	_t = __t219;
	_t = _t->getNextSibling();
#line 1188 "walker.g"
	
	// 			if (!as) as = mk_nil();
	// 			id = to_rml_str(i);
	// 			ast = Absyn__CREF_5fIDENT(id,as);
			
#line 5799 "flat_modelica_tree_parser.cpp"
	connector_ref_2_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = connector_ref_2_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::if_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1202 "walker.g"
	void* ast;
#line 5809 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST if_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST if_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1202 "walker.g"
	
		void* cond;
		void* thenPart;
		void* elsePart;
		void* e;
	//	void* elseifPart;
	
#line 5822 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t224 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp61_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp61_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp61_AST = astFactory.create(_t);
	tmp61_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp61_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST224 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IF);
	_t = _t->getFirstChild();
	cond=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	thenPart=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==ELSEIF)) {
			e=elseif_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1212 "walker.g"
			/*el_stack.push(e);*/
#line 5851 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop226;
		}
		
	}
	_loop226:;
	}
	elsePart=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1213 "walker.g"
	
	// 				elseifPart = make_rml_list_from_stack(el_stack);
	// 				ast = Absyn__IFEXP(cond,thenPart,elsePart,elseifPart);
				
#line 5868 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST224;
	_t = __t224;
	_t = _t->getNextSibling();
	if_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = if_expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::elseif_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1220 "walker.g"
	void* ast;
#line 5881 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST elseif_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST elseif_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1220 "walker.g"
	
		void *cond;
		void *thenPart;
	
#line 5891 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t228 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp62_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp62_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp62_AST = astFactory.create(_t);
	tmp62_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp62_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST228 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEIF);
	_t = _t->getFirstChild();
	cond=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	thenPart=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1227 "walker.g"
	
	//			ast = mk_box2(0,cond,thenPart);
			
#line 5914 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST228;
	_t = __t228;
	_t = _t->getNextSibling();
	elseif_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = elseif_expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::logical_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1255 "walker.g"
	void* ast;
#line 5927 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1255 "walker.g"
	
		void* e1;
		void* e2;
	
#line 5937 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case END:
	case FALSE:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=logical_term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case OR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t235 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp63_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp63_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp63_AST = astFactory.create(_t);
		tmp63_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp63_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST235 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,OR);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=logical_term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST235;
		_t = __t235;
		_t = _t->getNextSibling();
#line 1263 "walker.g"
		
				//		ast = Absyn__LBINARY(e1,Absyn__OR, e2);
					
#line 6003 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	logical_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = logical_expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::logical_term(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1270 "walker.g"
	void* ast;
#line 6021 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_term_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1270 "walker.g"
	
		void* e1;
		void* e2;
	
#line 6031 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=logical_factor(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case AND:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t238 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp64_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp64_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp64_AST = astFactory.create(_t);
		tmp64_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp64_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST238 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,AND);
		_t = _t->getFirstChild();
		e1=logical_term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=logical_factor(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST238;
		_t = __t238;
		_t = _t->getNextSibling();
#line 1278 "walker.g"
		
				//		ast = Absyn__LBINARY(e1,Absyn__AND,e2);
					
#line 6096 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	logical_term_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = logical_term_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::logical_factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1284 "walker.g"
	void* ast;
#line 6114 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_factor_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case NOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t240 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp65_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp65_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp65_AST = astFactory.create(_t);
		tmp65_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp65_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST240 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,NOT);
		_t = _t->getFirstChild();
		ast=relation(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1286 "walker.g"
		/* ast = Absyn__LUNARY(Absyn__NOT,ast); */
#line 6141 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST240;
		_t = __t240;
		_t = _t->getNextSibling();
		logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=relation(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = logical_factor_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::relation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1289 "walker.g"
	void* ast;
#line 6194 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST relation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST relation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1289 "walker.g"
	
		void* e1;
	//	void* op = 0;
		void* e2 = 0;
	
#line 6205 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=arithmetic_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LESS:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t244 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp66_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp66_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp66_AST = astFactory.create(_t);
			tmp66_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp66_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST244 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,LESS);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST244;
			_t = __t244;
			_t = _t->getNextSibling();
#line 1299 "walker.g"
			/*op = Absyn__LESS;*/
#line 6272 "flat_modelica_tree_parser.cpp"
			break;
		}
		case LESSEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t245 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp67_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp67_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp67_AST = astFactory.create(_t);
			tmp67_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp67_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST245 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,LESSEQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST245;
			_t = __t245;
			_t = _t->getNextSibling();
#line 1301 "walker.g"
			/*op = Absyn__LESSEQ;*/
#line 6299 "flat_modelica_tree_parser.cpp"
			break;
		}
		case GREATER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t246 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp68_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp68_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp68_AST = astFactory.create(_t);
			tmp68_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp68_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST246 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,GREATER);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST246;
			_t = __t246;
			_t = _t->getNextSibling();
#line 1303 "walker.g"
			/*op = Absyn__GREATER;*/
#line 6326 "flat_modelica_tree_parser.cpp"
			break;
		}
		case GREATEREQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t247 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp69_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp69_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp69_AST = astFactory.create(_t);
			tmp69_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp69_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST247 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,GREATEREQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST247;
			_t = __t247;
			_t = _t->getNextSibling();
#line 1305 "walker.g"
			/*op = Absyn__GREATEREQ;*/
#line 6353 "flat_modelica_tree_parser.cpp"
			break;
		}
		case EQEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t248 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp70_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp70_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp70_AST = astFactory.create(_t);
			tmp70_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp70_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST248 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,EQEQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST248;
			_t = __t248;
			_t = _t->getNextSibling();
#line 1307 "walker.g"
			
			
			/*op = Absyn__EQUAL; */
#line 6382 "flat_modelica_tree_parser.cpp"
			break;
		}
		case LESSGT:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t249 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp71_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp71_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp71_AST = astFactory.create(_t);
			tmp71_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp71_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST249 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,LESSGT);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST249;
			_t = __t249;
			_t = _t->getNextSibling();
#line 1311 "walker.g"
			/*op = Absyn__NEQUAL; */
#line 6409 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 1313 "walker.g"
		
		//ast = Absyn__RELATION(e1,op,e2);
					
#line 6422 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 1317 "walker.g"
	
	
	
#line 6435 "flat_modelica_tree_parser.cpp"
	relation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = relation_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1333 "walker.g"
	void* ast;
#line 6445 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST arithmetic_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1333 "walker.g"
	
		void* e1;
		void* e2;
	
#line 6455 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case STAR:
	case SLASH:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=unary_arithmetic_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t254 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp72_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp72_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp72_AST = astFactory.create(_t);
		tmp72_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp72_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST254 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,PLUS);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST254;
		_t = __t254;
		_t = _t->getNextSibling();
#line 1341 "walker.g"
		
						eq_stack.push("PLUS");
						//ast = Absyn__BINARY(e1,Absyn__ADD,e2);
					
#line 6512 "flat_modelica_tree_parser.cpp"
		break;
	}
	case MINUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t255 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp73_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp73_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp73_AST = astFactory.create(_t);
		tmp73_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp73_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST255 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,MINUS);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST255;
		_t = __t255;
		_t = _t->getNextSibling();
#line 1346 "walker.g"
			
						eq_stack.push("MINUS");
						//ast = Absyn__BINARY(e1,Absyn__SUB,e2);
					
#line 6542 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = arithmetic_expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::rel_op(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1322 "walker.g"
	void* ast;
#line 6560 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST rel_op_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rel_op_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LESS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp74_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp74_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp74_AST = astFactory.create(_t);
		tmp74_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp74_AST));
		match(_t,LESS);
		_t = _t->getNextSibling();
#line 1324 "walker.g"
		/*ast = Absyn__LESS;*/
#line 6581 "flat_modelica_tree_parser.cpp"
		break;
	}
	case LESSEQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp75_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp75_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp75_AST = astFactory.create(_t);
		tmp75_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp75_AST));
		match(_t,LESSEQ);
		_t = _t->getNextSibling();
#line 1325 "walker.g"
		/*ast = Absyn__LESSEQ; */
#line 6595 "flat_modelica_tree_parser.cpp"
		break;
	}
	case GREATER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp76_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp76_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp76_AST = astFactory.create(_t);
		tmp76_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp76_AST));
		match(_t,GREATER);
		_t = _t->getNextSibling();
#line 1326 "walker.g"
		/*ast = Absyn__GREATER; */
#line 6609 "flat_modelica_tree_parser.cpp"
		break;
	}
	case GREATEREQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp77_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp77_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp77_AST = astFactory.create(_t);
		tmp77_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp77_AST));
		match(_t,GREATEREQ);
		_t = _t->getNextSibling();
#line 1327 "walker.g"
		/*ast = Absyn__GREATEREQ; */
#line 6623 "flat_modelica_tree_parser.cpp"
		break;
	}
	case EQEQ:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp78_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp78_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp78_AST = astFactory.create(_t);
		tmp78_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp78_AST));
		match(_t,EQEQ);
		_t = _t->getNextSibling();
#line 1328 "walker.g"
		/*ast = Absyn__EQUAL; */
#line 6637 "flat_modelica_tree_parser.cpp"
		break;
	}
	case LESSGT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp79_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp79_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp79_AST = astFactory.create(_t);
		tmp79_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp79_AST));
		match(_t,LESSGT);
		_t = _t->getNextSibling();
#line 1329 "walker.g"
		/*ast = Absyn__NEQUAL; */
#line 6651 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	rel_op_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = rel_op_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::unary_arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1353 "walker.g"
	void* ast;
#line 6669 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST unary_arithmetic_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNARY_PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t258 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp80_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp80_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp80_AST = astFactory.create(_t);
		tmp80_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp80_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST258 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,UNARY_PLUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST258;
		_t = __t258;
		_t = _t->getNextSibling();
#line 1355 "walker.g"
		eq_stack.push("UNARY_PLUS");
								/*ast = Absyn__UNARY(Absyn__UPLUS,ast);*/
#line 6701 "flat_modelica_tree_parser.cpp"
		break;
	}
	case UNARY_MINUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t259 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp81_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp81_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp81_AST = astFactory.create(_t);
		tmp81_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp81_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST259 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,UNARY_MINUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST259;
		_t = __t259;
		_t = _t->getNextSibling();
#line 1357 "walker.g"
		eq_stack.push("UNARY_MINUS");
								/*ast = Absyn__UNARY(Absyn__UMINUS,ast);*/
#line 6726 "flat_modelica_tree_parser.cpp"
		break;
	}
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case STAR:
	case SLASH:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = unary_arithmetic_expression_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::term(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1363 "walker.g"
	void* ast;
#line 6766 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST term_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1363 "walker.g"
	
		void* e1;
		void* e2;
	
#line 6776 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=factor(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case STAR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t262 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp82_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp82_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp82_AST = astFactory.create(_t);
		tmp82_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp82_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST262 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,STAR);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=factor(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST262;
		_t = __t262;
		_t = _t->getNextSibling();
#line 1371 "walker.g"
		
						eq_stack.push("STAR");
						//ast = Absyn__BINARY(e1,Absyn__MUL,e2); 
					
#line 6829 "flat_modelica_tree_parser.cpp"
		break;
	}
	case SLASH:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t263 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp83_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp83_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp83_AST = astFactory.create(_t);
		tmp83_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp83_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST263 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,SLASH);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=factor(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST263;
		_t = __t263;
		_t = _t->getNextSibling();
#line 1376 "walker.g"
		
						eq_stack.push("SLASH");
						//ast = Absyn__BINARY(e1,Absyn__DIV,e2); 
					
#line 6859 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	term_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = term_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1383 "walker.g"
	void* ast;
#line 6877 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST factor_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1383 "walker.g"
	
		void* e1;
		void* e2;
	
#line 6887 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case DOT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=primary(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case POWER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t266 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp84_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp84_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp84_AST = astFactory.create(_t);
		tmp84_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp84_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST266 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,POWER);
		_t = _t->getFirstChild();
		e1=primary(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=primary(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST266;
		_t = __t266;
		_t = _t->getNextSibling();
#line 1391 "walker.g"
		
						eq_stack.push("POWER");
						//ast = Absyn__BINARY(e1,Absyn__POW,e2);
					
#line 6939 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	factor_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = factor_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::primary(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1398 "walker.g"
	void* ast;
#line 6957 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST primary_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST primary_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ui = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ui_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ur = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ur_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST str = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST str_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1398 "walker.g"
	
		void* e;
	
#line 6972 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNSIGNED_INTEGER:
	{
		ui = _t;
		ui_AST = astFactory.create(ui);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ui_AST));
		match(_t,UNSIGNED_INTEGER);
		_t = _t->getNextSibling();
#line 1404 "walker.g"
			
				eq_stack.push(ui->getText());
						//ast = Absyn__INTEGER(mk_icon(str_to_int(ui->getText()))); 
					
#line 6990 "flat_modelica_tree_parser.cpp"
		break;
	}
	case UNSIGNED_REAL:
	{
		ur = _t;
		ur_AST = astFactory.create(ur);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ur_AST));
		match(_t,UNSIGNED_REAL);
		_t = _t->getNextSibling();
#line 1409 "walker.g"
		
				eq_stack.push(ur->getText());	
						//ast = Absyn__REAL(mk_rcon(str_to_double(ur->getText()))); 
					
#line 7005 "flat_modelica_tree_parser.cpp"
		break;
	}
	case STRING:
	{
		str = _t;
		str_AST = astFactory.create(str);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(str_AST));
		match(_t,STRING);
		_t = _t->getNextSibling();
#line 1414 "walker.g"
		
						eq_stack.push( str->getText() );
						//ast = Absyn__STRING(to_rml_str(str));
					
#line 7020 "flat_modelica_tree_parser.cpp"
		break;
	}
	case FALSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp85_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp85_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp85_AST = astFactory.create(_t);
		tmp85_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp85_AST));
		match(_t,FALSE);
		_t = _t->getNextSibling();
#line 1418 "walker.g"
		/*ast = Absyn__BOOL(RML_FALSE); */
#line 7034 "flat_modelica_tree_parser.cpp"
		break;
	}
	case TRUE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp86_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp86_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp86_AST = astFactory.create(_t);
		tmp86_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp86_AST));
		match(_t,TRUE);
		_t = _t->getNextSibling();
#line 1419 "walker.g"
		/*ast = Absyn__BOOL(RML_TRUE); */
#line 7048 "flat_modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	case IDENT:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=component_reference__function_call(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case LPAR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t269 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp87_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp87_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp87_AST = astFactory.create(_t);
		tmp87_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp87_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST269 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,LPAR);
		_t = _t->getFirstChild();
		ast=tuple_expression_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST269;
		_t = __t269;
		_t = _t->getNextSibling();
		break;
	}
	case LBRACK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t270 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp88_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp88_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp88_AST = astFactory.create(_t);
		tmp88_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp88_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST270 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,LBRACK);
		_t = _t->getFirstChild();
		e=expression_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1422 "walker.g"
		/*el_stack.push(e);  */
#line 7100 "flat_modelica_tree_parser.cpp"
		{
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			if ((_t->getType()==EXPRESSION_LIST)) {
				e=expression_list(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1423 "walker.g"
				/*el_stack.push(e); */
#line 7111 "flat_modelica_tree_parser.cpp"
			}
			else {
				goto _loop272;
			}
			
		}
		_loop272:;
		}
		currentAST = __currentAST270;
		_t = __t270;
		_t = _t->getNextSibling();
#line 1424 "walker.g"
		
						//ast = Absyn__MATRIX(make_rml_list_from_stack(el_stack));
					
#line 7127 "flat_modelica_tree_parser.cpp"
		break;
	}
	case LBRACE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t273 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp89_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp89_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp89_AST = astFactory.create(_t);
		tmp89_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp89_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST273 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,LBRACE);
		_t = _t->getFirstChild();
		ast=expression_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST273;
		_t = __t273;
		_t = _t->getNextSibling();
#line 1427 "walker.g"
		
		/*ast = Absyn__ARRAY(ast);*/ 
		
#line 7153 "flat_modelica_tree_parser.cpp"
		break;
	}
	case END:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp90_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp90_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp90_AST = astFactory.create(_t);
		tmp90_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp90_AST));
		match(_t,END);
		_t = _t->getNextSibling();
#line 1430 "walker.g"
		/*ast = Absyn__END; */
#line 7167 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	primary_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = primary_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::component_reference__function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1434 "walker.g"
	void* ast;
#line 7185 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference__function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1434 "walker.g"
	
		void* cref;
		void* fnc = 0;
	
#line 7195 "flat_modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	case FUNCTION_CALL:
	{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FUNCTION_CALL:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t276 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp91_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp91_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp91_AST = astFactory.create(_t);
			tmp91_AST_in = _t;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp91_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST276 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,FUNCTION_CALL);
			_t = _t->getFirstChild();
			cref=component_reference(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case FUNCTION_ARGUMENTS:
			{
				fnc=function_call(_t);
				_t = _retTree;
				astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			currentAST = __currentAST276;
			_t = __t276;
			_t = _t->getNextSibling();
#line 1441 "walker.g"
			
			
			// 				if (!fnc) fnc = mk_nil();
			// 				ast = Absyn__CALL(cref,fnc);
						
#line 7254 "flat_modelica_tree_parser.cpp"
			break;
		}
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1447 "walker.g"
			
			
			//				ast = Absyn__CREF(cref);
						
#line 7268 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case INITIAL_FUNCTION_CALL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t278 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp92_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp92_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp92_AST = astFactory.create(_t);
		tmp92_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp92_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST278 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,INITIAL_FUNCTION_CALL);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp93_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp93_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp93_AST = astFactory.create(_t);
		tmp93_AST_in = _t;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp93_AST));
		match(_t,INITIAL);
		_t = _t->getNextSibling();
		currentAST = __currentAST278;
		_t = __t278;
		_t = _t->getNextSibling();
#line 1454 "walker.g"
		
			//			ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("initial"), mk_nil()),Absyn__FUNCTIONARGS(mk_nil(),mk_nil()));
					
#line 7307 "flat_modelica_tree_parser.cpp"
		component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = component_reference__function_call_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::tuple_expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1562 "walker.g"
	void* ast;
#line 7324 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST tuple_expression_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tuple_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1562 "walker.g"
	
		//l_stack el_stack;
		void* e;
	
#line 7334 "flat_modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t306 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp94_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp94_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp94_AST = astFactory.create(_t);
	tmp94_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp94_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST306 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1569 "walker.g"
	/*el_stack.push(e); */
#line 7353 "flat_modelica_tree_parser.cpp"
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1570 "walker.g"
			/*el_stack.push(e); */
#line 7364 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop308;
		}
		
	}
	_loop308:;
	}
	currentAST = __currentAST306;
	_t = __t306;
	_t = _t->getNextSibling();
	}
#line 1573 "walker.g"
	
			// 	if (el_stack.size() == 1)
	// 			{
	// 				ast = el_stack.top();
	// 			}
	// 			else
	// 			{
	// 				ast = Absyn__TUPLE(make_rml_list_from_stack(el_stack));
	// 			}
			
#line 7388 "flat_modelica_tree_parser.cpp"
	tuple_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = tuple_expression_list_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::function_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1513 "walker.g"
	void* ast;
#line 7398 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST function_arguments_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1513 "walker.g"
	
	//	void* ast = 0;
	
#line 7407 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXPRESSION_LIST:
	{
		ast=expression_list(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case EQUALS:
	{
		ast=named_argument(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	function_arguments_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = function_arguments_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::named_argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1534 "walker.g"
	void* ast;
#line 7442 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST named_argument_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST eq = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST eq_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1534 "walker.g"
	
		void* temp;
	
#line 7455 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t298 = _t;
	eq = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	eq_AST = astFactory.create(eq);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST298 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUALS);
	_t = _t->getFirstChild();
	i = _t;
	i_AST = astFactory.create(i);
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(_t,IDENT);
	_t = _t->getNextSibling();
	temp=expression(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST298;
	_t = __t298;
	_t = _t->getNextSibling();
#line 1540 "walker.g"
	
	
	//			ast = Absyn__NAMEDARG(to_rml_str(i),temp);
			
#line 7482 "flat_modelica_tree_parser.cpp"
	named_argument_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = named_argument_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::named_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1523 "walker.g"
	void* ast;
#line 7492 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1523 "walker.g"
	
		void* n;
	
#line 7501 "flat_modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t293 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp95_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp95_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp95_AST = astFactory.create(_t);
	tmp95_AST_in = _t;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp95_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST293 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,NAMED_ARGUMENTS);
	_t = _t->getFirstChild();
	{
	n=named_argument(_t);
	_t = _retTree;
	astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1528 "walker.g"
	/*el_stack.push(n); */
#line 7520 "flat_modelica_tree_parser.cpp"
	}
	{
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType()==EQUALS)) {
			n=named_argument(_t);
			_t = _retTree;
			astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1528 "walker.g"
			/*el_stack.push(n); */
#line 7532 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop296;
		}
		
	}
	_loop296:;
	}
	currentAST = __currentAST293;
	_t = __t293;
	_t = _t->getNextSibling();
#line 1529 "walker.g"
	
	//			ast = make_rml_list_from_stack(el_stack);
			
#line 7548 "flat_modelica_tree_parser.cpp"
	named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = named_arguments_AST;
	_retTree = _t;
	return ast;
}

void*  flat_modelica_tree_parser::subscript(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1605 "walker.g"
	void* ast;
#line 7558 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST subscript_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST subscript_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1605 "walker.g"
	
		void* e;
	
#line 7569 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case END:
	case FALSE:
	case IF:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case RANGE2:
	case RANGE3:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		e=expression(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1612 "walker.g"
		
		//ast = Absyn__SUBSCRIPT(e);
					
#line 7615 "flat_modelica_tree_parser.cpp"
		break;
	}
	case COLON:
	{
		c = _t;
		c_AST = astFactory.create(c);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
		match(_t,COLON);
		_t = _t->getNextSibling();
#line 1616 "walker.g"
		
					//	ast = Absyn__NOSUB;
					
#line 7629 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	subscript_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
	returnAST = subscript_AST;
	_retTree = _t;
	return ast;
}

void *  flat_modelica_tree_parser::string_concatenation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1652 "walker.g"
	void * ast;
#line 7647 "flat_modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST string_concatenation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST string_concatenation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING:
	{
#line 1653 "walker.g"
		
					ast = 0;
				
#line 7668 "flat_modelica_tree_parser.cpp"
		s = _t;
		s_AST = astFactory.create(s);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s_AST));
		match(_t,STRING);
		_t = _t->getNextSibling();
#line 1656 "walker.g"
		
			  		//ast = to_rml_str(s);
				
#line 7678 "flat_modelica_tree_parser.cpp"
		string_concatenation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	case PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t321 = _t;
		p = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		p_AST = astFactory.create(p);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST321 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,PLUS);
		_t = _t->getFirstChild();
		ast=string_concatenation(_t);
		_t = _retTree;
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		s2 = _t;
		s2_AST = astFactory.create(s2);
		astFactory.addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s2_AST));
		match(_t,STRING);
		_t = _t->getNextSibling();
		currentAST = __currentAST321;
		_t = __t321;
		_t = _t->getNextSibling();
#line 1660 "walker.g"
		
					//ast = to_rml_str(s2);
				
#line 7708 "flat_modelica_tree_parser.cpp"
		string_concatenation_AST = ANTLR_USE_NAMESPACE(antlr)RefAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = string_concatenation_AST;
	_retTree = _t;
	return ast;
}

const char* flat_modelica_tree_parser::_tokenNames[] = {
	"<0>",
	"EOF",
	"<2>",
	"NULL_TREE_LOOKAHEAD",
	"\"algorithm\"",
	"\"and\"",
	"\"annotation\"",
	"\"block\"",
	"\"boundary\"",
	"\"class\"",
	"\"connect\"",
	"\"connector\"",
	"\"constant\"",
	"\"discrete\"",
	"\"each\"",
	"\"else\"",
	"\"elseif\"",
	"\"elsewhen\"",
	"\"end\"",
	"\"enumeration\"",
	"\"equation\"",
	"\"encapsulated\"",
	"\"extends\"",
	"\"external\"",
	"\"false\"",
	"\"final\"",
	"\"flow\"",
	"\"for\"",
	"\"function\"",
	"\"if\"",
	"\"import\"",
	"\"in\"",
	"\"initial\"",
	"\"inner\"",
	"\"input\"",
	"\"loop\"",
	"\"model\"",
	"\"not\"",
	"\"outer\"",
	"\"or\"",
	"\"output\"",
	"\"package\"",
	"\"parameter\"",
	"\"partial\"",
	"\"protected\"",
	"\"public\"",
	"\"record\"",
	"\"redeclare\"",
	"\"replaceable\"",
	"\"results\"",
	"\"then\"",
	"\"true\"",
	"\"type\"",
	"\"unsigned_real\"",
	"\"when\"",
	"\"while\"",
	"\"within\"",
	"LPAR",
	"RPAR",
	"LBRACK",
	"RBRACK",
	"LBRACE",
	"RBRACE",
	"EQUALS",
	"ASSIGN",
	"PLUS",
	"MINUS",
	"STAR",
	"SLASH",
	"DOT",
	"COMMA",
	"LESS",
	"LESSEQ",
	"GREATER",
	"GREATEREQ",
	"EQEQ",
	"LESSGT",
	"COLON",
	"SEMICOLON",
	"POWER",
	"WS",
	"ML_COMMENT",
	"ML_COMMENT_CHAR",
	"SL_COMMENT",
	"IDENT",
	"NONDIGIT",
	"DIGIT",
	"EXPONENT",
	"UNSIGNED_INTEGER",
	"STRING",
	"SCHAR",
	"SESCAPE",
	"ESC",
	"ALGORITHM_STATEMENT",
	"ARGUMENT_LIST",
	"CLASS_DEFINITION",
	"CLASS_MODIFICATION",
	"COMMENT",
	"DECLARATION",
	"DEFINITION",
	"ENUMERATION_LITERAL",
	"ELEMENT",
	"ELEMENT_MODIFICATION",
	"ELEMENT_REDECLARATION",
	"EQUATION_STATEMENT",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"EXPRESSION_LIST",
	"EXTERNAL_FUNCTION_CALL",
	"FOR_INDICES",
	"FUNCTION_CALL",
	"INITIAL_FUNCTION_CALL",
	"FUNCTION_ARGUMENTS",
	"NAMED_ARGUMENTS",
	"QUALIFIED",
	"RANGE2",
	"RANGE3",
	"STORED_DEFINITION",
	"STRING_COMMENT",
	"UNARY_MINUS",
	"UNARY_PLUS",
	"UNQUALIFIED",
	0
};

const unsigned long flat_modelica_tree_parser::_tokenSet_0_data_[] = { 1048592UL, 12288UL, 0UL, 1536UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "equation" "protected" "public" INITIAL_EQUATION INITIAL_ALGORITHM 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_tree_parser::_tokenSet_0(_tokenSet_0_data_,8);
const unsigned long flat_modelica_tree_parser::_tokenSet_1_data_[] = { 553910304UL, 707264672UL, 51429310UL, 26787840UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "not" "or" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING FUNCTION_CALL INITIAL_FUNCTION_CALL 
// RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_tree_parser::_tokenSet_1(_tokenSet_1_data_,8);
const unsigned long flat_modelica_tree_parser::_tokenSet_2_data_[] = { 553910304UL, 707264672UL, 51421118UL, 26787840UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "not" "or" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT POWER IDENT UNSIGNED_INTEGER STRING FUNCTION_CALL INITIAL_FUNCTION_CALL 
// RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_tree_parser::_tokenSet_2(_tokenSet_2_data_,8);


