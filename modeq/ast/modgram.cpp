/*
 * A n t l r  T r a n s l a t i o n  H e a d e r
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-1994
 * Purdue University Electrical Engineering
 * With AHPCRC, University of Minnesota
 * ANTLR Version 1.33
 */
#include <stdio.h>
#define ANTLR_VERSION	133
#include "tokens.h"


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

  
#include "ASTBase.h"

#include "AParser.h"
#include "ModParse.h"
#include "DLexerBase.h"
#include "ATokPtr.h"
#ifndef PURIFY
#define PURIFY(r,s)
#endif


#include <stdlib.h>		// getopt
#include <iostream.h>
#include <fstream.h>
#include "DLexerBase.h"		// Base info for DLG-generated scanner
#include "DLGLexer.h"
#include "AToken.h"		// Base token definitions for ANTLR

#include "rml.h"
// #include "codegen.h"
#include "dae.h"
#include "exp.h"
#include "class.h"

static int errors=0;

static char *filename=NULL;
static char *outputfilename=NULL;

int main(int argc, char **argv)
{
	
#ifdef _WIN32
	__progname = argv[0];
#endif
	
    bool nocode=false;
	bool dump=false;
	bool noprint=true;
	bool showcom=false;
	bool verbosemode=false;
	
    FILE *source;
	ofstream code;
	
    int c;
	extern char *optarg;
	extern int optind;
	int errflg = 0;
	
    // Initialize RML
	Exp_5finit();
	DAE_5finit();
	Class_5finit();
	
    while ((c = getopt(argc, argv, "svxdr:o:D")) != EOF)
	switch (c) {
		case 'v':
		verbosemode=true;
		break;
		case 'd':
		noprint=false;
		break;
		case 'D':
		dump=true;
		break;
		case 'o':
		outputfilename = optarg;
		//	cout << "ofile = " << ofile << "\n";
		break;
		case 'r':
		rootcontextname=optarg;
		//	cout << "context = " << rootcontextname << "\n";
		break;
		case '?':
		errflg++;
	}
	if (errflg) {
		cerr << "usage: mod2om5 [-v] [-x] [-d] [-D] [-r <contextname>] [-o <filename>] file\n";
		exit (2);
	}
	
    filename=argv[optind];
	if (!rootcontextname) {
		if (filename) {
			// get root context name from filename
			char *p;
			rootcontextname=strdup(filename);
			// Strip everything after the first dot
			if (p=strchr(rootcontextname,'.'))
			*p=0;
		} else
		rootcontextname="rootContext";
	}
	
    if (verbosemode) {
		cout << "Root context name: " << rootcontextname << "\n";
		cout << "Input filename: " << ( filename? filename : "stdin" ) << "\n";
		cout << "Output filename: " << ( outputfilename? outputfilename : "stdout" ) << "\n";
	}
	
    if (filename) {
		source=fopen(filename,"r");
	} else {
		source=stdin;
	}
	
    // Declare the parser objects
	DLGFileInput in(source);          // define the input file; in this case, source
	DLGLexer scanner(&in);           // define an instance of your scanner
	ANTLRTokenBuffer pipe(&scanner); // define a token buffer between scanner and parser
	ANTLRToken tok;                  // create a token to use as a model
	ASTBase *root=NULL;
	AST *rootCopy;
	CodeGenerator codeGen;
	ModParse parser(&pipe);        // create an instance of your parser
	
    scanner.setToken(&tok);          // tell the scanner what type the token is
	
    parser.init();                 // initialize your parser
	parser.model_specification(&root);              // start first rule
	
    if (filename) fclose(source);
	
    rootCopy=(AST *) root;
	if (!noprint) {
		printf("Dump of tree:\n");
		rootCopy->preorder();
		printf("\n\n");
	}
	if (dump) {
		printf("Dump of tree:\n");
		rootCopy->dumpTree();
	}
	if (!nocode) {
		codeGen.genCode(rootCopy);
	} else {
		cout << "Syntax check complete.\n";
	}
	if (showcom) {
		newComment=getFirstComment();
		while(newComment) {
			cout << "Comment at line: " << newComment->getLine() << "\n";
			cout << newComment->getText() << "\n";
			newComment=newComment->getNext();
		}
	}
	rootCopy->destroy();
	//    fprintf(stderr,"%d errors.\n",errors);
	return 0;                        // it's over Johnnie... it's over
}



void
ModParse::model_specification(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t12=NULL;
	AST *_ast12=NULL;
	ANTLRTokenPtr cl=NULL;
	AST *cl_ast=NULL;
	{
		ANTLRTokenPtr _t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		int zzcnt=1;
		do {
			if ( (setwd1[LA(1)]&0x1) ) {
				_ast = NULL;
				class_definition(&_ast, false,false );
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
				cl_ast = _ast21;
				zzmatch(77);				
				if ( !guessing ) {
				 _t22 = (ANTLRTokenPtr)LT(1);
				}

				  consume();
			}
			else {
				if ( (LA(1)==IMPORT) ) {
					_ast = NULL;
					import_statement(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
				}
				else if ( zzcnt>1 ) break; /* implied exit branch */
				else {FAIL(1,err1,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
			zzcnt++;
		} while ( 1 );
	}
	zzmatch(1);	
	if ( !guessing ) {
	 _t12 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd1, 0x2);
}

void
ModParse::import_statement(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t12=NULL,_t13=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	ANTLRTokenPtr im=NULL;
	AST *im_ast=NULL;
	zzmatch(IMPORT);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		im = _t11;
	im_ast = _ast11;
}
	 consume();
	zzmatch(STRING);	
	if ( !guessing ) {
	 _t12 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast12 = new AST(_t12);
	_ast12->subchild(_root, &_sibling, &_tail);
	}
	 consume();
	zzmatch(77);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	 
	if ( !guessing ) {
	im_ast->ni.type=IMPORT_STATEMENT;   
	}
 consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd1, 0x4);
}

void
ModParse::class_definition(ASTBase **_root, bool is_virtual,bool is_final )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t13=NULL;
	AST *_ast13=NULL,*_ast14=NULL;
	ANTLRTokenPtr id=NULL;
	AST *id_ast=NULL;
	bool is_ext=false,is_external=false,is_fun=false, is_type=false,is_partial=false; char *classType;   
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==PARTIAL) ) {
			zzmatch(PARTIAL);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			is_partial=true;   
			}
 consume();
		}
	}
	{
		ANTLRTokenPtr _t21=NULL,_t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (LA(1)==CLASS_) ) {
			zzmatch(CLASS_);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			classType="Class";   
			}
 consume();
		}
		else {
			if ( (LA(1)==MODEL) ) {
				zzmatch(MODEL);				
				if ( !guessing ) {
				 _t21 = (ANTLRTokenPtr)LT(1);
				}

				 
				if ( !guessing ) {
				classType="Model";   
				}
 consume();
			}
			else {
				if ( (LA(1)==RECORD) ) {
					zzmatch(RECORD);					
					if ( !guessing ) {
					 _t21 = (ANTLRTokenPtr)LT(1);
					}

					 
					if ( !guessing ) {
					classType="RecordType";   
					}
 consume();
				}
				else {
					if ( (LA(1)==BLOCK) ) {
						zzmatch(BLOCK);						
						if ( !guessing ) {
						 _t21 = (ANTLRTokenPtr)LT(1);
						}

						 
						if ( !guessing ) {
						classType="BlockClass";   
						}
 consume();
					}
					else {
						if ( (LA(1)==CONNECTOR) ) {
							zzmatch(CONNECTOR);							
							if ( !guessing ) {
							 _t21 = (ANTLRTokenPtr)LT(1);
							}

							 
							if ( !guessing ) {
							classType="Connector";   
							}
 consume();
						}
						else {
							if ( (LA(1)==TYPE) ) {
								zzmatch(TYPE);								
								if ( !guessing ) {
								 _t21 = (ANTLRTokenPtr)LT(1);
								}

								 
								if ( !guessing ) {
								classType="Type"; is_type=true;   
								}
 consume();
							}
							else {
								if ( (LA(1)==PACKAGE) ) {
									zzmatch(PACKAGE);									
									if ( !guessing ) {
									 _t21 = (ANTLRTokenPtr)LT(1);
									}

									 
									if ( !guessing ) {
									classType="Package";   
									}
 consume();
								}
								else {
									if ( (setwd1[LA(1)]&0x8) ) {
										{
											ANTLRTokenPtr _t31=NULL;
											AST *_ast31=NULL;
											if ( (LA(1)==EXTERNAL) ) {
												zzmatch(EXTERNAL);												
												if ( !guessing ) {
												 _t31 = (ANTLRTokenPtr)LT(1);
												}

												 
												if ( !guessing ) {
												is_external=true;   
												}
 consume();
											}
										}
										zzmatch(FUNCTION);										
										if ( !guessing ) {
										 _t22 = (ANTLRTokenPtr)LT(1);
										}

										 
										if ( !guessing ) {
										is_fun=true;   
										}
 consume();
									}
									else {FAIL(1,err2,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
								}
							}
						}
					}
				}
			}
		}
	}
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast13 = new AST(_t13);
	_ast13->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		id = _t13;
	id_ast = _ast13;
}
	 consume();
	_ast = NULL;
	comment(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast14 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL,_t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (setwd1[LA(1)]&0x10) ) {
			_ast = NULL;
			composition(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(END);			
			if ( !guessing ) {
			 _t22 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			{
				ANTLRTokenPtr _t31=NULL;
				AST *_ast31=NULL;
				if ( (LA(1)==IDENT) ) {
					zzmatch(IDENT);					
					if ( !guessing ) {
					 _t31 = (ANTLRTokenPtr)LT(1);
					}

					  consume();
				}
			}
		}
		else {
			if ( (LA(1)==64) ) {
				zzmatch(64);				
				if ( !guessing ) {
				 _t21 = (ANTLRTokenPtr)LT(1);
				}

				 
				if ( !guessing ) {
				is_ext=true;   
				}
 consume();
				zzmatch(IDENT);				
				if ( !guessing ) {
				 _t22 = (ANTLRTokenPtr)LT(1);
				}

				if ( !guessing ) {
				
				_ast22 = new AST(_t22);
				_ast22->subchild(_root, &_sibling, &_tail);
				}
				 consume();
				{
					AST *_ast31=NULL;
					if ( (LA(1)==LBRACK) ) {
						_ast = NULL;
						array_decl(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast31 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
				}
				{
					AST *_ast31=NULL;
					if ( (LA(1)==LPAR) ) {
						_ast = NULL;
						class_specialization(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast31 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
				}
			}
			else {FAIL(1,err3,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
	}
	if ( !guessing ) {
	if (is_ext) {
		id_ast->ni.type=ET_EXTCLASS;
	} else if (is_fun) {
		id_ast->ni.type=ET_FUNCTION;
	} else {
		id_ast->ni.type=CLASSDEF;
	}
	id_ast->classType=classType;
	// #id->classType="Class";
	if (is_virtual)  id_ast->ni.properties |= CLASS_VIRTUAL;
	if (is_final)    id_ast->ni.properties |= IS_FINAL;
	if (is_partial)  id_ast->ni.properties |= CLASS_PARTIAL;
	if (is_external) id_ast->ni.properties |= FUNCTION_EXTERNAL;
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd1, 0x20);
}

void
ModParse::composition(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	default_public(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		AST *_ast21=NULL;
		while ( 1 ) {
			if ( !((setwd1[LA(1)]&0x40))) break;
			if ( (LA(1)==PUBLIC) ) {
				_ast = NULL;
				public_elements(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
			else {
				if ( (LA(1)==PROTECTED) ) {
					_ast = NULL;
					protected_elements(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
				}
				else {
					if ( (LA(1)==EQUATION) ) {
						_ast = NULL;
						equation_clause(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast21 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
					else {
						if ( (LA(1)==ALGORITHM) ) {
							_ast = NULL;
							algorithm_clause(&_ast);
							if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
							_ast21 = (AST *)_ast;
							ASTBase::link(_root, &_sibling, &_tail);
						}
					}
				}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd1, 0x80);
}

void
ModParse::default_public(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr el=NULL;
	AST *el_ast=NULL;
	_ast = NULL;
	element_list(&_ast, false );
	_ast11 = (AST *)_ast;
	el_ast = _ast11;
	if ( !guessing ) {
	(*_root)=ASTBase::tmake((new AST(EXTRA_TOKEN)),el_ast, NULL);   
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd2, 0x1);
}

void
ModParse::public_elements(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	zzmatch(PUBLIC);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	 consume();
	_ast = NULL;
	element_list(&_ast, false );
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd2, 0x2);
}

void
ModParse::protected_elements(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	zzmatch(PROTECTED);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	 consume();
	_ast = NULL;
	element_list(&_ast, true );
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd2, 0x4);
}

void
ModParse::element_list(ASTBase **_root, bool is_protected )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
;
	ANTLRTokenPtr el=NULL;
	AST *el_ast=NULL;
	{
		ANTLRTokenPtr _t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( 1 ) {
			if ( !((setwd2[LA(1)]&0x8))) break;
			if ( (setwd2[LA(1)]&0x10) ) {
				_ast = NULL;
				element(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
				el_ast = _ast21;
				zzmatch(77);				
				if ( !guessing ) {
				 _t22 = (ANTLRTokenPtr)LT(1);
				}

				 
				if ( !guessing ) {
				if (is_protected) el_ast->ni.properties |= ELEMENT_PROTECTED;   
				}
 consume();
			}
			else {
				if ( (LA(1)==ANNOTATION) ) {
					_ast = NULL;
					annotation(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
					zzmatch(77);					
					if ( !guessing ) {
					 _t22 = (ANTLRTokenPtr)LT(1);
					}

					  consume();
				}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd2, 0x20);
}

void
ModParse::element(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
;
	bool is_virtual=false; bool is_final=false;   
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==FINAL) ) {
			zzmatch(FINAL);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			is_final=true;   
			}
 consume();
		}
	}
	{
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (setwd2[LA(1)]&0x40) ) {
			{
				ANTLRTokenPtr _t31=NULL;
				AST *_ast31=NULL;
				if ( (LA(1)==VIRTUAL) ) {
					zzmatch(VIRTUAL);					
					if ( !guessing ) {
					 _t31 = (ANTLRTokenPtr)LT(1);
					}

					 
					if ( !guessing ) {
					is_virtual=true;   
					}
 consume();
				}
			}
			_ast = NULL;
			class_definition(&_ast, is_virtual,is_final );
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
		else {
			if ( (LA(1)==EXTENDS) ) {
				_ast = NULL;
				extends_clause(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
			else {
				if ( (setwd2[LA(1)]&0x80) ) {
					_ast = NULL;
					component_clause(&_ast, ET_COMPONENT );
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
				}
				else {FAIL(1,err4,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x1);
}

void
ModParse::extends_clause(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t12=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	ANTLRTokenPtr i=NULL;
	AST *i_ast=NULL;
	zzmatch(EXTENDS);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t12 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast12 = new AST(_t12);
	_ast12->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		i = _t12;
	i_ast = _ast12;
}
	
	if ( !guessing ) {
	i_ast->ni.type=ET_INHERIT;   
	}
 consume();
	{
		AST *_ast21=NULL;
		if ( (LA(1)==LPAR) ) {
			_ast = NULL;
			class_specialization(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x2);
}

void
ModParse::component_clause(ASTBase **_root, NodeType nt )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	ANTLRTokenPtr p=NULL, t=NULL, c=NULL;
	AST *p_ast=NULL, *t_ast=NULL, *c_ast=NULL;
	_ast = NULL;
	type_prefix(&_ast);
	_ast11 = (AST *)_ast;
	p_ast = _ast11;
	_ast = NULL;
	type_specifier(&_ast);
	_ast12 = (AST *)_ast;
	t_ast = _ast12;
	if ( !guessing ) {
	t_ast->ni.type=nt;   
	}
	_ast = NULL;
	component_list(&_ast, NO_SPECIAL );
	_ast13 = (AST *)_ast;
	c_ast = _ast13;
	if ( !guessing ) {
	(*_root)=ASTBase::tmake(t_ast,ASTBase::tmake((new AST(EXTRA_TOKEN)),p_ast, NULL),c_ast, NULL);   
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x4);
}

void
ModParse::type_prefix(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
;
	ANTLRTokenPtr f1=NULL, f2=NULL, f3=NULL, f4=NULL, f5=NULL;
	AST *f1_ast=NULL, *f2_ast=NULL, *f3_ast=NULL, *f4_ast=NULL, *f5_ast=NULL;
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==FLOW) ) {
			zzmatch(FLOW);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subchild(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						f1 = _t21;
			f1_ast = _ast21;
}
			
			if ( !guessing ) {
			f1_ast->setTranslation("Flow ");   
			}
 consume();
		}
	}
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==PARAMETER) ) {
			zzmatch(PARAMETER);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subchild(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						f2 = _t21;
			f2_ast = _ast21;
}
			
			if ( !guessing ) {
			f2_ast->setTranslation("Parameter ");   
			}
 consume();
		}
		else {
			if ( (LA(1)==CONSTANT) ) {
				zzmatch(CONSTANT);				
				if ( !guessing ) {
				 _t21 = (ANTLRTokenPtr)LT(1);
				}

				if ( !guessing ) {
				
				_ast21 = new AST(_t21);
				_ast21->subchild(_root, &_sibling, &_tail);
				}
				
				if ( !guessing ) {
								f3 = _t21;
				f3_ast = _ast21;
}
				
				if ( !guessing ) {
				f3_ast->setTranslation("Constant ");   
				}
 consume();
			}
		}
	}
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==INPUT) ) {
			zzmatch(INPUT);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subchild(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						f4 = _t21;
			f4_ast = _ast21;
}
			
			if ( !guessing ) {
			f4_ast->setTranslation("Input ");   
			}
 consume();
		}
		else {
			if ( (LA(1)==OUTPUT) ) {
				zzmatch(OUTPUT);				
				if ( !guessing ) {
				 _t21 = (ANTLRTokenPtr)LT(1);
				}

				if ( !guessing ) {
				
				_ast21 = new AST(_t21);
				_ast21->subchild(_root, &_sibling, &_tail);
				}
				
				if ( !guessing ) {
								f5 = _t21;
				f5_ast = _ast21;
}
				
				if ( !guessing ) {
				f5_ast->setTranslation("Output ");   
				}
 consume();
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x8);
}

void
ModParse::type_specifier(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	name_path(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x10);
}

void
ModParse::component_list(ASTBase **_root, NodeType nt )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	component_declaration(&_ast, nt );
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==78) ) {
			zzmatch(78);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			component_declaration(&_ast, nt );
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x20);
}

void
ModParse::component_declaration(ASTBase **_root, NodeType nt )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	_ast = NULL;
	declaration(&_ast, nt );
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	_ast = NULL;
	comment(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd3, 0x40);
}

void
ModParse::declaration(ASTBase **_root, NodeType nt )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr i=NULL;
	AST *i_ast=NULL;
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		i = _t11;
	i_ast = _ast11;
}
	
	if ( !guessing ) {
	i_ast->ni.type=nt;   
	}
 consume();
	{
		AST *_ast21=NULL;
		if ( (LA(1)==LBRACK) ) {
			_ast = NULL;
			array_decl(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	{
		AST *_ast21=NULL;
		if ( (setwd3[LA(1)]&0x80) ) {
			_ast = NULL;
			specialization(&_ast, "=" );
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd4, 0x1);
}

void
ModParse::array_decl(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	ANTLRTokenPtr brak=NULL;
	AST *brak_ast=NULL;
	zzmatch(LBRACK);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		brak = _t11;
	brak_ast = _ast11;
}
	 consume();
	_ast = NULL;
	subscript_list(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	zzmatch(RBRACK);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	 
	if ( !guessing ) {
	brak_ast->setOpType(OP_ARRAYDECL);   
	}
 consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd4, 0x2);
}

void
ModParse::subscript_list(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	subscript(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==78) ) {
			zzmatch(78);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subchild(_root, &_sibling, &_tail);
			}
			 consume();
			_ast = NULL;
			subscript(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd4, 0x4);
}

void
ModParse::subscript(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	ANTLRTokenPtr ex1=NULL, ex2=NULL, ex3=NULL, ex4=NULL;
	AST *ex1_ast=NULL, *ex2_ast=NULL, *ex3_ast=NULL, *ex4_ast=NULL;
	zzGUESS_BLOCK
	zzGUESS
	if ( !zzrv && (setwd4[LA(1)]&0x8) ) {
		{
			ANTLRTokenPtr _t22=NULL;
			AST *_ast21=NULL,*_ast22=NULL;
			_ast = NULL;
			expression(&_ast);
			_ast21 = (AST *)_ast;
			zzmatch(79);			
			if ( !guessing ) {
			 _t22 = (ANTLRTokenPtr)LT(1);
			}

			 consume();
		}
		zzGUESS_DONE
		_ast = NULL;
		expression(&_ast);
		_ast12 = (AST *)_ast;
		ex1_ast = _ast12;
		zzmatch(79);		
		if ( !guessing ) {
		 _t13 = (ANTLRTokenPtr)LT(1);
		}

		 consume();
		{
			AST *_ast21=NULL;
			if ( (setwd4[LA(1)]&0x10) ) {
				_ast = NULL;
				expression(&_ast);
				_ast21 = (AST *)_ast;
				ex2_ast = _ast21;
			}
		}
		if ( !guessing ) {
		
		// if ex2 was parsed, build a [n:m] treee
		if (ex2_ast) (*_root)=ASTBase::tmake(0,ex1_ast,(new AST(EXTRA_TOKEN,"|")),ex2_ast, NULL);
		// else build a [n:] tree
		else (*_root)=ASTBase::tmake(0,ex1_ast,(new AST(EXTRA_TOKEN,"|")),(new AST(EXTRA_TOKEN,"_")), NULL);
		}
	}
	else {
		if ( !zzrv ) zzGUESS_DONE;
		if ( (LA(1)==79) ) {
			zzmatch(79);			
			if ( !guessing ) {
			 _t11 = (ANTLRTokenPtr)LT(1);
			}

			 consume();
			{
				AST *_ast21=NULL;
				if ( (setwd4[LA(1)]&0x20) ) {
					_ast = NULL;
					expression(&_ast);
					_ast21 = (AST *)_ast;
					ex3_ast = _ast21;
				}
			}
			if ( !guessing ) {
			
			if (ex3_ast) {
				// if ex3 was parsed, build a [:m] tree
				(*_root)=ASTBase::tmake(0,(new AST(EXTRA_TOKEN,"1")),(new AST(EXTRA_TOKEN,"|")),ex3_ast, NULL);
			} else {
				// else build a [:] tree
				(*_root)=ASTBase::tmake(0,(new AST(EXTRA_TOKEN,"_")), NULL);
			}
			}
		}
		else {
			if ( !zzrv ) zzGUESS_DONE;
			if ( (setwd4[LA(1)]&0x40) ) {
				_ast = NULL;
				expression(&_ast);
				_ast11 = (AST *)_ast;
				ex4_ast = _ast11;
				if ( !guessing ) {
				
				// single expression; build [n] tree
				(*_root)=ASTBase::tmake(0,ex4_ast, NULL);
				}
			}
			else {FAIL(1,err5,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd4, 0x80);
}

void
ModParse::specialization(ASTBase **_root, char *tr )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	ANTLRTokenPtr eq=NULL;
	AST *eq_ast=NULL;
	if ( (LA(1)==LPAR) ) {
		_ast = NULL;
		class_specialization(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast11 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
		{
			ANTLRTokenPtr _t21=NULL;
			AST *_ast21=NULL,*_ast22=NULL;
			if ( (LA(1)==64) ) {
				zzmatch(64);				
				if ( !guessing ) {
				 _t21 = (ANTLRTokenPtr)LT(1);
				}

				if ( !guessing ) {
				
				_ast21 = new AST(_t21);
				_ast21->subchild(_root, &_sibling, &_tail);
				}
				 consume();
				_ast = NULL;
				expression(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast22 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
		}
	}
	else {
		if ( (LA(1)==64) ) {
			zzmatch(64);			
			if ( !guessing ) {
			 _t11 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast11 = new AST(_t11);
			_ast11->subchild(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						eq = _t11;
			eq_ast = _ast11;
}
			 consume();
			_ast = NULL;
			expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast12 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			if ( !guessing ) {
			eq_ast->setTranslation(tr);   
			}
		}
		else {FAIL(1,err6,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd5, 0x1);
}

void
ModParse::class_specialization(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	zzmatch(LPAR);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	 consume();
	_ast = NULL;
	argument_list(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	zzmatch(RPAR);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd5, 0x2);
}

void
ModParse::argument_list(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	argument(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==78) ) {
			zzmatch(78);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			argument(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd5, 0x4);
}

void
ModParse::argument(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	if ( (setwd5[LA(1)]&0x8) ) {
		_ast = NULL;
		element_modification(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast11 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
	}
	else {
		if ( (LA(1)==REDECLARE) ) {
			_ast = NULL;
			element_redeclaration(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast11 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
		else {FAIL(1,err7,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd5, 0x10);
}

void
ModParse::element_modification(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t12=NULL;
	AST *_ast12=NULL,*_ast14=NULL;
	ANTLRTokenPtr id=NULL;
	AST *id_ast=NULL;
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==FINAL) ) {
			zzmatch(FINAL);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subchild(_root, &_sibling, &_tail);
			}
			 consume();
		}
	}
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t12 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast12 = new AST(_t12);
	_ast12->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		id = _t12;
	id_ast = _ast12;
}
	
	if ( !guessing ) {
	id_ast->ni.type=ELEMENT_MOD;   
	}
 consume();
	{
		AST *_ast21=NULL;
		if ( (LA(1)==LBRACK) ) {
			_ast = NULL;
			array_decl(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	_ast = NULL;
	specialization(&_ast, "->" );
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast14 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd5, 0x20);
}

void
ModParse::element_redeclaration(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	bool is_final=false;   
	zzmatch(REDECLARE);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==FINAL) ) {
			zzmatch(FINAL);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			is_final=true;   
			}
 consume();
		}
	}
	{
		AST *_ast21=NULL;
		if ( (LA(1)==EXTENDS) ) {
			_ast = NULL;
			extends_clause(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
		else {
			if ( (setwd5[LA(1)]&0x40) ) {
				_ast = NULL;
				class_definition(&_ast, false,is_final );
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
			else {
				if ( (setwd5[LA(1)]&0x80) ) {
					_ast = NULL;
					component_clause1(&_ast, ET_COMPONENT );
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
				}
				else {FAIL(1,err8,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd6, 0x1);
}

void
ModParse::component_clause1(ASTBase **_root, NodeType nt )
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	ANTLRTokenPtr p=NULL, t=NULL, c=NULL;
	AST *p_ast=NULL, *t_ast=NULL, *c_ast=NULL;
	_ast = NULL;
	type_prefix(&_ast);
	_ast11 = (AST *)_ast;
	p_ast = _ast11;
	_ast = NULL;
	type_specifier(&_ast);
	_ast12 = (AST *)_ast;
	t_ast = _ast12;
	if ( !guessing ) {
	t_ast->ni.type=nt;   
	}
	_ast = NULL;
	component_declaration(&_ast, ET_COMPONENT );
	_ast13 = (AST *)_ast;
	c_ast = _ast13;
	if ( !guessing ) {
	(*_root)=ASTBase::tmake(t_ast,ASTBase::tmake((new AST(EXTRA_TOKEN)),p_ast, NULL),c_ast, NULL);   
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd6, 0x2);
}

void
ModParse::equation_clause(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr eq=NULL, an=NULL;
	AST *eq_ast=NULL, *an_ast=NULL;
	zzmatch(EQUATION);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	 consume();
	{
		ANTLRTokenPtr _t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( 1 ) {
			if ( !((setwd6[LA(1)]&0x4))) break;
			if ( (setwd6[LA(1)]&0x8) ) {
				_ast = NULL;
				equation(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
				eq_ast = _ast21;
				zzmatch(77);				
				if ( !guessing ) {
				 _t22 = (ANTLRTokenPtr)LT(1);
				}

				 
				if ( !guessing ) {
				eq_ast->ni.type=ET_EQUATION;   
				}
 consume();
			}
			else {
				if ( (LA(1)==ANNOTATION) ) {
					_ast = NULL;
					annotation(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
					an_ast = _ast21;
					zzmatch(77);					
					if ( !guessing ) {
					 _t22 = (ANTLRTokenPtr)LT(1);
					}

					 
					if ( !guessing ) {
					an_ast->ni.type=ET_ANNOTATION;   
					}
 consume();
				}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd6, 0x10);
}

void
ModParse::algorithm_clause(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr eq=NULL, an=NULL;
	AST *eq_ast=NULL, *an_ast=NULL;
	zzmatch(ALGORITHM);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	 consume();
	{
		ANTLRTokenPtr _t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( 1 ) {
			if ( !((setwd6[LA(1)]&0x20))) break;
			if ( (setwd6[LA(1)]&0x40) ) {
				_ast = NULL;
				equation(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
				eq_ast = _ast21;
				zzmatch(77);				
				if ( !guessing ) {
				 _t22 = (ANTLRTokenPtr)LT(1);
				}

				 
				if ( !guessing ) {
				eq_ast->ni.type=ET_ALGORITHM;   
				}
 consume();
			}
			else {
				if ( (LA(1)==ANNOTATION) ) {
					_ast = NULL;
					annotation(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
					an_ast = _ast21;
					zzmatch(77);					
					if ( !guessing ) {
					 _t22 = (ANTLRTokenPtr)LT(1);
					}

					 
					if ( !guessing ) {
					an_ast->ni.type=ET_ANNOTATION;   
					}
 consume();
				}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd6, 0x80);
}

void
ModParse::equation(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast12=NULL;
	ANTLRTokenPtr op=NULL;
	AST *op_ast=NULL;
	{
		AST *_ast21=NULL;
		if ( (setwd7[LA(1)]&0x1) ) {
			_ast = NULL;
			simple_expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			{
				ANTLRTokenPtr _t31=NULL;
				AST *_ast31=NULL,*_ast32=NULL;
				if ( (setwd7[LA(1)]&0x2) ) {
					zzsetmatch(ASSIGN_set);					
					if ( !guessing ) {
					 _t31 = (ANTLRTokenPtr)LT(1);
					}

					if ( !guessing ) {
					
					_ast31 = new AST(_t31);
					_ast31->subroot(_root, &_sibling, &_tail);
					}
					
					if ( !guessing ) {
										op = _t31;
					op_ast = _ast31;
}
					
					if ( !guessing ) {
					op_ast->setTranslation("==");   
					}
 consume();
					_ast = NULL;
					expression(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast32 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
				}
			}
		}
		else {
			if ( (LA(1)==IF) ) {
				_ast = NULL;
				conditional_equation(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast21 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
			else {
				if ( (LA(1)==FOR) ) {
					_ast = NULL;
					for_clause(&_ast);
					if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
					_ast21 = (AST *)_ast;
					ASTBase::link(_root, &_sibling, &_tail);
				}
				else {
					if ( (LA(1)==WHILE) ) {
						_ast = NULL;
						while_clause(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast21 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
					else {FAIL(1,err10,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
		}
	}
	_ast = NULL;
	comment(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd7, 0x4);
}

void
ModParse::conditional_equation(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL,_t17=NULL,_t18=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL,*_ast14=NULL,*_ast17=NULL,*_ast18=NULL;
	ANTLRTokenPtr i=NULL, el=NULL, el1=NULL, els=NULL, el2=NULL;
	AST *i_ast=NULL, *el_ast=NULL, *el1_ast=NULL, *els_ast=NULL, *el2_ast=NULL;
	bool is_elseif=false; AST *e_ast;  
	zzmatch(IF);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		i = _t11;
	i_ast = _ast11;
}
	 consume();
	_ast = NULL;
	expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	zzmatch(THEN);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	_ast = NULL;
	equation_list(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast14 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	el_ast = _ast14;
	if ( !guessing ) {
	el_ast->setTranslation(";");   
	}
	{
		ANTLRTokenPtr _t21=NULL,_t23=NULL;
		AST *_ast21=NULL,*_ast22=NULL,*_ast23=NULL,*_ast24=NULL;
		while ( (LA(1)==ELSEIF) ) {
			zzmatch(ELSEIF);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			is_elseif=true;   
			}
 consume();
			_ast = NULL;
			expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(THEN);			
			if ( !guessing ) {
			 _t23 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			equation_list(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast24 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			el1_ast = _ast24;
			if ( !guessing ) {
			el1_ast->setTranslation(";");   
			}
		}
	}
	{
		AST *_ast22=NULL;
		if ( (LA(1)==ELSE) ) {
			{
				ANTLRTokenPtr _t31=NULL;
				AST *_ast31=NULL;
				if ( (LA(1)==ELSE)&&(LT(1),is_elseif) ) {
					if (!(LT(1),is_elseif)) {zzfailed_pred("  LT(1),is_elseif");}
					zzmatch(ELSE);					
					if ( !guessing ) {
					 _t31 = (ANTLRTokenPtr)LT(1);
					}

					if ( !guessing ) {
					
					_ast31 = new AST(_t31);
					_ast31->subchild(_root, &_sibling, &_tail);
					}
					
					if ( !guessing ) {
										els = _t31;
					els_ast = _ast31;
}
					
					if ( !guessing ) {
					els_ast->setTranslation("True");   
					}
 consume();
				}
				else {
					if ( (LA(1)==ELSE) ) {
						zzmatch(ELSE);						
						if ( !guessing ) {
						 _t31 = (ANTLRTokenPtr)LT(1);
						}

						  consume();
					}
					else {FAIL(1,err11,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
			_ast = NULL;
			equation_list(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			el2_ast = _ast22;
			if ( !guessing ) {
			el2_ast->setTranslation(";");   
			}
		}
	}
	zzmatch(END);	
	if ( !guessing ) {
	 _t17 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	zzmatch(IF);	
	if ( !guessing ) {
	 _t18 = (ANTLRTokenPtr)LT(1);
	}

	 
	if ( !guessing ) {
	if (is_elseif) {
		i_ast->setOpType(OP_FUNCTION); 
		i_ast->setTranslation("Which");
	} else {
		i_ast->setOpType(OP_FUNCTION); 
		i_ast->setTranslation("If"); 
	}
	}
 consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd7, 0x8);
}

void
ModParse::for_clause(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t12=NULL,_t13=NULL,_t15=NULL,_t18=NULL,_t110=NULL,_t111=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL,*_ast14=NULL,*_ast15=NULL,*_ast16=NULL,*_ast18=NULL,*_ast19=NULL,*_ast110=NULL,*_ast111=NULL;
	ANTLRTokenPtr for_=NULL, id=NULL, e1=NULL, e2=NULL, e3=NULL, el=NULL;
	AST *for__ast=NULL, *id_ast=NULL, *e1_ast=NULL, *e2_ast=NULL, *e3_ast=NULL, *el_ast=NULL;
	zzmatch(FOR);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	
	if ( !guessing ) {
		for_ = _t11;
}
	 consume();
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t12 = (ANTLRTokenPtr)LT(1);
	}

	
	if ( !guessing ) {
		id = _t12;
}
	 consume();
	zzmatch(IN);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	 consume();
	_ast = NULL;
	expression(&_ast);
	_ast14 = (AST *)_ast;
	e1_ast = _ast14;
	zzmatch(79);	
	if ( !guessing ) {
	 _t15 = (ANTLRTokenPtr)LT(1);
	}

	 consume();
	_ast = NULL;
	expression(&_ast);
	_ast16 = (AST *)_ast;
	e2_ast = _ast16;
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (LA(1)==79) ) {
			zzmatch(79);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 consume();
			_ast = NULL;
			expression(&_ast);
			_ast22 = (AST *)_ast;
			e3_ast = _ast22;
		}
	}
	zzmatch(LOOP);	
	if ( !guessing ) {
	 _t18 = (ANTLRTokenPtr)LT(1);
	}

	 consume();
	_ast = NULL;
	equation_list(&_ast);
	_ast19 = (AST *)_ast;
	el_ast = _ast19;
	if ( !guessing ) {
	el_ast->setTranslation(";");   
	}
	zzmatch(END);	
	if ( !guessing ) {
	 _t110 = (ANTLRTokenPtr)LT(1);
	}

	 consume();
	zzmatch(FOR);	
	if ( !guessing ) {
	 _t111 = (ANTLRTokenPtr)LT(1);
	}

	
	if ( !guessing ) {
	for__ast=(new AST(for_));
	for__ast->setOpType(OP_FUNCTION); 
	for__ast->setTranslation("For");
	if (e3_ast) {
		(*_root)=ASTBase::tmake(for__ast,
		ASTBase::tmake((new AST(EXTRA_TOKEN,"=")),(new AST(id)),e1_ast, NULL),
		ASTBase::tmake((new AST(EXTRA_TOKEN,"<=")),(new AST(id)),e2_ast, NULL),
		ASTBase::tmake((new AST(EXTRA_TOKEN,"=")),(new AST(id)),ASTBase::tmake((new AST(EXTRA_TOKEN,"+")),(new AST(id)),e3_ast, NULL), NULL),
		el_ast, NULL);
	} else {
		(*_root)=ASTBase::tmake(for__ast,
		ASTBase::tmake((new AST(EXTRA_TOKEN,"=")),(new AST(id)),e1_ast, NULL),
		ASTBase::tmake((new AST(EXTRA_TOKEN,"<=")),(new AST(id)),e2_ast, NULL),
		ASTBase::tmake((new AST(EXTRA_TOKEN,"++",OP_POSTFIX)),(new AST(id)), NULL),
		el_ast, NULL);
	}	   
	}
 consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd7, 0x10);
}

void
ModParse::while_clause(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL,_t15=NULL,_t16=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL,*_ast14=NULL,*_ast15=NULL,*_ast16=NULL;
	ANTLRTokenPtr while_=NULL, el=NULL;
	AST *while__ast=NULL, *el_ast=NULL;
	zzmatch(WHILE);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		while_ = _t11;
	while__ast = _ast11;
}
	 consume();
	_ast = NULL;
	expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	zzmatch(LOOP);	
	if ( !guessing ) {
	 _t13 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	_ast = NULL;
	equation_list(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast14 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	el_ast = _ast14;
	if ( !guessing ) {
	el_ast->setTranslation(";");   
	}
	zzmatch(END);	
	if ( !guessing ) {
	 _t15 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	zzmatch(WHILE);	
	if ( !guessing ) {
	 _t16 = (ANTLRTokenPtr)LT(1);
	}

	 
	if ( !guessing ) {
	while__ast->setOpType(OP_FUNCTION); 
	while__ast->setTranslation("While");
	}
 consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd7, 0x20);
}

void
ModParse::equation_list(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
;
	{
		ANTLRTokenPtr _t22=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (setwd7[LA(1)]&0x40) ) {
			_ast = NULL;
			equation(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast21 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(77);			
			if ( !guessing ) {
			 _t22 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
		}
	}
	if ( !guessing ) {
	(*_root)=ASTBase::tmake((new AST(EXTRA_TOKEN)),(*_root), NULL);   
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd7, 0x80);
}

void
ModParse::expression(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL,_t15=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL,*_ast14=NULL,*_ast15=NULL,*_ast16=NULL;
	ANTLRTokenPtr ifpart=NULL;
	AST *ifpart_ast=NULL;
	if ( (setwd8[LA(1)]&0x1) ) {
		_ast = NULL;
		simple_expression(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast11 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
	}
	else {
		if ( (LA(1)==IF) ) {
			zzmatch(IF);			
			if ( !guessing ) {
			 _t11 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast11 = new AST(_t11);
			_ast11->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						ifpart = _t11;
			ifpart_ast = _ast11;
}
			
			if ( !guessing ) {
			ifpart_ast->setOpType(OP_FUNCTION); ifpart_ast->setTranslation("If");
			}
 consume();
			_ast = NULL;
			expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast12 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(THEN);			
			if ( !guessing ) {
			 _t13 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			simple_expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast14 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(ELSE);			
			if ( !guessing ) {
			 _t15 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast16 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
		else {FAIL(1,err12,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd8, 0x2);
}

void
ModParse::simple_expression(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr o=NULL;
	AST *o_ast=NULL;
	_ast = NULL;
	logical_term(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==OR) ) {
			zzmatch(OR);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						o = _t21;
			o_ast = _ast21;
}
			 consume();
			_ast = NULL;
			logical_term(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			if ( !guessing ) {
			o_ast->setTranslation("||");   
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd8, 0x4);
}

void
ModParse::logical_term(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr a=NULL;
	AST *a_ast=NULL;
	_ast = NULL;
	logical_factor(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==AND) ) {
			zzmatch(AND);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						a = _t21;
			a_ast = _ast21;
}
			 consume();
			_ast = NULL;
			logical_factor(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			if ( !guessing ) {
			a_ast->setTranslation("&&");   
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd8, 0x8);
}

void
ModParse::logical_factor(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	ANTLRTokenPtr not=NULL;
	AST *not_ast=NULL;
	if ( (LA(1)==NOT) ) {
		zzmatch(NOT);		
		if ( !guessing ) {
		 _t11 = (ANTLRTokenPtr)LT(1);
		}

		if ( !guessing ) {
		
		_ast11 = new AST(_t11);
		_ast11->subroot(_root, &_sibling, &_tail);
		}
		
		if ( !guessing ) {
				not = _t11;
		not_ast = _ast11;
}
		
		if ( !guessing ) {
		not_ast->setOpType(OP_PREFIX); not_ast->setTranslation("!");   
		}
 consume();
		_ast = NULL;
		relation(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast12 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
	}
	else {
		if ( (setwd8[LA(1)]&0x10) ) {
			_ast = NULL;
			relation(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast11 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
		else {FAIL(1,err13,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd8, 0x20);
}

void
ModParse::relation(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr rel=NULL;
	AST *rel_ast=NULL;
	_ast = NULL;
	arithmetic_expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (setwd8[LA(1)]&0x40) ) {
			zzsetmatch(REL_OP_set);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						rel = _t21;
			rel_ast = _ast21;
}
			 consume();
			_ast = NULL;
			arithmetic_expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			if ( !guessing ) {
			if (!strcmp(mytoken( rel)->getText(),"<>")) rel_ast->setTranslation("!=");
			else if (!strcmp(mytoken( rel)->getText(),"==")) rel_ast->setTranslation("===");
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd8, 0x80);
}

void
ModParse::arithmetic_expression(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	unary_arithmetic_expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (setwd9[LA(1)]&0x1) ) {
			zzsetmatch(ADD_OP_set);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			 consume();
			_ast = NULL;
			term(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd9, 0x2);
}

void
ModParse::unary_arithmetic_expression(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	ANTLRTokenPtr plus=NULL, minus=NULL;
	AST *plus_ast=NULL, *minus_ast=NULL;
	if ( (LA(1)==58) ) {
		zzmatch(58);		
		if ( !guessing ) {
		 _t11 = (ANTLRTokenPtr)LT(1);
		}

		if ( !guessing ) {
		
		_ast11 = new AST(_t11);
		_ast11->subroot(_root, &_sibling, &_tail);
		}
		
		if ( !guessing ) {
				plus = _t11;
		plus_ast = _ast11;
}
		 consume();
		_ast = NULL;
		term(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast12 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
		if ( !guessing ) {
		plus_ast->setOpType(OP_PREFIX);   
		}
	}
	else {
		if ( (LA(1)==59) ) {
			zzmatch(59);			
			if ( !guessing ) {
			 _t11 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast11 = new AST(_t11);
			_ast11->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						minus = _t11;
			minus_ast = _ast11;
}
			 consume();
			_ast = NULL;
			term(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast12 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			if ( !guessing ) {
			minus_ast->setOpType(OP_PREFIX);   
			}
		}
		else {
			if ( (setwd9[LA(1)]&0x4) ) {
				_ast = NULL;
				term(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast11 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
			else {FAIL(1,err16,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd9, 0x8);
}

void
ModParse::term(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	factor(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (setwd9[LA(1)]&0x10) ) {
			zzsetmatch(MUL_OP_set);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			 consume();
			_ast = NULL;
			factor(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd9, 0x20);
}

void
ModParse::factor(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t12=NULL,_t14=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL,*_ast14=NULL;
	ANTLRTokenPtr op=NULL;
	AST *op_ast=NULL;
	if ( (setwd9[LA(1)]&0x40) ) {
		_ast = NULL;
		primary(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast11 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
		{
			ANTLRTokenPtr _t21=NULL;
			AST *_ast21=NULL,*_ast22=NULL;
			if ( (LA(1)==80) ) {
				zzmatch(80);				
				if ( !guessing ) {
				 _t21 = (ANTLRTokenPtr)LT(1);
				}

				if ( !guessing ) {
				
				_ast21 = new AST(_t21);
				_ast21->subroot(_root, &_sibling, &_tail);
				}
				 consume();
				_ast = NULL;
				primary(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast22 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
		}
	}
	else {
		if ( (LA(1)==DER) ) {
			zzmatch(DER);			
			if ( !guessing ) {
			 _t11 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast11 = new AST(_t11);
			_ast11->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						op = _t11;
			op_ast = _ast11;
}
			 consume();
			zzmatch(LPAR);			
			if ( !guessing ) {
			 _t12 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			primary(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast13 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(RPAR);			
			if ( !guessing ) {
			 _t14 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			op_ast->setOpType(OP_POSTFIX);
			op_ast->setTranslation("'");
			}
 consume();
		}
		else {FAIL(1,err18,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd9, 0x80);
}

void
ModParse::primary(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t13=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL;
	ANTLRTokenPtr par=NULL, op=NULL, nr=NULL;
	AST *par_ast=NULL, *op_ast=NULL, *nr_ast=NULL;
	zzGUESS_BLOCK
	bool is_matrix;   
	if ( (LA(1)==LPAR) ) {
		zzmatch(LPAR);		
		if ( !guessing ) {
		 _t11 = (ANTLRTokenPtr)LT(1);
		}

		if ( !guessing ) {
		
		_ast11 = new AST(_t11);
		_ast11->subroot(_root, &_sibling, &_tail);
		}
		
		if ( !guessing ) {
				par = _t11;
		par_ast = _ast11;
}
		
		if ( !guessing ) {
		par_ast->setOpType(OP_BALANCED,')');   
		}
 consume();
		_ast = NULL;
		expression(&_ast);
		if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
		_ast12 = (AST *)_ast;
		ASTBase::link(_root, &_sibling, &_tail);
		zzmatch(RPAR);		
		if ( !guessing ) {
		 _t13 = (ANTLRTokenPtr)LT(1);
		}

		  consume();
	}
	else {
		if ( (LA(1)==LBRACK) ) {
			zzmatch(LBRACK);			
			if ( !guessing ) {
			 _t11 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast11 = new AST(_t11);
			_ast11->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						op = _t11;
			op_ast = _ast11;
}
			
			if ( !guessing ) {
			op_ast->setOpType(OP_BALANCED,'}');
			op_ast->setTranslation("{");   
			}
 consume();
			_ast = NULL;
			if ( !guessing ) {
			 is_matrix  = column_expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast12 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			} else {
			column_expression(&_ast);
			}
			if ( !guessing ) {
			if (!is_matrix) {
				// Probable memory leak!
				// elevate row expression to get rid of {{ }}
				(*_root)->setDown((*_root)->down()->down());
			}
			}
			zzmatch(RBRACK);			
			if ( !guessing ) {
			 _t13 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
		}
		else {
			if ( (LA(1)==UNSIGNED_NUMBER) ) {
				zzmatch(UNSIGNED_NUMBER);				
				if ( !guessing ) {
				 _t11 = (ANTLRTokenPtr)LT(1);
				}

				if ( !guessing ) {
				
				_ast11 = new AST(_t11);
				_ast11->subchild(_root, &_sibling, &_tail);
				}
				
				if ( !guessing ) {
								nr = _t11;
				nr_ast = _ast11;
}
				
				if ( !guessing ) {
				mytoken( nr)->convertFloat();   
				}
 consume();
			}
			else {
				if ( (LA(1)==FALS) ) {
					zzmatch(FALS);					
					if ( !guessing ) {
					 _t11 = (ANTLRTokenPtr)LT(1);
					}

					if ( !guessing ) {
					
					_ast11 = new AST(_t11);
					_ast11->subchild(_root, &_sibling, &_tail);
					}
					 consume();
				}
				else {
					if ( (LA(1)==TRU) ) {
						zzmatch(TRU);						
						if ( !guessing ) {
						 _t11 = (ANTLRTokenPtr)LT(1);
						}

						if ( !guessing ) {
						
						_ast11 = new AST(_t11);
						_ast11->subchild(_root, &_sibling, &_tail);
						}
						 consume();
					}
					else {
						zzGUESS
						if ( !zzrv && (LA(1)==IDENT) ) {
							{
								AST *_ast21=NULL;
								_ast = NULL;
								name_path_function_arguments(&_ast);
								if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
								_ast21 = (AST *)_ast;
								ASTBase::link(_root, &_sibling, &_tail);
							}
							zzGUESS_DONE
							_ast = NULL;
							name_path_function_arguments(&_ast);
							if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
							_ast12 = (AST *)_ast;
							ASTBase::link(_root, &_sibling, &_tail);
						}
						else {
							if ( !zzrv ) zzGUESS_DONE;
							zzGUESS
							if ( !zzrv && (LA(1)==IDENT) ) {
								{
									AST *_ast21=NULL;
									_ast = NULL;
									member_list(&_ast);
									if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
									_ast21 = (AST *)_ast;
									ASTBase::link(_root, &_sibling, &_tail);
								}
								zzGUESS_DONE
								{
									AST *_ast21=NULL;
									_ast = NULL;
									member_list(&_ast);
									if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
									_ast21 = (AST *)_ast;
									ASTBase::link(_root, &_sibling, &_tail);
								}
							}
							else {
								if ( !zzrv ) zzGUESS_DONE;
								if ( (LA(1)==IDENT) ) {
									_ast = NULL;
									name_path(&_ast);
									if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
									_ast11 = (AST *)_ast;
									ASTBase::link(_root, &_sibling, &_tail);
								}
								else {
									if ( !zzrv ) zzGUESS_DONE;
									if ( (LA(1)==TIME) ) {
										zzmatch(TIME);										
										if ( !guessing ) {
										 _t11 = (ANTLRTokenPtr)LT(1);
										}

										if ( !guessing ) {
										
										_ast11 = new AST(_t11);
										_ast11->subchild(_root, &_sibling, &_tail);
										}
										 consume();
									}
									else {
										if ( !zzrv ) zzGUESS_DONE;
										if ( (LA(1)==STRING) ) {
											zzmatch(STRING);											
											if ( !guessing ) {
											 _t11 = (ANTLRTokenPtr)LT(1);
											}

											if ( !guessing ) {
											
											_ast11 = new AST(_t11);
											_ast11->subchild(_root, &_sibling, &_tail);
											}
											 consume();
										}
										else {FAIL(1,err19,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x1);
}

void
ModParse::name_path_function_arguments(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	ANTLRTokenPtr n=NULL, f=NULL;
	AST *n_ast=NULL, *f_ast=NULL;
	_ast = NULL;
	name_path(&_ast);
	_ast11 = (AST *)_ast;
	n_ast = _ast11;
	_ast = NULL;
	function_arguments(&_ast);
	_ast12 = (AST *)_ast;
	f_ast = _ast12;
	if ( !guessing ) {
	(*_root)=ASTBase::tmake((new AST(EXTRA_TOKEN)),n_ast,f_ast, NULL);   
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x2);
}

void
ModParse::name_path(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr dot=NULL;
	AST *dot_ast=NULL;
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subchild(_root, &_sibling, &_tail);
	}
	 consume();
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (LA(1)==81) ) {
			zzmatch(81);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						dot = _t21;
			dot_ast = _ast21;
}
			
			if ( !guessing ) {
			dot_ast->setTranslation("`");   
			}
 consume();
			_ast = NULL;
			name_path(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x4);
}

void
ModParse::new_component_reference(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr a=NULL, dot=NULL;
	AST *a_ast=NULL, *dot_ast=NULL;
	_ast = NULL;
	array_op(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	a_ast = _ast11;
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (LA(1)==81) ) {
			zzmatch(81);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						dot = _t21;
			dot_ast = _ast21;
}
			
			if ( !guessing ) {
			dot_ast->setTranslation("`");   
			}
 consume();
			_ast = NULL;
			new_component_reference(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x8);
}

void
ModParse::member_list(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr dot=NULL;
	AST *dot_ast=NULL;
	_ast = NULL;
	comp_ref(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		if ( (LA(1)==81) ) {
			zzmatch(81);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						dot = _t21;
			dot_ast = _ast21;
}
			
			if ( !guessing ) {
			dot_ast->setTranslation("Member"); dot_ast->setOpType(OP_FUNCTION);   
			}
 consume();
			{
				AST *_ast31=NULL;
				zzGUESS_BLOCK
				zzGUESS
				if ( !zzrv && (LA(1)==IDENT) ) {
					{
						AST *_ast41=NULL;
						_ast = NULL;
						member_list(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast41 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
					zzGUESS_DONE
					{
						AST *_ast41=NULL;
						_ast = NULL;
						member_list(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast41 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
				}
				else {
					if ( !zzrv ) zzGUESS_DONE;
					if ( (LA(1)==IDENT) ) {
						_ast = NULL;
						name_path(&_ast);
						if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
						_ast31 = (AST *)_ast;
						ASTBase::link(_root, &_sibling, &_tail);
					}
					else {FAIL(1,err20,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x10);
}

void
ModParse::comp_ref(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t12=NULL,_t14=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast13=NULL,*_ast14=NULL;
	ANTLRTokenPtr b=NULL;
	AST *b_ast=NULL;
	_ast = NULL;
	name_path(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	zzmatch(LBRACK);	
	if ( !guessing ) {
	 _t12 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast12 = new AST(_t12);
	_ast12->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		b = _t12;
	b_ast = _ast12;
}
	
	if ( !guessing ) {
	b_ast->setOpType(OP_ARRAYRANGE);   
	}
 consume();
	_ast = NULL;
	subscript_list(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast13 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	zzmatch(RBRACK);	
	if ( !guessing ) {
	 _t14 = (ANTLRTokenPtr)LT(1);
	}

	  consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x20);
}

void
ModParse::array_op(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr i=NULL, brak=NULL;
	AST *i_ast=NULL, *brak_ast=NULL;
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subchild(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		i = _t11;
	i_ast = _ast11;
}
	 consume();
	{
		ANTLRTokenPtr _t21=NULL,_t23=NULL;
		AST *_ast21=NULL,*_ast22=NULL,*_ast23=NULL;
		if ( (LA(1)==LBRACK) ) {
			zzmatch(LBRACK);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			if ( !guessing ) {
			
			_ast21 = new AST(_t21);
			_ast21->subroot(_root, &_sibling, &_tail);
			}
			
			if ( !guessing ) {
						brak = _t21;
			brak_ast = _ast21;
}
			 consume();
			_ast = NULL;
			subscript_list(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			zzmatch(RBRACK);			
			if ( !guessing ) {
			 _t23 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
			brak_ast->setOpType(OP_ARRAYRANGE);   
			}
 consume();
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x40);
}

void
ModParse::component_reference(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL;
	ANTLRTokenPtr i=NULL, a=NULL, dot=NULL, c=NULL;
	AST *i_ast=NULL, *a_ast=NULL, *dot_ast=NULL, *c_ast=NULL;
	zzmatch(IDENT);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	
	if ( !guessing ) {
		i = _t11;
}
	 consume();
	{
		AST *_ast21=NULL;
		if ( (LA(1)==LBRACK) ) {
			_ast = NULL;
			array_decl(&_ast);
			_ast21 = (AST *)_ast;
			a_ast = _ast21;
		}
	}
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		if ( (LA(1)==81) ) {
			zzmatch(81);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			
			if ( !guessing ) {
						dot = _t21;
}
			 consume();
			_ast = NULL;
			component_reference(&_ast);
			_ast22 = (AST *)_ast;
			c_ast = _ast22;
		}
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd10, 0x80);
}

 bool  
ModParse::column_expression(ASTBase **_root)
{
	 bool  	 _retv;
	PURIFY(_retv,sizeof( bool  	))
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_retv=false;   
	_ast = NULL;
	row_expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==77) ) {
			zzmatch(77);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			row_expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
			if ( !guessing ) {
			_retv=true;   
			}
		}
	}
	return _retv;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd11, 0x1);
	return _retv;
}

void
ModParse::row_expression(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	AST *_ast11=NULL;
	_ast = NULL;
	expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast11 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==78) ) {
			zzmatch(78);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	if ( !guessing ) {
	(*_root)=ASTBase::tmake((new AST(EXTRA_TOKEN,"{",OP_BALANCED,'}')),(*_root), NULL);   
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd11, 0x2);
}

void
ModParse::function_arguments(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL,_t14=NULL;
	AST *_ast11=NULL,*_ast12=NULL,*_ast14=NULL;
	ANTLRTokenPtr p=NULL;
	AST *p_ast=NULL;
	zzmatch(LPAR);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subroot(_root, &_sibling, &_tail);
	}
	
	if ( !guessing ) {
		p = _t11;
	p_ast = _ast11;
}
	 consume();
	_ast = NULL;
	expression(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL,*_ast22=NULL;
		while ( (LA(1)==78) ) {
			zzmatch(78);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			  consume();
			_ast = NULL;
			expression(&_ast);
			if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
			_ast22 = (AST *)_ast;
			ASTBase::link(_root, &_sibling, &_tail);
		}
	}
	zzmatch(RPAR);	
	if ( !guessing ) {
	 _t14 = (ANTLRTokenPtr)LT(1);
	}

	 
	if ( !guessing ) {
	p_ast->setOpType(OP_FUNCTION); 
	p_ast->setTranslation(""); // don't output (
	}
 consume();
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd11, 0x4);
}

void
ModParse::comment(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
;
	ANTLRTokenPtr s=NULL;
	AST *s_ast=NULL;
	{
		ANTLRTokenPtr _t21=NULL;
		AST *_ast21=NULL;
		while ( (LA(1)==STRING) ) {
			zzmatch(STRING);			
			if ( !guessing ) {
			 _t21 = (ANTLRTokenPtr)LT(1);
			}

			 
			if ( !guessing ) {
						s = _t21;
}
			
			if ( !guessing ) {
			newComment=new Comment(mytoken( s)->getLine(),OPTIONAL);
			newComment->addText(mytoken( s)->getText()); 
			}
 consume();
		}
	}
	{
		AST *_ast22=NULL;
		zzGUESS_BLOCK
		zzGUESS
		if ( !zzrv && (LA(1)==ANNOTATION) ) {
			{
				AST *_ast31=NULL;
				_ast = NULL;
				annotation(&_ast);
				if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
				_ast31 = (AST *)_ast;
				ASTBase::link(_root, &_sibling, &_tail);
			}
			zzGUESS_DONE
			_ast = NULL;
			annotation(&_ast);
			_ast22 = (AST *)_ast;
		}
		else if ( !zzrv ) zzGUESS_DONE;
	}
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd11, 0x8);
}

void
ModParse::annotation(ASTBase **_root)
{
	zzRULE;
	ASTBase **_astp, *_ast = NULL, *_sibling = NULL, *_tail = NULL;
	ANTLRTokenPtr _t11=NULL;
	AST *_ast11=NULL,*_ast12=NULL;
	zzmatch(ANNOTATION);	
	if ( !guessing ) {
	 _t11 = (ANTLRTokenPtr)LT(1);
	}

	if ( !guessing ) {
	
	_ast11 = new AST(_t11);
	_ast11->subchild(_root, &_sibling, &_tail);
	}
	 consume();
	_ast = NULL;
	class_specialization(&_ast);
	if ( _tail==NULL ) _sibling = _ast; else _tail->setRight(_ast);
	_ast12 = (AST *)_ast;
	ASTBase::link(_root, &_sibling, &_tail);
	return;
fail:
	if ( guessing ) zzGUESS_FAIL;
	syn(zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk);
	resynch(setwd11, 0x10);
}
