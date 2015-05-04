package Dict

function localdeclarationtypes
 input String instring;
 input String instring1;
 input String instring2;
 output String outstring;
 algorithm
 outstring:= matchcontinue(instring,instring1,instring2)
   local

      /* Pam apply_binop() types */

        case("./rmltests/pam/pam.rml","apply_binop","x") then "Integer";
        case("./rmltests/pam/pam.rml","apply_binop","y") then "Integer";
        case("./rmltests/pam/pam.rml","apply_binop","z") then "Integer";

          /* Pam apply_binop() types */

        case("./rmltests/pam/pam.rml","apply_relop","x") then "Integer";
        case("./rmltests/pam/pam.rml","apply_relop","y") then "Integer";
        case("./rmltests/pam/pam.rml","apply_relop","z") then "Boolean";

          /* Pam repeat_eval() types */
        case("./rmltests/pam/pam.rml","repeat_eval","n") then "Integer";
        case("./rmltests/pam/pam.rml","repeat_eval","n2") then "Integer";
        case("./rmltests/pam/pam.rml","repeat_eval","stmt") then "Stmt";
        case("./rmltests/pam/pam.rml","repeat_eval","state") then "State";
        case("./rmltests/pam/pam.rml","repeat_eval","state2") then "State";
        case("./rmltests/pam/pam.rml","repeat_eval","state3") then "State";

         /* Pam update() types */
        case("./rmltests/pam/pam.rml","update","env") then "Env";
        case("./rmltests/pam/pam.rml","update","id") then "Ident";
        case("./rmltests/pam/pam.rml","update","value") then "Value";

        /* Pam error() types */

       case("./rmltests/pam/pam.rml","error","str1") then "Ident";
       case("./rmltests/pam/pam.rml","error","str2") then "Ident";

          /* Pam output_item() types */

       case("./rmltests/pam/pam.rml","input_item","i") then "Integer";

         /* Pam output_item() types */
        case("./rmltests/pam/pam.rml","output_item","i") then "Integer";
        case("./rmltests/pam/pam.rml","output_item","s") then "String";

         /* Pam lookup() types */

        case("./rmltests/pam/pam.rml","lookup","value") then "Value";
        case("./rmltests/pam/pam.rml","lookup","id") then "Ident";
        case("./rmltests/pam/pam.rml","lookup","id2") then "Ident";
        case("./rmltests/pam/pam.rml","lookup","rest") then "Env";

        /* Pam eval() types */

        case("./rmltests/pam/pam.rml","eval","n") then "Integer";
        case("./rmltests/pam/pam.rml","eval","n2") then "Integer";
        case("./rmltests/pam/pam.rml","eval","state") then "State";
        case("./rmltests/pam/pam.rml","eval","stmt") then "Stmt";
        case("./rmltests/pam/pam.rml","eval","state2") then "State";
        case("./rmltests/pam/pam.rml","eval","state3") then "State";
        case("./rmltests/pam/pam.rml","eval","x") then "Integer";
        case("./rmltests/pam/pam.rml","eval","y") then "Integer";
        case("./rmltests/pam/pam.rml","eval","z") then "Integer";
        case("./rmltests/pam/pam.rml","eval","env") then "State";
        case("./rmltests/pam/pam.rml","eval","id") then "Ident";
        case("./rmltests/pam/pam.rml","eval","v") then "Integer";
        case("./rmltests/pam/pam.rml","eval","val1") then "Value";
        case("./rmltests/pam/pam.rml","eval","e1") then "Exp";
        case("./rmltests/pam/pam.rml","eval","v1") then "Integer";
        case("./rmltests/pam/pam.rml","eval","e2") then "Exp";
        case("./rmltests/pam/pam.rml","eval","v2") then "Integer";
        case("./rmltests/pam/pam.rml","eval","v3") then "Integer";
        case("./rmltests/pam/pam.rml","eval","binop") then "BinOp";
        case("./rmltests/pam/pam.rml","eval","b") then "Boolean";
        case("./rmltests/pam/pam.rml","eval","relop") then "RelOp";

      case("./rmltests/pam/main.rml","main","program") then "Pam.Stmt";

        /* Pam eval_stmt() types */
        case("./rmltests/pam/pam.rml","eval_stmt","val1") then "Value";
        case("./rmltests/pam/pam.rml","eval_stmt","env") then "State";
        case("./rmltests/pam/pam.rml","eval_stmt","env2") then "State";
        case("./rmltests/pam/pam.rml","eval_stmt","state2") then "State";
        case("./rmltests/pam/pam.rml","eval_stmt","state") then "State";
        case("./rmltests/pam/pam.rml","eval_stmt","state3") then "State";
        case("./rmltests/pam/pam.rml","eval_stmt","e1") then "Exp";
        case("./rmltests/pam/pam.rml","eval_stmt","comp") then "Exp";
        case("./rmltests/pam/pam.rml","eval_stmt","state1") then "State";
        case("./rmltests/pam/pam.rml","eval_stmt","s1") then "Stmt";
        case("./rmltests/pam/pam.rml","eval_stmt","s2") then "Stmt";
        case("./rmltests/pam/pam.rml","eval_stmt","stmt1") then "Stmt";
        case("./rmltests/pam/pam.rml","eval_stmt","stmt2") then "Stmt";
        case("./rmltests/pam/pam.rml","eval_stmt","v2") then "Integer";
        case("./rmltests/pam/pam.rml","eval_stmt","n1") then "Integer";
        case("./rmltests/pam/pam.rml","eval_stmt","id") then "Ident";
        case("./rmltests/pam/pam.rml","eval_stmt","SKIP") then "Stmt";
        case("./rmltests/pam/pam.rml","eval_stmt","rest") then "Identlist";

        /* PamDecl env.rml lookup() types */

        case("./rmltests/pamdecl/env.rml","lookup","id") then "Ident";
        case("./rmltests/pamdecl/env.rml","lookup","idenv") then "Ident";
        case("./rmltests/pamdecl/env.rml","lookup","rest") then "Env";
        case("./rmltests/pamdecl/env.rml","lookup","v") then "Value";

         /* PamDecl env.rml lookuptype() types */
        case("./rmltests/pamdecl/env.rml","lookuptype","id") then "Ident";
        case("./rmltests/pamdecl/env.rml","lookuptype","idenv") then "Ident";
        case("./rmltests/pamdecl/env.rml","lookuptype","rest") then "Env";
        case("./rmltests/pamdecl/env.rml","lookuptype","t") then "Type";

         /* PamDecl env.rml update() types */
        case("./rmltests/pamdecl/env.rml","update","newenv") then "Env";
        case("./rmltests/pamdecl/env.rml","update","id") then "Ident";
        case("./rmltests/pamdecl/env.rml","update","v") then "Value";
        case("./rmltests/pamdecl/env.rml","update","ty") then "Type";
        case("./rmltests/pamdecl/env.rml","update","env") then "Env";

     /* PamDecl env.rml update() types */
        case("./rmltests/pamdecl/main.rml","main","ast") then "Absyn.Prog";


         /* PamDecl eval.rml binary_lub() types */

        case("./rmltests/pamdecl/eval.rml","binary_lub","v1") then "Integer";
        case("./rmltests/pamdecl/eval.rml","binary_lub","v2") then "Integer";
        case("./rmltests/pamdecl/eval.rml","binary_lub","r1") then "Real";
        case("./rmltests/pamdecl/eval.rml","binary_lub","r2") then "Real";

          /* PamDecl eval.rml promote() types */

        case("./rmltests/pamdecl/eval.rml","promote","v") then "Integer";
        case("./rmltests/pamdecl/eval.rml","promote","r") then "Real";
        case("./rmltests/pamdecl/eval.rml","promote","b") then "Boolean";

         /* PamDecl eval.rml apply_int_binary() types */

        case("./rmltests/pamdecl/eval.rml","apply_int_binary","v1") then "Integer";
        case("./rmltests/pamdecl/eval.rml","apply_int_binary","v2") then "Integer";
        case("./rmltests/pamdecl/eval.rml","apply_int_binary","v3") then "Integer";

         /* PamDecl eval.rml apply_real_binary() types */

        case("./rmltests/pamdecl/eval.rml","apply_real_binary","v1") then "Real";
        case("./rmltests/pamdecl/eval.rml","apply_real_binary","v2") then "Real";
        case("./rmltests/pamdecl/eval.rml","apply_real_binary","v3") then "Real";

        /* PamDecl eval.rml apply_int_unary() types */

        case("./rmltests/pamdecl/eval.rml","apply_int_unary","v1") then "Integer";
        case("./rmltests/pamdecl/eval.rml","apply_int_unary","v2") then "Integer";

          /* PamDecl eval.rml apply_real_unary() types */

        case("./rmltests/pamdecl/eval.rml","apply_real_unary","v1") then "Real";
        case("./rmltests/pamdecl/eval.rml","apply_real_unary","v2") then "Real";


        /* PamDecl eval.rml apply_int_relation() types */

        case("./rmltests/pamdecl/eval.rml","apply_int_relation","v1") then "Integer";
        case("./rmltests/pamdecl/eval.rml","apply_int_relation","v2") then "Integer";
        case("./rmltests/pamdecl/eval.rml","apply_int_relation","v3") then "Boolean";


        /* PamDecl eval.rml apply_real_relation() types */

        case("./rmltests/pamdecl/eval.rml","apply_real_relation","v1") then "Real";
        case("./rmltests/pamdecl/eval.rml","apply_real_relation","v2") then "Real";
        case("./rmltests/pamdecl/eval.rml","apply_real_relation","v3") then "Boolean";

         /* PamDecl eval.rml eval_expr() types */

        case("./rmltests/pamdecl/eval.rml","eval_expr","env") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_expr","v") then "Integer";
        case("./rmltests/pamdecl/eval.rml","eval_expr","r") then "Real";
        case("./rmltests/pamdecl/eval.rml","eval_expr","e1") then "Absyn.Expr";
        case("./rmltests/pamdecl/eval.rml","eval_expr","e2") then "Absyn.Expr";
        case("./rmltests/pamdecl/eval.rml","eval_expr","v1") then "Env.Value";
        case("./rmltests/pamdecl/eval.rml","eval_expr","v2") then "Env.Value";
        case("./rmltests/pamdecl/eval.rml","eval_expr","c1") then "Integer";
        case("./rmltests/pamdecl/eval.rml","eval_expr","c2") then "Integer";
        case("./rmltests/pamdecl/eval.rml","eval_expr","binop") then "Absyn.BinOp";
        case("./rmltests/pamdecl/eval.rml","eval_expr","v3") then "Integer";
        case("./rmltests/pamdecl/eval.rml","eval_expr","r1") then "Real";
        case("./rmltests/pamdecl/eval.rml","eval_expr","r2") then "Real";
        case("./rmltests/pamdecl/eval.rml","eval_expr","r3") then "Real";
        case("./rmltests/pamdecl/eval.rml","eval_expr","unop") then "Absyn.UnOp";
        case("./rmltests/pamdecl/eval.rml","eval_expr","relop") then "Absyn.RelOp";
        case("./rmltests/pamdecl/eval.rml","eval_expr","b") then "Boolean";
        case("./rmltests/pamdecl/eval.rml","eval_expr","id") then "String";

            /* PamDecl eval.rml print_value() types */

        case("./rmltests/pamdecl/eval.rml","print_value","v") then "Integer";
        case("./rmltests/pamdecl/eval.rml","print_value","r") then "Real";
        case("./rmltests/pamdecl/eval.rml","print_value","vstr") then "String";

             /* PamDecl eval.rml eval_stmt() types */

        case("./rmltests/pamdecl/eval.rml","eval_stmt","env") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","env1") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","env2") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","e") then "Absyn.Expr";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","v") then "Env.Value";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","id") then "String";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","ty") then "Env.Type";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","v2") then "Env.Value";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","c") then "list<Absyn.Stmt>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","a") then "list<Absyn.Stmt>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","ss") then "list<Absyn.Stmt>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt","NOOP") then "Absyn.Stmt";

            /* PamDecl eval.rml eval_stmt_list() types */

        case("./rmltests/pamdecl/eval.rml","eval_stmt_list","env") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt_list","env1") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt_list","env2") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_stmt_list","s") then "Absyn.Stmt";
        case("./rmltests/pamdecl/eval.rml","eval_stmt_list","ss") then "list<Absyn.Stmt>";

        /* PamDecl eval.rml eval_decl() types */

        case("./rmltests/pamdecl/eval.rml","eval_decl","env2") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_decl","env") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_decl","var") then "String";

       /* PamDecl eval.rml eval_decl_list() types */

        case("./rmltests/pamdecl/eval.rml","eval_decl_list","env") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_decl_list","env1") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_decl_list","env2") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","eval_decl_list","s") then "Absyn.Decl";
        case("./rmltests/pamdecl/eval.rml","eval_decl_list","ss") then "list<Absyn.Decl>";

       /* PamDecl eval.rml evalprog() types */

        case("./rmltests/pamdecl/eval.rml","evalprog","env1") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","evalprog","env2") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","evalprog","env3") then "list<Env.Bind>";
        case("./rmltests/pamdecl/eval.rml","evalprog","decls") then "list<Absyn.Decl>";
        case("./rmltests/pamdecl/eval.rml","evalprog","stmts") then "list<Absyn.Stmt>";

        /* Petrol fcemit.rml invert_ty() types */

        case("./rmltests/petrol/fcemit.rml","invert_ty","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","invert_ty","ity1") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","invert_ty","ty") then "FCode.Ty";
        case("./rmltests/petrol/fcemit.rml","invert_ty","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","invert_ty","sz") then "Integer";
        case("./rmltests/petrol/fcemit.rml","invert_ty","stamp") then "Integer";

        /* Petrol fcemit.rml print_int() types */

        case("./rmltests/petrol/fcemit.rml","print_int","i") then "Integer";
        case("./rmltests/petrol/fcemit.rml","print_int","s") then "String";

        /* Petrol fcemit.rml emit_struct() types */

        case("./rmltests/petrol/fcemit.rml","emit_struct","stamp") then "Integer";

         /* Petrol fcemit.rml emit_base() types */

        case("./rmltests/petrol/fcemit.rml","emit_base","stamp") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_base","str") then "String";

        /* Petrol fcemit.rml emit_invty() types */

        case("./rmltests/petrol/fcemit.rml","emit_invty","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","emit_invty","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_invty","str") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_invty","sz") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_invty","args") then "Arglist";

         /* Petrol fcemit.rml emit_args() types */

        case("./rmltests/petrol/fcemit.rml","emit_args","arg") then "Arg";
        case("./rmltests/petrol/fcemit.rml","emit_args","args") then "Arglist";

        /* Petrol fcemit.rml emit_arg() types */

        case("./rmltests/petrol/fcemit.rml","emit_arg","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","emit_arg","ity") then "InvTy";

        /* Petrol fcemit.rml emit_comma_arg() types */

        case("./rmltests/petrol/fcemit.rml","emit_comma_arg","arg") then "Arg";


         /* Petrol fcemit.rml emit_var() types */

        case("./rmltests/petrol/fcemit.rml","emit_var","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","emit_var","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","emit_var","ty") then "FCode.Ty";
        case("./rmltests/petrol/fcemit.rml","emit_var","id") then "String";

         /* Petrol fcemit.rml emit_var_bnd() types */

        case("./rmltests/petrol/fcemit.rml","emit_var_bnd","var") then "FCode.Var";

         /* Petrol fcemit.rml emit_rec_bnds() types */

        case("./rmltests/petrol/fcemit.rml","emit_rec_bnds","bnds") then "FCodeVarlist";
        case("./rmltests/petrol/fcemit.rml","emit_rec_bnds","ty") then "FCode.Ty";
        case("./rmltests/petrol/fcemit.rml","emit_rec_bnds","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_rec_bnds","prefix") then "String";

         /* Petrol fcemit.rml emit_record() types */

        case("./rmltests/petrol/fcemit.rml","emit_record","stamp0") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_record","stamp1") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_record","prefix0") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_record","prefix1") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_record","bnds") then " list<FCode.Var>";


         /* Petrol fcemit.rml emit_unop() types */

        case("./rmltests/petrol/fcemit.rml","emit_unop","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","emit_unop","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","emit_unop","ty") then "FCode.Ty";
        case("./rmltests/petrol/fcemit.rml","emit_unop","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_unop","stamp") then "Integer";

        /* Petrol main.rml parse() types */

        case("./rmltests/petrol/main.rml","main","ast") then "Absyn.Prog";

        /* Petrol main.rml static() types */

        case("./rmltests/petrol/main.rml","static","tcode") then " TCode.Prog";
        case("./rmltests/petrol/main.rml","static","ast") then "Absyn.Prog";

          /* Petrol main.rml flatten() types */

        case("./rmltests/petrol/main.rml","flatten","tcode") then " TCode.Prog";
        case("./rmltests/petrol/main.rml","flatten","fcode") then "FCode.Prog";
        case("./rmltests/petrol/main.rml","emit","fcode") then "FCode.Prog";

          /* Petrol fcemit.rml emit_exp() types */

        case("./rmltests/petrol/fcemit.rml","emit_exp","i") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_exp","level") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_exp","r") then "Real";
        case("./rmltests/petrol/fcemit.rml","emit_exp","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_exp","str") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_exp","r1") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_exp","unop") then "FCode.UnOp";
        case("./rmltests/petrol/fcemit.rml","emit_exp","exp") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_exp","exp1") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_exp","exp2") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_exp","binop") then "FCode.BinOp";
        case("./rmltests/petrol/fcemit.rml","emit_exp","exps") then "list<FCode.Exp>";


                 /* Petrol fcemit.rml emit_comma_exp() types */

        case("./rmltests/petrol/fcemit.rml","emit_comma_exp","exp") then "FCode.Exp";

                  /* Petrol fcemit.rml emit_exps() types */

        case("./rmltests/petrol/fcemit.rml","emit_exps","exp") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_exps","exps") then "list<FCode.Exp>";

             /* Petrol fcemit.rml emit_assign_retval() types */

        case("./rmltests/petrol/fcemit.rml","emit_assign_retval","exp") then "FCode.Exp";

         /* Petrol fcemit.rml emit_stmt() types */

        case("./rmltests/petrol/fcemit.rml","emit_stmt","exps") then "list<FCode.Exp>";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","exp") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","lhs") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","rhs") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","ret") then "Option<tuple<FCode.Ty, FCode.Exp>>";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","stmt") then "FCode.Stmt";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","stmt1") then "FCode.Stmt";
        case("./rmltests/petrol/fcemit.rml","emit_stmt","stmt2") then "FCode.Stmt";

         /* Petrol fcemit.rml conv_formal_decl() types */

        case("./rmltests/petrol/fcemit.rml","conv_formal_decl","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","conv_formal_decl","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","conv_formal_decl","ty") then "FCode.Ty";

        /* Petrol fcemit.rml emit_proc_head() types */

        case("./rmltests/petrol/fcemit.rml","emit_proc_head","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_proc_head","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","emit_proc_head","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","emit_proc_head","ty") then "FCode.Ty";
        case("./rmltests/petrol/fcemit.rml","emit_proc_head","args") then "list<Arg>";

        /* Petrol fcemit.rml emit_proc_decl() types */

        case("./rmltests/petrol/fcemit.rml","emit_proc_decl","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_proc_decl","formals1") then "list<Arg>";
        case("./rmltests/petrol/fcemit.rml","emit_proc_decl","formals") then "list<FCode.Var>";
        case("./rmltests/petrol/fcemit.rml","emit_proc_decl","ty_opt") then "Option<FCode.Ty>";

                /* Petrol fcemit.rml conv_formal_defn() types */

        case("./rmltests/petrol/fcemit.rml","conv_formal_defn","id") then "String";
        case("./rmltests/petrol/fcemit.rml","conv_formal_defn","base") then "Base";
        case("./rmltests/petrol/fcemit.rml","conv_formal_defn","ity") then "InvTy";
        case("./rmltests/petrol/fcemit.rml","conv_formal_defn","ty") then "FCode.Ty";

                          /* Petrol fcemit.rml emit_decl_retval() types */

        case("./rmltests/petrol/fcemit.rml","emit_decl_retval","ty") then "FCode.Ty";

          /* Petrol fcemit.rml emit_load_formals() types */

        case("./rmltests/petrol/fcemit.rml","emit_load_formals","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_load_formals","stamp") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_load_formals","formals") then "list<FCode.Var>";

         /* Petrol fcemit.rml foreach() types */

        case("./rmltests/petrol/fcemit.rml","foreach","x") then "a";
        case("./rmltests/petrol/fcemit.rml","foreach","F") then "FuncType";
        case("./rmltests/petrol/fcemit.rml","foreach","xs") then "alist";

        /* Petrol fcemit.rml map() types */

        case("./rmltests/petrol/fcemit.rml","map","x") then "a";
        case("./rmltests/petrol/fcemit.rml","map","y") then "b";
        case("./rmltests/petrol/fcemit.rml","map","F") then "FuncType";
        case("./rmltests/petrol/fcemit.rml","map","xs") then "alist";
        case("./rmltests/petrol/fcemit.rml","map","ys") then "blist";


           /* Petrol fcemit.rml emit_setup_display() types */

        case("./rmltests/petrol/fcemit.rml","emit_setup_display","lev1") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_setup_display","stamp1") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_setup_display","lev") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_setup_display","stamp") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_setup_display","formals") then "list<FCode.Var>";
        case("./rmltests/petrol/fcemit.rml","emit_setup_display","vars") then "list<FCode.Var>";

                   /* Petrol fcemit.rml emit_restore_display() types */

        case("./rmltests/petrol/fcemit.rml","emit_restore_display","lev") then "Integer";

         /* Petrol fcemit.rml emit_proc_defn() types */

        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","r") then "FCode.Record";
        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","stmt") then "FCode.Stmt";
        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","lev") then "Integer";
        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","ty_opt") then "Option<FCode.Ty> ";
        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","formals") then "list<FCode.Var>";
        case("./rmltests/petrol/fcemit.rml","emit_proc_defn","formals1") then "list<Arg>";

                  /* Petrol fcemit.rml compare1() types */

        case("./rmltests/petrol/fcemit.rml","compare1","i") then "Integer";
        case("./rmltests/petrol/fcemit.rml","compare1","j") then "Integer";

        /* Petrol fcemit.rml compare() types */

        case("./rmltests/petrol/fcemit.rml","compare","i") then "Integer";
        case("./rmltests/petrol/fcemit.rml","compare","j") then "Integer";
        case("./rmltests/petrol/fcemit.rml","compare","cmp") then "Cmp";

        /* Petrol fcemit.rml insert() types */

        case("./rmltests/petrol/fcemit.rml","insert","r") then "FCode.Record";
        case("./rmltests/petrol/fcemit.rml","insert","r1") then "FCode.Record";
        case("./rmltests/petrol/fcemit.rml","insert","cmp") then "Cmp";
        case("./rmltests/petrol/fcemit.rml","insert","stamp") then "Integer";
        case("./rmltests/petrol/fcemit.rml","insert","stamp1") then "Integer";
        case("./rmltests/petrol/fcemit.rml","insert","left1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","insert","right1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","insert","left") then "RTree";
        case("./rmltests/petrol/fcemit.rml","insert","right") then "RTree";

          /* Petrol fcemit.rml insert1() types */

        case("./rmltests/petrol/fcemit.rml","insert1","r1") then "FCode.Record";
        case("./rmltests/petrol/fcemit.rml","insert1","left1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","insert1","right1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","insert1","left") then "RTree";
        case("./rmltests/petrol/fcemit.rml","insert1","right") then "RTree";

         /* Petrol fcemit.rml emit_rec_tree() types */

        case("./rmltests/petrol/fcemit.rml","emit_rec_tree","r") then "FCode.Record";
        case("./rmltests/petrol/fcemit.rml","emit_rec_tree","left") then "RTree";
        case("./rmltests/petrol/fcemit.rml","emit_rec_tree","right") then "RTree";

        /* Petrol fcemit.rml ty_recs() types */

        case("./rmltests/petrol/fcemit.rml","ty_recs","r") then "FCode.Record";
        case("./rmltests/petrol/fcemit.rml","ty_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_recs","bnds") then "list<FCode.Var>";
        case("./rmltests/petrol/fcemit.rml","ty_recs","ty") then "FCode.Ty";

         /* Petrol fcemit.rml vars_recs() types */

        case("./rmltests/petrol/fcemit.rml","vars_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","vars_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","vars_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","vars_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","vars_recs","vars") then "list<FCode.Var>";
        case("./rmltests/petrol/fcemit.rml","vars_recs","ty") then "FCode.Ty";

       /* Petrol fcemit.rml ty_opt_recs() types */

        case("./rmltests/petrol/fcemit.rml","ty_opt_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_opt_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_opt_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_opt_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","ty_opt_recs","ty") then "FCode.Ty";

        /* Petrol fcemit.rml unop_recs() types */

        case("./rmltests/petrol/fcemit.rml","unop_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","unop_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","unop_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","unop_recs","ty") then "FCode.Ty";

         /* Petrol fcemit.rml exp_recs() types */

        case("./rmltests/petrol/fcemit.rml","exp_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exp_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exp_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exp_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exp_recs","exp") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","exp_recs","exp1") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","exp_recs","exp2") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","exp_recs","exps") then "list<FCode.Exp>";
        case("./rmltests/petrol/fcemit.rml","exp_recs","unop") then " FCode.UnOp";


       /* Petrol fcemit.rml exps_recs() types */

        case("./rmltests/petrol/fcemit.rml","exps_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exps_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exps_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exps_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","exps_recs","exp") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","exps_recs","exp1") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","exps_recs","exp2") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","exps_recs","exps") then "list<FCode.Exp>";

         /* Petrol fcemit.rml stmt_recs() types */

        case("./rmltests/petrol/fcemit.rml","stmt_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","recs3") then "RTree";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","ty") then "FCode.Ty";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","exp") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","exp1") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","exp2") then "FCode.Exp";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","exps") then "list<FCode.Exp>";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","stmt") then "FCode.Stmt";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","stmt1") then "FCode.Stmt";
        case("./rmltests/petrol/fcemit.rml","stmt_recs","stmt2") then "FCode.Stmt";

            /* Petrol fcemit.rml block_opt_recs() types */

        case("./rmltests/petrol/fcemit.rml","block_opt_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","block_opt_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","block_opt_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","block_opt_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","block_opt_recs","recs3") then "RTree";
        case("./rmltests/petrol/fcemit.rml","block_opt_recs","stmt") then "FCode.Stmt";
        case("./rmltests/petrol/fcemit.rml","block_opt_recs","r") then "FCode.Record";

            /* Petrol fcemit.rml proc_recs() types */

        case("./rmltests/petrol/fcemit.rml","proc_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","proc_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","proc_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","proc_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","proc_recs","recs3") then "RTree";
        case("./rmltests/petrol/fcemit.rml","proc_recs","formals") then "list<FCode.Var>";
        case("./rmltests/petrol/fcemit.rml","proc_recs","ty_opt") then "Option<FCode.Ty>";
        case("./rmltests/petrol/fcemit.rml","proc_recs","block_opt") then "Option<FCode.Block>";

         /* Petrol fcemit.rml procs_recs() types */

        case("./rmltests/petrol/fcemit.rml","procs_recs","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","procs_recs","recs0") then "RTree";
        case("./rmltests/petrol/fcemit.rml","procs_recs","recs1") then "RTree";
        case("./rmltests/petrol/fcemit.rml","procs_recs","recs2") then "RTree";
        case("./rmltests/petrol/fcemit.rml","procs_recs","recs3") then "RTree";
        case("./rmltests/petrol/fcemit.rml","procs_recs","proc") then "FCode.Proc";
        case("./rmltests/petrol/fcemit.rml","procs_recs","procs") then "list<FCode.Proc>";

         /* Petrol fcemit.rml emit_record_defns() types */

        case("./rmltests/petrol/fcemit.rml","emit_record_defns","recs") then "RTree";
        case("./rmltests/petrol/fcemit.rml","emit_record_defns","procs") then "list<FCode.Proc>";

       /* Petrol fcemit.rml emit() types */

        case("./rmltests/petrol/fcemit.rml","emit","id") then "String";
        case("./rmltests/petrol/fcemit.rml","emit","procs") then "list<FCode.Proc>";

         /* Petrol flatten.rml lookup() types */

        case("./rmltests/petrol/flatten.rml","lookup","key1") then "String";
        case("./rmltests/petrol/flatten.rml","lookup","key0") then "String";
        case("./rmltests/petrol/flatten.rml","lookup","bnd") then "Bnd";
        case("./rmltests/petrol/flatten.rml","lookup","env") then "Env";


        /* Petrol flatten.rml map() types */

        case("./rmltests/petrol/flatten.rml","map","x") then "a";
        case("./rmltests/petrol/flatten.rml","map","y") then "b";
        case("./rmltests/petrol/flatten.rml","map","F") then "FuncType";
        case("./rmltests/petrol/flatten.rml","map","xs") then "alist";
        case("./rmltests/petrol/flatten.rml","map","ys") then "blist";

         /* Petrol flatten.rml trans_ty() types */

        case("./rmltests/petrol/flatten.rml","trans_ty","ty1") then "FCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_ty","ty") then "TCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_ty","sz") then "Integer";
        case("./rmltests/petrol/flatten.rml","trans_ty","stamp") then "Integer";
        case("./rmltests/petrol/flatten.rml","trans_ty","r1") then "FCode.Record";
        case("./rmltests/petrol/flatten.rml","trans_ty","r") then "TCode.Record";


         /* Petrol flatten.rml trans_rec() types */

        case("./rmltests/petrol/flatten.rml","trans_rec","bnds1") then "list<FCode.Var>";
        case("./rmltests/petrol/flatten.rml","trans_rec","bnds") then "list<TCode.Var>";
        case("./rmltests/petrol/flatten.rml","trans_rec","stamp") then "Integer";


        /* Petrol flatten.rml trans_var() types */

        case("./rmltests/petrol/flatten.rml","trans_var","ty1") then "FCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_var","ty") then "TCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_var","id") then "String";


        /* Petrol flatten.rml trans_tyopt() types */

        case("./rmltests/petrol/flatten.rml","trans_tyopt","ty1") then "FCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_tyopt","ty") then "TCode.Ty";

        /* Petrol flatten.rml trans_unop() types */

        case("./rmltests/petrol/flatten.rml","trans_unop","ty1") then "FCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_unop","ty") then "TCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_unop","r1") then "FCode.Record";
        case("./rmltests/petrol/flatten.rml","trans_unop","r") then "TCode.Record";
        case("./rmltests/petrol/flatten.rml","trans_unop","id") then "String";

        /* Petrol flatten.rml trans_binop() types */

        case("./rmltests/petrol/flatten.rml","trans_binop","ty1") then "FCode.Ty";
        case("./rmltests/petrol/flatten.rml","trans_binop","ty") then "TCode.Ty";

         /* Petrol flatten.rml trans_procid() types */

        case("./rmltests/petrol/flatten.rml","trans_procid","env") then "Env";
        case("./rmltests/petrol/flatten.rml","trans_procid","id") then "FCode.Ident";



        /* Petrol flatten.rml trans_exp() types */

        case("./rmltests/petrol/flatten.rml","trans_exp","x") then "Integer";
        case("./rmltests/petrol/flatten.rml","trans_exp","r") then "Real";

        case("./rmltests/petrol/flatten.rml","trans_exp","id") then "String";
        case("./rmltests/petrol/flatten.rml","trans_exp","id1") then "String";

        case("./rmltests/petrol/flatten.rml","trans_exp","env") then "Env";
        case("./rmltests/petrol/flatten.rml","trans_exp","lev") then "Integer";
        case("./rmltests/petrol/flatten.rml","trans_exp","rec") then "FCode.Record";
        case("./rmltests/petrol/flatten.rml","trans_exp","unop") then "TCode.UnOp";
        case("./rmltests/petrol/flatten.rml","trans_exp","unop1") then "FCode.UnOp";
        case("./rmltests/petrol/flatten.rml","trans_exp","binop") then "TCode.BinOp";
        case("./rmltests/petrol/flatten.rml","trans_exp","binop1") then "FCode.BinOp";
        case("./rmltests/petrol/flatten.rml","trans_exp","exp") then "TCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_exp","exp1") then "TCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_exp","exp2") then "TCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_exp","exp_1") then "FCode.Exp";

        case("./rmltests/petrol/flatten.rml","trans_exp","exp1_1") then "FCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_exp","exp2_1") then "FCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_exp","args") then "list<TCode.Exp> ";
        case("./rmltests/petrol/flatten.rml","trans_exp","args1") then "list<FCode.Exp> ";

        /* Petrol flatten.rml trans_args() types */

        case("./rmltests/petrol/flatten.rml","trans_args","args_1") then "list<FCode.Exp> ";
        case("./rmltests/petrol/flatten.rml","trans_args","args_2") then "list<FCode.Exp> ";
        case("./rmltests/petrol/flatten.rml","trans_args","args") then "list<TCode.Exp> ";
        case("./rmltests/petrol/flatten.rml","trans_args","arg") then "TCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_args","arg_1") then "FCode.Exp";
        case("./rmltests/petrol/flatten.rml","trans_args","env") then "Env";


    /* Petrol flatten.rml trans_return() types */

        case("./rmltests/petrol/flatten.rml","trans_return","ty") then " TCode.Ty ";
        case("./rmltests/petrol/flatten.rml","trans_return","exp") then " TCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_return","ty1") then " FCode.Ty ";
        case("./rmltests/petrol/flatten.rml","trans_return","exp1") then " FCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_return","env") then "Env";

       /* Petrol flatten.rml trans_stmt() types */

        case("./rmltests/petrol/flatten.rml","trans_stmt","ty") then " TCode.Ty ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","ty1") then " FCode.Ty ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","lhs") then " TCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","rhs") then " TCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","exp") then " TCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","lhs1") then " FCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","rhs1") then " FCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","exp1") then " FCode.Exp ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","env") then " Env ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","id1") then " String";
        case("./rmltests/petrol/flatten.rml","trans_stmt","id") then " String";
        case("./rmltests/petrol/flatten.rml","trans_stmt","ret1") then "Option<tuple<FCode.Ty, FCode.Exp>>";
        case("./rmltests/petrol/flatten.rml","trans_stmt","ret") then "Option<tuple<TCode.Ty, TCode.Exp>>";
        case("./rmltests/petrol/flatten.rml","trans_stmt","args1") then "list<FCode.Exp> ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","args") then "list<TCode.Exp> ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","stmt") then "TCode.Stmt ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","stmt1") then " TCode.Stmt ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","stmt2") then " TCode.Stmt ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","stmt1_1") then "FCode.Stmt ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","stmt_1") then " FCode.Stmt ";
        case("./rmltests/petrol/flatten.rml","trans_stmt","stmt2_1") then " FCode.Stmt ";


        /* Petrol flatten.rml env_plus_vars() types */

        case("./rmltests/petrol/flatten.rml","env_plus_vars","env") then " Env ";
        case("./rmltests/petrol/flatten.rml","env_plus_vars","env1") then " Env ";
        case("./rmltests/petrol/flatten.rml","env_plus_vars","bnd") then " Bnd ";
        case("./rmltests/petrol/flatten.rml","env_plus_vars","vars") then " list<FCode.Var> ";
        case("./rmltests/petrol/flatten.rml","env_plus_vars","id") then " String ";

        /* Petrol flatten.rml flatten_proc() types */

        case("./rmltests/petrol/flatten.rml","flatten_proc","formals") then " list<TCode.Var> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","locals") then " list<TCode.Var> ";

        case("./rmltests/petrol/flatten.rml","flatten_proc","formals1") then " list<FCode.Var> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","locals1") then " list<FCode.Var> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","vars1") then " list<FCode.Var> ";

        case("./rmltests/petrol/flatten.rml","flatten_proc","env0") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","env1") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","env2") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","env3") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","bnd1") then " Bnd ";

        case("./rmltests/petrol/flatten.rml","flatten_proc","id") then " String ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","tyopt") then " Option<TCode.Ty> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","tyopt1") then " Option<FCode.Ty> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","proc") then " FCode.Proc ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","fcodeproc") then " FCode.Proc ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","fcodeblock") then " FCode.Block ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","procs") then " list<TCode.Proc> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","stmt") then " TCode.Stmt ";

        case("./rmltests/petrol/flatten.rml","flatten_proc","procs0") then " list<FCode.Proc> ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","procs1") then " list<FCode.Proc> ";

        case("./rmltests/petrol/flatten.rml","flatten_proc","level0") then "  Integer ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","level1") then "  Integer ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","stamp") then "  Integer ";

        case("./rmltests/petrol/flatten.rml","flatten_proc","id1") then " String ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","prefix0") then " String ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","prefix1") then " String ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","r") then "  FCode.Record ";
        case("./rmltests/petrol/flatten.rml","flatten_proc","stmt1") then "  FCode.Stmt ";



         /* Petrol flatten.rml flatten_procs() types */

        case("./rmltests/petrol/flatten.rml","flatten_procs","env0") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","env1") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","env2") then " Env ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","procs0") then " list<FCode.Proc> ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","procs1") then " list<FCode.Proc> ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","procs2") then " list<FCode.Proc> ";

        case("./rmltests/petrol/flatten.rml","flatten_procs","scope") then " Scope ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","proc") then " TCode.Proc ";
        case("./rmltests/petrol/flatten.rml","flatten_procs","procs") then " list<TCode.Proc> ";

         /* Petrol flatten.rml flatten() types */

        case("./rmltests/petrol/flatten.rml","flatten","id") then " String ";
        case("./rmltests/petrol/flatten.rml","flatten","proc1") then " TCode.Proc ";
        case("./rmltests/petrol/flatten.rml","flatten","block_") then " TCode.Block  ";
        case("./rmltests/petrol/flatten.rml","flatten","procs1") then " list<FCode.Proc> ";


          /* Petrol static.rml map() types */

        case("./rmltests/petrol/static.rml","map","x") then "a";
        case("./rmltests/petrol/static.rml","map","y") then "b";
        case("./rmltests/petrol/static.rml","map","F") then "FuncType";
        case("./rmltests/petrol/static.rml","map","xs") then "alist";
        case("./rmltests/petrol/static.rml","map","ys") then "blist";



        /* Petrol static.rml lookup1() types */

        case("./rmltests/petrol/static.rml","lookup1","key1") then " String ";
        case("./rmltests/petrol/static.rml","lookup1","key0") then " String ";
        case("./rmltests/petrol/static.rml","lookup1","ty") then " Types.Ty  ";
        case("./rmltests/petrol/static.rml","lookup1","r") then " Env1 ";

           /* Petrol static.rml lookup() types */

        case("./rmltests/petrol/static.rml","lookup","key1") then " TCode.Ident ";
        case("./rmltests/petrol/static.rml","lookup","key0") then " TCode.Ident ";
        case("./rmltests/petrol/static.rml","lookup","env") then " Env ";
        case("./rmltests/petrol/static.rml","lookup","bnd") then " Bnd ";

         /* Petrol static.rml elab_constant() types */

        case("./rmltests/petrol/static.rml","elab_constant","i") then " Integer ";
        case("./rmltests/petrol/static.rml","elab_constant","r") then " Real ";
        case("./rmltests/petrol/static.rml","elab_constant","env") then " Env ";
        case("./rmltests/petrol/static.rml","elab_constant","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_constant","c") then " Con ";

        /* Petrol static.rml elab_const() types */

        case("./rmltests/petrol/static.rml","elab_const","con") then " Con ";
        case("./rmltests/petrol/static.rml","elab_const","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_const","env0") then " Env ";
        case("./rmltests/petrol/static.rml","elab_const","c") then " Absyn.Constant ";


        /* Petrol static.rml elab_consts() types */

        case("./rmltests/petrol/static.rml","elab_consts","consts") then " list<Absyn.ConBnd> ";
        case("./rmltests/petrol/static.rml","elab_consts","env2") then " Env ";
        case("./rmltests/petrol/static.rml","elab_consts","env1") then " Env ";
        case("./rmltests/petrol/static.rml","elab_consts","env") then " Env ";
        case("./rmltests/petrol/static.rml","elab_consts","c") then "  Absyn.ConBnd ";

       /* Petrol static.rml elab_ty() types */

        case("./rmltests/petrol/static.rml","elab_ty","env") then " Env ";
        case("./rmltests/petrol/static.rml","elab_ty","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_ty","ty") then "  Absyn.Ty ";
        case("./rmltests/petrol/static.rml","elab_ty","ty1") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_ty","c") then " Absyn.Constant ";
        case("./rmltests/petrol/static.rml","elab_ty","sz") then " Integer ";
        case("./rmltests/petrol/static.rml","elab_ty","stamp") then " Integer ";
        case("./rmltests/petrol/static.rml","elab_ty","bnds") then " list<Absyn.VarBnd> ";
        case("./rmltests/petrol/static.rml","elab_ty","bnds1") then " list<tuple<String, Types.Ty>> ";

        /* Petrol static.rml elab_ty_bnds() types */

        case("./rmltests/petrol/static.rml","elab_ty_bnds","env") then " Env ";
        case("./rmltests/petrol/static.rml","elab_ty_bnds","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_ty_bnds","ty") then "  Absyn.Ty ";
        case("./rmltests/petrol/static.rml","elab_ty_bnds","ty1") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_ty_bnds","bnds") then " list<Absyn.VarBnd> ";
        case("./rmltests/petrol/static.rml","elab_ty_bnds","bnds1") then "  list<tuple<String, Types.Ty>> ";
        case("./rmltests/petrol/static.rml","elab_ty_bnds","bnds2") then "  list<tuple<String, Types.Ty>> ";

       /* Petrol static.rml elab_types() types */

        case("./rmltests/petrol/static.rml","elab_types","env") then " Env ";
        case("./rmltests/petrol/static.rml","elab_types","env1") then " Env ";
        case("./rmltests/petrol/static.rml","elab_types","env2") then " Env ";
        case("./rmltests/petrol/static.rml","elab_types","tybnd") then " Absyn.TyBnd ";
        case("./rmltests/petrol/static.rml","elab_types","tybnds") then " list<Absyn.TyBnd> ";
        case("./rmltests/petrol/static.rml","elab_types","ty1") then "  Types.Ty ";

       /* Petrol static.rml elab_tybnd() types */

        case("./rmltests/petrol/static.rml","elab_tybnd","xxx") then "  IsRec ";
        case("./rmltests/petrol/static.rml","elab_tybnd","ty") then " Absyn.Ty ";
        case("./rmltests/petrol/static.rml","elab_tybnd","ty1") then " Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_tybnd","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_tybnd","env0") then " Env ";


       /* Petrol static.rml elab_tybnd1() types */

        case("./rmltests/petrol/static.rml","elab_tybnd1","stamp") then " Integer ";
        case("./rmltests/petrol/static.rml","elab_tybnd1","bnds") then " list<Absyn.VarBnd> ";
        case("./rmltests/petrol/static.rml","elab_tybnd1","bnds1") then "list<tuple<String, Types.Ty>> ";
        case("./rmltests/petrol/static.rml","elab_tybnd1","ty") then " Absyn.Ty ";
        case("./rmltests/petrol/static.rml","elab_tybnd1","ty1") then " Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_tybnd1","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_tybnd1","env0") then " Env ";

          /* Petrol static.rml check_bnds() types */

        case("./rmltests/petrol/static.rml","check_bnds","ty") then " Types.Ty ";
        case("./rmltests/petrol/static.rml","check_bnds","bnds") then "list<tuple<String, Types.Ty>> ";

          /* Petrol static.rml check_ty() types */

        case("./rmltests/petrol/static.rml","check_ty","ty") then " Types.Ty ";
        case("./rmltests/petrol/static.rml","check_ty","bnds") then "list<tuple<String, Types.Ty>> ";

        /* Petrol static.rml isrec() types */

        case("./rmltests/petrol/static.rml","isrec","ty") then " Absyn.Ty ";
        case("./rmltests/petrol/static.rml","isrec","bnds") then " list<Absyn.VarBnd> ";

       /* Petrol static.rml elab_rvalue() types */

        case("./rmltests/petrol/static.rml","elab_rvalue","env") then " Env ";
        case("./rmltests/petrol/static.rml","elab_rvalue","r") then " Real ";
        case("./rmltests/petrol/static.rml","elab_rvalue","i") then " Integer ";
        case("./rmltests/petrol/static.rml","elab_rvalue","bnd") then " Bnd ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp") then " TCode.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp_1") then " TCode.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp_2") then " TCode.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp1_1") then " TCode.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp2_1") then " TCode.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp3") then " TCode.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","aty") then "  Absyn.Ty ";

        case("./rmltests/petrol/static.rml","elab_rvalue","ty") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","ty_1") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","ty_2") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","rty") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","rty1") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","rty2") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","rty3") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","resty") then "  Types.Ty ";
        case("./rmltests/petrol/static.rml","elab_rvalue","aexp") then " Absyn.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp1") then " Absyn.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","exp2") then " Absyn.Exp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","id") then " String ";
        case("./rmltests/petrol/static.rml","elab_rvalue","unop") then " Absyn.UnOp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","binop") then " Absyn.BinOp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","relop") then " Absyn.RelOp ";
        case("./rmltests/petrol/static.rml","elab_rvalue","argtys") then "  list<Types.Ty> ";
        case("./rmltests/petrol/static.rml","elab_rvalue","args") then "  list<Absyn.Exp> ";
        case("./rmltests/petrol/static.rml","elab_rvalue","args_1") then "  list<TCode.Exp> ";

        /* Petrol static.rml elab_unary_rvalue() types */

        case("./rmltests/petrol/static.rml","elab_unary_rvalue","env") then " Env ";
           case("./rmltests/petrol/static.rml","elab_unary_rvalue","exp") then " Absyn.Exp ";
           case("./rmltests/petrol/static.rml","elab_unary_rvalue","ty") then " Types.Ty ";
           case("./rmltests/petrol/static.rml","elab_unary_rvalue","exp1") then " TCode.Exp ";
           case("./rmltests/petrol/static.rml","elab_unary_rvalue","exp2") then " TCode.Exp ";
           case("./rmltests/petrol/static.rml","elab_unary_rvalue","ty1") then " TCode.Ty ";

     /* Petrol static.rml elab_rvalue_decay() types */

         case("./rmltests/petrol/static.rml","elab_rvalue_decay","env") then " Env ";
         case("./rmltests/petrol/static.rml","elab_rvalue_decay","exp") then " Absyn.Exp ";
         case("./rmltests/petrol/static.rml","elab_rvalue_decay","ty") then " Types.Ty ";
         case("./rmltests/petrol/static.rml","elab_rvalue_decay","ty1") then " Types.Ty ";
         case("./rmltests/petrol/static.rml","elab_rvalue_decay","exp1") then " TCode.Exp ";
         case("./rmltests/petrol/static.rml","elab_rvalue_decay","exp2") then " TCode.Exp ";

       /* Petrol static.rml rvalue_id() types */

         case("./rmltests/petrol/static.rml","rvalue_id","i") then "Integer";
         case("./rmltests/petrol/static.rml","rvalue_id","r") then "Real";
         case("./rmltests/petrol/static.rml","rvalue_id","id") then "String";
         case("./rmltests/petrol/static.rml","rvalue_id","exp1") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","rvalue_id","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","rvalue_id","ty1") then "Types.Ty";

         /* Petrol static.rml rvalue_var() types */

         case("./rmltests/petrol/static.rml","rvalue_var","exp") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","rvalue_var","addr") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","rvalue_var","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","rvalue_var","ty1") then "TCode.Ty";

         /* Petrol static.rml mkload() types */

         case("./rmltests/petrol/static.rml","mkload","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","mkload","addr") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","mkload","ty1") then "TCode.Ty";

        /* Petrol static.rml elab_arg() types */
         case("./rmltests/petrol/static.rml","elab_arg","env") then "Env";
         case("./rmltests/petrol/static.rml","elab_arg","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","elab_arg","ty1") then "Types.Ty";
         case("./rmltests/petrol/static.rml","elab_arg","exp") then "Absyn.Exp";
         case("./rmltests/petrol/static.rml","elab_arg","exp1") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","elab_arg","exp2") then "TCode.Exp";

       /* Petrol static.rml elab_args() types */

         case("./rmltests/petrol/static.rml","elab_args","env") then "Env";
         case("./rmltests/petrol/static.rml","elab_args","args2") then "list<TCode.Exp>";
         case("./rmltests/petrol/static.rml","elab_args","args1") then "list<TCode.Exp>";
         case("./rmltests/petrol/static.rml","elab_args","exps1") then "list<TCode.Exp>";
         case("./rmltests/petrol/static.rml","elab_args","exps2") then "list<TCode.Exp>";
         case("./rmltests/petrol/static.rml","elab_args","exps") then "list<Absyn.Exp>";
         case("./rmltests/petrol/static.rml","elab_args","exp") then "Absyn.Exp";
         case("./rmltests/petrol/static.rml","elab_args","exp1") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","elab_args","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","elab_args","tys") then "list<Types.Ty>";

         /* Petrol static.rml elab_lvalue() types */

         case("./rmltests/petrol/static.rml","elab_lvalue","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","elab_lvalue","env") then "Env";
         case("./rmltests/petrol/static.rml","elab_lvalue","exp1") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","elab_lvalue","exp") then "Absyn.Exp";
         case("./rmltests/petrol/static.rml","elab_lvalue","id") then "String";

         /* Petrol static.rml elab_field() types */

         case("./rmltests/petrol/static.rml","elab_field","ty") then "Types.Ty";
         case("./rmltests/petrol/static.rml","elab_field","exp1") then "TCode.Exp";
         case("./rmltests/petrol/static.rml","elab_field","r") then "Types.Record";
         case("./rmltests/petrol/static.rml","elab_field","bnds") then "Env1";
         case("./rmltests/petrol/static.rml","elab_field","r1") then "TCode.Record";
         case("./rmltests/petrol/static.rml","elab_field","exp") then "Absyn.Exp";
         case("./rmltests/petrol/static.rml","elab_field","env") then "Env";
         case("./rmltests/petrol/static.rml","elab_field","id") then "String";

                 /* Petrol static.rml elab_stmt() types */

         case("./rmltests/petrol/static.rml","elab_stmt","lval") then "TCode.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","rval") then "TCode.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","rval1") then "TCode.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","exp1") then "TCode.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","exp2") then "TCode.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","lvalty") then "Types.Ty";
           case("./rmltests/petrol/static.rml","elab_stmt","rvalty") then "Types.Ty";
           case("./rmltests/petrol/static.rml","elab_stmt","ety") then "Types.Ty";
           case("./rmltests/petrol/static.rml","elab_stmt","rty") then "Types.Ty";
           case("./rmltests/petrol/static.rml","elab_stmt","lvalty1") then "TCode.Ty";
           case("./rmltests/petrol/static.rml","elab_stmt","rty1") then "TCode.Ty";
           case("./rmltests/petrol/static.rml","elab_stmt","env") then "Env";
           case("./rmltests/petrol/static.rml","elab_stmt","lhs") then "Absyn.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","rhs") then "Absyn.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","exp") then "Absyn.Exp";
           case("./rmltests/petrol/static.rml","elab_stmt","fty") then "list<Types.Ty>";
           case("./rmltests/petrol/static.rml","elab_stmt","argtys") then "list<Types.Ty>";
           case("./rmltests/petrol/static.rml","elab_stmt","args1") then "list<TCode.Exp>";
           case("./rmltests/petrol/static.rml","elab_stmt","args") then "list<Absyn.Exp>";
           case("./rmltests/petrol/static.rml","elab_stmt","id") then "String";
           case("./rmltests/petrol/static.rml","elab_stmt","stmt") then "Absyn.Stmt";
           case("./rmltests/petrol/static.rml","elab_stmt","stmt1") then "Absyn.Stmt";
           case("./rmltests/petrol/static.rml","elab_stmt","stmt2") then "Absyn.Stmt";
           case("./rmltests/petrol/static.rml","elab_stmt","stmt1_1") then "TCode.Stmt";
           case("./rmltests/petrol/static.rml","elab_stmt","stmt2_1") then "TCode.Stmt";
           case("./rmltests/petrol/static.rml","elab_stmt","stmt_1") then "TCode.Stmt";
           case("./rmltests/petrol/static.rml","elab_stmt","oty") then "Option<Types.Ty>";

          /* Petrol static.rml elab_vars() types */

           case("./rmltests/petrol/static.rml","elab_vars","vars2") then "Env1";
           case("./rmltests/petrol/static.rml","elab_vars","vars1") then "Env1";
           case("./rmltests/petrol/static.rml","elab_vars","env") then "Env";
           case("./rmltests/petrol/static.rml","elab_vars","ty") then "Types.Ty";
           case("./rmltests/petrol/static.rml","elab_vars","var") then "Absyn.VarBnd";
           case("./rmltests/petrol/static.rml","elab_vars","vars") then "list<Absyn.VarBnd>";
           case("./rmltests/petrol/static.rml","elab_vars","id") then "String";

         /* Petrol static.rml elab_var() types */

           case("./rmltests/petrol/static.rml","elab_var","id") then "String";
           case("./rmltests/petrol/static.rml","elab_var","ty") then "Absyn.Ty";
           case("./rmltests/petrol/static.rml","elab_var","ty1") then "Types.Ty";

           case("./rmltests/petrol/static.rml","elab_var","env") then "Env";

        /* Petrol static.rml mkvar() types */

           case("./rmltests/petrol/static.rml","mkvar","id") then "String";
           case("./rmltests/petrol/static.rml","mkvar","ty") then "Types.Ty";
           case("./rmltests/petrol/static.rml","mkvar","ty1") then "TCode.Ty";

        /* Petrol static.rml mkvarbnd() types */

           case("./rmltests/petrol/static.rml","mkvarbnd","id") then "String";
           case("./rmltests/petrol/static.rml","mkvarbnd","ty") then "Types.Ty";

        /* Petrol static.rml elab_formals() types */

           case("./rmltests/petrol/static.rml","elab_formals","pre_formals") then " list<tuple<String, Types.Ty>> ";
           case("./rmltests/petrol/static.rml","elab_formals","pre_formals1") then " list<tuple<String, Types.Ty>> ";
           case("./rmltests/petrol/static.rml","elab_formals","argenv") then "list<tuple<String, Bnd>>";
           case("./rmltests/petrol/static.rml","elab_formals","env") then "Env";
           case("./rmltests/petrol/static.rml","elab_formals","argtys") then "list<Types.Ty> ";
           case("./rmltests/petrol/static.rml","elab_formals","formals") then "list<Absyn.VarBnd>";
           case("./rmltests/petrol/static.rml","elab_formals","formals1") then "list<TCode.Var>";

                /* Petrol static.rml extract_ty() types */
          case("./rmltests/petrol/static.rml","extract_ty","y") then "Types.Ty";

          /* Petrol static.rml decay_formal_ty() types */
          case("./rmltests/petrol/static.rml","decay_formal_ty","ty") then "Types.Ty";

        /* Petrol static.rml decay_formal_ty() types */
          case("./rmltests/petrol/static.rml","decay_formal","ty") then "Types.Ty";
          case("./rmltests/petrol/static.rml","decay_formal","ty1") then "Types.Ty";
          case("./rmltests/petrol/static.rml","decay_formal","id") then "String";

       /* Petrol static.rml elab_subbnd() types */
          case("./rmltests/petrol/static.rml","elab_subbnd","ty0") then "Types.Ty";
          case("./rmltests/petrol/static.rml","elab_subbnd","ty1") then "Types.Ty";
          case("./rmltests/petrol/static.rml","elab_subbnd","ty2") then "TCode.Ty";
          case("./rmltests/petrol/static.rml","elab_subbnd","ty") then "Absyn.Ty";
          case("./rmltests/petrol/static.rml","elab_subbnd","formals1") then "list<TCode.Var>";
          case("./rmltests/petrol/static.rml","elab_subbnd","argenv") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnd","env0") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnd","env1") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnd","env2") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnd","argtys") then "list<Types.Ty>";
          case("./rmltests/petrol/static.rml","elab_subbnd","block_") then "Option<Absyn.Block> ";
          case("./rmltests/petrol/static.rml","elab_subbnd","block1") then "Option<TCode.Block> ";
          case("./rmltests/petrol/static.rml","elab_subbnd","argtys") then "list<Types.Ty>";
          case("./rmltests/petrol/static.rml","elab_subbnd","formals") then "list<Absyn.VarBnd>";
          case("./rmltests/petrol/static.rml","elab_subbnd","id") then "String";
          case("./rmltests/petrol/static.rml","elab_subbnd","bnd") then "Bnd";
          case("./rmltests/petrol/static.rml","elab_subbnd","proc1") then "TCode.Proc";

        /* Petrol static.rml elab_subbnds() types */
          case("./rmltests/petrol/static.rml","elab_subbnds","subbnds2") then "list<TCode.Proc>";
          case("./rmltests/petrol/static.rml","elab_subbnds","subbnds1") then "list<TCode.Proc>";
          case("./rmltests/petrol/static.rml","elab_subbnds","env") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnds","env1") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnds","env2") then "Env";
          case("./rmltests/petrol/static.rml","elab_subbnds","subbnd1") then "TCode.Proc";
          case("./rmltests/petrol/static.rml","elab_subbnds","subbnd") then "Absyn.SubBnd";
          case("./rmltests/petrol/static.rml","elab_subbnds","subbnds") then "list<Absyn.SubBnd>";

        /* Petrol static.rml elab_body() types */
          case("./rmltests/petrol/static.rml","elab_body","block_") then "Absyn.Block ";
          case("./rmltests/petrol/static.rml","elab_body","block1") then "TCode.Block ";
          case("./rmltests/petrol/static.rml","elab_body","fty") then "Option<Types.Ty> ";
          case("./rmltests/petrol/static.rml","elab_body","env") then " Env ";

        /* Petrol static.rml elab_block() types */
          case("./rmltests/petrol/static.rml","elab_block","env0") then " Env ";
          case("./rmltests/petrol/static.rml","elab_block","env1") then " Env ";
          case("./rmltests/petrol/static.rml","elab_block","env2") then " Env ";
          case("./rmltests/petrol/static.rml","elab_block","env3") then " Env ";
          case("./rmltests/petrol/static.rml","elab_block","env4") then " Env ";
          case("./rmltests/petrol/static.rml","elab_block","varenv") then " Env ";
          case("./rmltests/petrol/static.rml","elab_block","pre_vars") then " Env1 ";
          case("./rmltests/petrol/static.rml","elab_block","vars1") then "list<TCode.Var> ";
          case("./rmltests/petrol/static.rml","elab_block","subbnds1") then "list<TCode.Proc> ";
          case("./rmltests/petrol/static.rml","elab_block","stmt1") then "TCode.Stmt ";
          case("./rmltests/petrol/static.rml","elab_block","fty") then "Option<Types.Ty> ";
          case("./rmltests/petrol/static.rml","elab_block","consts") then " list<Absyn.ConBnd> ";
          case("./rmltests/petrol/static.rml","elab_block","consts") then " list<Absyn.ConBnd> ";
          case("./rmltests/petrol/static.rml","elab_block","types") then " list<Absyn.TyBnd> ";
          case("./rmltests/petrol/static.rml","elab_block","vars") then " list<Absyn.VarBnd> ";
          case("./rmltests/petrol/static.rml","elab_block","subbnds") then " list<Absyn.SubBnd> ";
          case("./rmltests/petrol/static.rml","elab_block","stmt") then " Absyn.Stmt ";

        /* Petrol static.rml elaborate() types */
          case("./rmltests/petrol/static.rml","elaborate","id") then " String ";
          case("./rmltests/petrol/static.rml","elaborate","block1") then " TCode.Block ";
          case("./rmltests/petrol/static.rml","elaborate","block_") then " Absyn.Block ";

         /* Petrol types.rml unfold_rec() types */

          case("./rmltests/petrol/types.rml","unfold_rec","r") then " Record ";
          case("./rmltests/petrol/types.rml","unfold_rec","stamp") then " Stamp ";
          case("./rmltests/petrol/types.rml","unfold_rec","bnds") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","unfold_rec","bnds1") then " list<tuple<Ident, Ty>> ";

          /* Petrol types.rml unfold_bnds() types */

          case("./rmltests/petrol/types.rml","unfold_bnds","bnds") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","unfold_bnds","bnds1") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","unfold_bnds","bnds2") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","unfold_bnds","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","unfold_bnds","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","unfold_bnds","id") then " String ";
          case("./rmltests/petrol/types.rml","unfold_bnds","r") then " Record ";

         /* Petrol types.rml unfold_ty() types */

          case("./rmltests/petrol/types.rml","unfold_ty","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","unfold_ty","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","unfold_ty","r") then " Record ";
          case("./rmltests/petrol/types.rml","unfold_ty","sz") then " Stamp ";
          case("./rmltests/petrol/types.rml","unfold_ty","stamp") then " Stamp ";
          case("./rmltests/petrol/types.rml","unfold_ty","stamp1") then " Stamp ";
          case("./rmltests/petrol/types.rml","unfold_ty","bnds") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","unfold_ty","bnds1") then " list<tuple<Ident, Ty>> ";

         /* Petrol types.rml ty_cnv() types */

          case("./rmltests/petrol/types.rml","ty_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","ty_cnv","ty1") then " TCode.Ty ";
          case("./rmltests/petrol/types.rml","ty_cnv","sz") then " Stamp ";
          case("./rmltests/petrol/types.rml","ty_cnv","stamp") then " Stamp ";
          case("./rmltests/petrol/types.rml","ty_cnv","r") then " Record ";
          case("./rmltests/petrol/types.rml","ty_cnv","r1") then " TCode.Record ";

         /* Petrol types.rml rec_cnv() types */

          case("./rmltests/petrol/types.rml","rec_cnv","bnds") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","rec_cnv","stamp") then " Stamp ";
          case("./rmltests/petrol/types.rml","rec_cnv","bnds1") then " list<TCode.Var> ";

         /* Petrol types.rml bnds_cnv() types */

          case("./rmltests/petrol/types.rml","bnds_cnv","bnds1") then " list<TCode.Var> ";
          case("./rmltests/petrol/types.rml","bnds_cnv","bnds2") then " list<TCode.Var> ";
          case("./rmltests/petrol/types.rml","bnds_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","bnds_cnv","ty1") then "TCode.Ty";
          case("./rmltests/petrol/types.rml","bnds_cnv","var") then " String ";
          case("./rmltests/petrol/types.rml","bnds_cnv","bnds") then " list<tuple<Ident, Ty>> ";
          case("./rmltests/petrol/types.rml","bnds_cnv","var1") then " TCode.Var ";

          /* Petrol types.rml decay() types */

          case("./rmltests/petrol/types.rml","decay","exp") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","decay","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","decay","ty1") then " TCode.Ty ";

          /* Petrol types.rml asg_cnv() types */

          case("./rmltests/petrol/types.rml","asg_cnv","rhs") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","asg_cnv","rhs1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","asg_cnv","aty1") then " ATy ";
          case("./rmltests/petrol/types.rml","asg_cnv","aty2") then " ATy ";
          case("./rmltests/petrol/types.rml","asg_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","asg_cnv","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","asg_cnv","ty2") then " Ty ";
          case("./rmltests/petrol/types.rml","asg_cnv","ty_1") then "  TCode.Ty ";
          case("./rmltests/petrol/types.rml","asg_cnv","stamp2") then "  Stamp ";
          case("./rmltests/petrol/types.rml","asg_cnv","stamp1") then "  Stamp ";

                 /* Petrol types.rml asg_cnv1() types */

          case("./rmltests/petrol/types.rml","asg_cnv1","rhs") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","asg_cnv1","exp1") then " TCode.Exp ";

          /* Petrol types.rml cast_cnv() types */

          case("./rmltests/petrol/types.rml","cast_cnv","exp") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","cast_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","cast_cnv","aty1") then " ATy ";
          case("./rmltests/petrol/types.rml","cast_cnv","aty2") then " ATy ";
          case("./rmltests/petrol/types.rml","cast_cnv","aty") then " ATy ";
          case("./rmltests/petrol/types.rml","cast_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","cast_cnv","ty2") then " Ty ";
          case("./rmltests/petrol/types.rml","cast_cnv","ty2_1") then " TCode.Ty ";
          case("./rmltests/petrol/types.rml","cast_cnv","ty_1") then " TCode.Ty ";

         /* Petrol types.rml cond_cnv() types */

          case("./rmltests/petrol/types.rml","cond_cnv","exp") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","cond_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","cond_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","cond_cnv","ty1") then " TCode.Ty ";

          /* Petrol types.rml eq_cnv() types */

          case("./rmltests/petrol/types.rml","eq_cnv","exp") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","eq_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","eq_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","eq_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","eq_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","eq_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","eq_cnv","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","eq_cnv","ty2") then " Ty ";
          case("./rmltests/petrol/types.rml","eq_cnv","raty1") then " ATy ";
          case("./rmltests/petrol/types.rml","eq_cnv","raty2") then " ATy ";
          case("./rmltests/petrol/types.rml","eq_cnv","raty3") then " ATy ";
          case("./rmltests/petrol/types.rml","eq_cnv","bop") then "  TCode.BinOp ";

          case("./rmltests/petrol/types.rml","eq_cnv","ty_1") then " TCode.Ty ";

          /* Petrol types.rml ptr_eq_null() types */

          case("./rmltests/petrol/types.rml","ptr_eq_null","exp") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","ptr_eq_null","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","ptr_eq_null","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","ptr_eq_null","ty1") then " TCode.Ty ";

         /* Petrol types.rml choose_int_real() types */

          case("./rmltests/petrol/types.rml","choose_int_real","x") then " TCode.BinOp ";
          case("./rmltests/petrol/types.rml","choose_int_real","y") then " TCode.BinOp ";

        /* Petrol types.rml arith_cnv() types */

          case("./rmltests/petrol/types.rml","arith_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","arith_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","arith_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","arith_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","arith_cnv","raty1") then " ATy ";
          case("./rmltests/petrol/types.rml","arith_cnv","raty2") then " ATy ";
          case("./rmltests/petrol/types.rml","arith_cnv","raty3") then " ATy ";

        /* Petrol types.rml arith_lub() types */

          case("./rmltests/petrol/types.rml","arith_lub","y") then " ATy ";

       /* Petrol types.rml arith_widen() types */

          case("./rmltests/petrol/types.rml","arith_widen","exp") then " TCode.Exp ";

       /* Petrol types.rml rel_cnv() types */

          case("./rmltests/petrol/types.rml","rel_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rel_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rel_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rel_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rel_cnv","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","rel_cnv","ty2") then " Ty ";
          case("./rmltests/petrol/types.rml","rel_cnv","ty_1") then " TCode.Ty ";
          case("./rmltests/petrol/types.rml","rel_cnv","raty1") then " ATy ";
          case("./rmltests/petrol/types.rml","rel_cnv","raty2") then " ATy ";
          case("./rmltests/petrol/types.rml","rel_cnv","raty3") then " ATy ";
          case("./rmltests/petrol/types.rml","rel_cnv","relop") then " Absyn.RelOp ";
          case("./rmltests/petrol/types.rml","rel_cnv","bop") then " TCode.BinOp ";

         /* Petrol types.rml ptr_relop() types */

          case("./rmltests/petrol/types.rml","ptr_relop","ty") then " TCode.Ty ";

       /* Petrol types.rml bin_cnv() types */

          case("./rmltests/petrol/types.rml","bin_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","bin_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","bin_cnv","exp3") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","bin_cnv","rty1") then " Ty ";
          case("./rmltests/petrol/types.rml","bin_cnv","rty2") then " Ty ";
          case("./rmltests/petrol/types.rml","bin_cnv","rty3") then " Ty ";

        /* Petrol types.rml add_cnv() types */

          case("./rmltests/petrol/types.rml","add_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","add_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","add_cnv","exp3") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","add_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","add_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","add_cnv","bop") then " TCode.BinOp ";
          case("./rmltests/petrol/types.rml","add_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","add_cnv","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","add_cnv","ty2") then " Ty ";
          case("./rmltests/petrol/types.rml","add_cnv","ty3") then " Ty ";
          case("./rmltests/petrol/types.rml","add_cnv","raty1") then " ATy ";
          case("./rmltests/petrol/types.rml","add_cnv","raty2") then " ATy ";
          case("./rmltests/petrol/types.rml","add_cnv","raty3") then " ATy ";


         /* Petrol types.rml ptr_add_int_cnv() types */

          case("./rmltests/petrol/types.rml","ptr_add_int_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","ptr_add_int_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","ptr_add_int_cnv","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","ptr_add_int_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","ptr_add_int_cnv","ty1_1") then " TCode.Ty ";

        /* Petrol types.rml add_cnv() types */

          case("./rmltests/petrol/types.rml","sub_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","sub_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","sub_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","sub_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","sub_cnv","ty") then " Ty ";
          case("./rmltests/petrol/types.rml","sub_cnv","ty1") then " Ty ";
          case("./rmltests/petrol/types.rml","sub_cnv","ty2") then " Ty ";
          case("./rmltests/petrol/types.rml","sub_cnv","ty1_1") then " TCode.Ty ";
          case("./rmltests/petrol/types.rml","sub_cnv","bop") then "  TCode.BinOp ";
          case("./rmltests/petrol/types.rml","sub_cnv","raty1") then "  ATy ";
          case("./rmltests/petrol/types.rml","sub_cnv","raty2") then "  ATy ";
          case("./rmltests/petrol/types.rml","sub_cnv","raty3") then "  ATy ";

        /* Petrol types.rml mul_cnv() types */

          case("./rmltests/petrol/types.rml","mul_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","mul_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","mul_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","mul_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","mul_cnv","raty1") then " ATy ";
          case("./rmltests/petrol/types.rml","mul_cnv","raty2") then " ATy ";
          case("./rmltests/petrol/types.rml","mul_cnv","raty3") then " ATy ";
          case("./rmltests/petrol/types.rml","mul_cnv","bop") then " TCode.BinOp ";

        /* Petrol types.rml rdiv_cnv() types */

          case("./rmltests/petrol/types.rml","rdiv_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rdiv_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rdiv_cnv","exp1_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rdiv_cnv","exp2_1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","rdiv_cnv","raty1") then " ATy ";
          case("./rmltests/petrol/types.rml","rdiv_cnv","raty2") then " ATy ";

        /* Petrol types.rml intop_cnv() types */

          case("./rmltests/petrol/types.rml","intop_cnv","exp1") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","intop_cnv","exp2") then " TCode.Exp ";
          case("./rmltests/petrol/types.rml","intop_cnv","bop") then " TCode.BinOp ";


        /* exercise 05b_modassigntwotype*/

         /* modassigntwotype eval.rml intop_cnv() types */

          case("./rmltests/modassigntwotype/eval.rml","lookup","id") then " String ";
          case("./rmltests/modassigntwotype/eval.rml","lookup","id2") then " String ";
          case("./rmltests/modassigntwotype/eval.rml","lookup","value") then " Value ";
          case("./rmltests/modassigntwotype/eval.rml","lookup","rest") then " Env ";

        /* modassigntwotype eval.rml lookupextend() types */

          case("./rmltests/modassigntwotype/eval.rml","lookupextend","id") then " String ";
          case("./rmltests/modassigntwotype/eval.rml","lookupextend","env") then " Env ";
          case("./rmltests/modassigntwotype/eval.rml","lookupextend","value") then " Value ";
          case("./rmltests/modassigntwotype/eval.rml","lookupextend","v") then " Value ";

       /* modassigntwotype eval.rml update() types */

          case("./rmltests/modassigntwotype/eval.rml","update","id") then " String ";
          case("./rmltests/modassigntwotype/eval.rml","update","env") then " Env ";
          case("./rmltests/modassigntwotype/eval.rml","update","value") then " Value ";

       /* modassigntwotype eval.rml type_lub() types */

          case("./rmltests/modassigntwotype/eval.rml","type_lub","x") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","type_lub","y") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","type_lub","x2") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","type_lub","y2") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","type_lub","rx") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","type_lub","ry") then " Real ";

        /* modassigntwotype eval.rml apply_int_binop() types */

          case("./rmltests/modassigntwotype/eval.rml","apply_int_binop","x") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","apply_int_binop","y") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","apply_int_binop","z") then " Integer ";

         /* modassigntwotype eval.rml apply_real_binop() types */

          case("./rmltests/modassigntwotype/eval.rml","apply_real_binop","x") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","apply_real_binop","y") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","apply_real_binop","z") then " Real ";

        /* modassigntwotype eval.rml apply_int_unop() types */

          case("./rmltests/modassigntwotype/eval.rml","apply_int_unop","x") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","apply_int_unop","y") then " Integer ";

        /* modassigntwotype eval.rml apply_real_unop() types */

          case("./rmltests/modassigntwotype/eval.rml","apply_real_unop","x") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","apply_real_unop","y") then " Real ";

         /* modassigntwotype eval.rml apply_real_unop() types */

          case("./rmltests/modassigntwotype/eval.rml","eval","env") then " Env ";
          case("./rmltests/modassigntwotype/eval.rml","eval","env1") then " Env ";
          case("./rmltests/modassigntwotype/eval.rml","eval","env2") then " Env ";
          case("./rmltests/modassigntwotype/eval.rml","eval","ival") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","eval","x") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","eval","y") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","eval","z") then " Integer ";
          case("./rmltests/modassigntwotype/eval.rml","eval","rval") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","eval","rx") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","eval","ry") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","eval","rz") then " Real ";
          case("./rmltests/modassigntwotype/eval.rml","eval","value") then " Value ";
          case("./rmltests/modassigntwotype/eval.rml","eval","v1") then " Value ";
          case("./rmltests/modassigntwotype/eval.rml","eval","v2") then " Value ";
          case("./rmltests/modassigntwotype/eval.rml","eval","e") then " Absyn.Exp ";
          case("./rmltests/modassigntwotype/eval.rml","eval","e1") then " Absyn.Exp ";
          case("./rmltests/modassigntwotype/eval.rml","eval","e2") then " Absyn.Exp ";
          case("./rmltests/modassigntwotype/eval.rml","eval","exp") then " Absyn.Exp ";
          case("./rmltests/modassigntwotype/eval.rml","eval","binop") then " Absyn.BinOp ";
          case("./rmltests/modassigntwotype/eval.rml","eval","unop") then " Absyn.UnOp ";
          case("./rmltests/modassigntwotype/eval.rml","eval","id") then " String ";

          /* modassigntwotype eval.rml apply_real_unop() types */

          case("./rmltests/modassigntwotype/main.rml","printvalue","x") then " Integer ";
          case("./rmltests/modassigntwotype/main.rml","printvalue","rx") then " Real ";
          case("./rmltests/modassigntwotype/main.rml","printvalue","x1") then " String ";

          /* modassigntwotype eval.rml eval_loop() types */

          case("./rmltests/modassigntwotype/main.rml","eval_loop","ast") then " Absyn.Exp ";
          case("./rmltests/modassigntwotype/main.rml","eval_loop","env") then " list<tuple<String,Eval.Value>> ";
          case("./rmltests/modassigntwotype/main.rml","eval_loop","env2") then " list<tuple<String,Eval.Value>> ";
          case("./rmltests/modassigntwotype/main.rml","eval_loop","value") then " Eval.Value ";

         /* modassigntwotype eval.rml apply_real_unop() types */

          case("./rmltests/modassigntwotype/main.rml","printvalue","x") then " Integer ";
          case("./rmltests/modassigntwotype/main.rml","printvalue","rx") then " Real ";
          case("./rmltests/modassigntwotype/main.rml","printvalue","x1") then " String ";

         /*05a_assigntwotype assigntwotype.rml printvalue() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","printvalue","x") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","printvalue","rx") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","printvalue","x1") then " String ";

        /*05a_assigntwotype assigntwotype.rml evalprogram() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","evalprogram","assignments") then " list<Exp> ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evalprogram","assignments1") then " list<Exp> ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evalprogram","exp") then " Exp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evalprogram","value") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evalprogram","env2") then " Env ";


         /*05a_assigntwotype assigntwotype.rml evals() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","evals","e") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evals","env") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evals","env2") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evals","env3") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evals","exp") then " Exp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","evals","exp1") then " list<Exp> ";

         /*05a_assigntwotype assigntwotype.rml eval() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","eval","env") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","env1") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","env2") then " Env ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","ival") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","x") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","y") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","z") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","rval") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","rx") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","ry") then " Real ";

          case("./rmltests/assigntwotype/assigntwotype.rml","eval","rz") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","value") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","v1") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","v2") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","sval") then " String ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","id") then " String ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","e") then " Exp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","e1") then " Exp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","e2") then " Exp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","exp") then " Exp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","binop") then " BinOp ";
          case("./rmltests/assigntwotype/assigntwotype.rml","eval","unop") then " UnOp ";

          /*05a_assigntwotype assigntwotype.rml type_lub() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","type_lub","x") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","type_lub","y") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","type_lub","x2") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","type_lub","y2") then " Real ";

           /*05a_assigntwotype assigntwotype.rml apply_int_binop() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","apply_int_binop","x") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","apply_int_binop","y") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","apply_int_binop","z") then " Integer ";

           /*05a_assigntwotype assigntwotype.rml apply_real_binop() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","apply_real_binop","x") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","apply_real_binop","y") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","apply_real_binop","z") then " Real ";

          /*05a_assigntwotype assigntwotype.rml apply_int_unop() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","apply_int_unop","x") then " Integer ";
          case("./rmltests/assigntwotype/assigntwotype.rml","apply_int_unop","y") then " Integer ";


          /*05a_assigntwotype assigntwotype.rml apply_real_unop() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","apply_real_unop","x") then " Real ";
          case("./rmltests/assigntwotype/assigntwotype.rml","apply_real_unop","y") then " Real ";

         /*05a_assigntwotype assigntwotype.rml lookup() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","lookup","id") then " String ";
          case("./rmltests/assigntwotype/assigntwotype.rml","lookup","id2") then " String ";
          case("./rmltests/assigntwotype/assigntwotype.rml","lookup","value") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","lookup","rest") then " Env ";

         /*05a_assigntwotype assigntwotype.rml lookupextend() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","lookupextend","id") then " String ";
          case("./rmltests/assigntwotype/assigntwotype.rml","lookupextend","v") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","lookupextend","value") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","lookupextend","env") then " Env ";

          /*05a_assigntwotype assigntwotype.rml update() types */

          case("./rmltests/assigntwotype/assigntwotype.rml","update","id") then " String ";
          case("./rmltests/assigntwotype/assigntwotype.rml","update","value") then " Value ";
          case("./rmltests/assigntwotype/assigntwotype.rml","update","env") then " Env ";


          /*05a_assignment assignment.rml lookup() types */

          case("./rmltests/assignment/assignment.rml","lookup","id") then " String ";
          case("./rmltests/assignment/assignment.rml","lookup","id2") then " String ";
          case("./rmltests/assignment/assignment.rml","lookup","value") then " Value ";
          case("./rmltests/assignment/assignment.rml","lookup","rest") then " Env ";

         /*05a_assignment assignment.rml lookupextend() types */

          case("./rmltests/assignment/assignment.rml","lookupextend","id") then " String ";
          case("./rmltests/assignment/assignment.rml","lookupextend","v") then " Value ";
          case("./rmltests/assignment/assignment.rml","lookupextend","value") then " Value ";
          case("./rmltests/assignment/assignment.rml","lookupextend","env") then " Env ";

          /*04_assignment assignment.rml update() types */

          case("./rmltests/assignment/assignment.rml","update","id") then " String ";
          case("./rmltests/assignment/assignment.rml","update","value") then " Value ";
          case("./rmltests/assignment/assignment.rml","update","env") then " Env ";

           /*04_assignment assignment.rml evalprogram() types */

          case("./rmltests/assignment/assignment.rml","evalprogram","assignments") then " list<Exp> ";
          case("./rmltests/assignment/assignment.rml","evalprogram","assignments1") then " list<Exp> ";
          case("./rmltests/assignment/assignment.rml","evalprogram","exp") then " Exp ";
          case("./rmltests/assignment/assignment.rml","evalprogram","value") then " Value ";
          case("./rmltests/assignment/assignment.rml","evalprogram","env2") then " Env ";

           /*04_assignment assignment.rml evals() types */

          case("./rmltests/assignment/assignment.rml","evals","e") then " Env ";
          case("./rmltests/assignment/assignment.rml","evals","env") then " Env ";
          case("./rmltests/assignment/assignment.rml","evals","env2") then " Env ";
          case("./rmltests/assignment/assignment.rml","evals","env3") then " Env ";
          case("./rmltests/assignment/assignment.rml","evals","v") then " Value ";
          case("./rmltests/assignment/assignment.rml","evals","s") then " String ";
          case("./rmltests/assignment/assignment.rml","evals","exp") then " Exp ";
          case("./rmltests/assignment/assignment.rml","evals","exp1") then " list<Exp> ";

         /*04_assignment assignment.rml eval() types */

          case("./rmltests/assignment/assignment.rml","eval","env") then " Env ";
          case("./rmltests/assignment/assignment.rml","eval","env1") then " Env ";
          case("./rmltests/assignment/assignment.rml","eval","env2") then " Env ";
          case("./rmltests/assignment/assignment.rml","eval","env3") then " Env ";
          case("./rmltests/assignment/assignment.rml","eval","ival") then " Integer ";
          case("./rmltests/assignment/assignment.rml","eval","x") then " Integer ";
          case("./rmltests/assignment/assignment.rml","eval","y") then " Integer ";
          case("./rmltests/assignment/assignment.rml","eval","z") then " Integer ";
          case("./rmltests/assignment/assignment.rml","eval","rval") then " Real ";
          case("./rmltests/assignment/assignment.rml","eval","rx") then " Real ";
          case("./rmltests/assignment/assignment.rml","eval","ry") then " Real ";
          case("./rmltests/assignment/assignment.rml","eval","rz") then " Real ";
          case("./rmltests/assignment/assignment.rml","eval","value") then " Value ";
          case("./rmltests/assignment/assignment.rml","eval","v1") then " Value ";
          case("./rmltests/assignment/assignment.rml","eval","v2") then " Value ";
          case("./rmltests/assignment/assignment.rml","eval","v3") then " Value ";
          case("./rmltests/assignment/assignment.rml","eval","s") then " String ";
          case("./rmltests/assignment/assignment.rml","eval","id") then " String ";
          case("./rmltests/assignment/assignment.rml","eval","e") then " Exp ";
          case("./rmltests/assignment/assignment.rml","eval","e1") then " Exp ";
          case("./rmltests/assignment/assignment.rml","eval","e2") then " Exp ";
          case("./rmltests/assignment/assignment.rml","eval","exp") then " Exp ";
          case("./rmltests/assignment/assignment.rml","eval","binop") then " BinOp ";
          case("./rmltests/assignment/assignment.rml","eval","unop") then " UnOp ";

          /*04_assignment assignment.rml apply_binop() types */

          case("./rmltests/assignment/assignment.rml","apply_binop","v1") then " Integer ";
          case("./rmltests/assignment/assignment.rml","apply_binop","v2") then " Integer ";
          case("./rmltests/assignment/assignment.rml","apply_binop","v3") then " Integer ";

        /*04_assignment assignment.rml apply_unop() types */

          case("./rmltests/assignment/assignment.rml","apply_unop","v") then " Integer ";
          case("./rmltests/assignment/assignment.rml","apply_unop","v2") then " Integer ";


        /*10_pamtrans trans.rml trans_expr() types */

          case("./rmltests/pamtrans/trans.rml","trans_expr","v") then " Integer ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","id") then " String ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","e1") then " Absyn.Exp ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","e2") then " Absyn.Exp ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","opcode") then " Mcode.MBinOp ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","binop") then " Absyn.BinOp ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","operand2") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","t1") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","t2") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","operand2") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","cod1") then "  list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","cod2") then "  list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_expr","cod3") then "  list<Mcode.MCode> ";

          /*10_pamtrans trans.rml gentemp() types */

          case("./rmltests/pamtrans/trans.rml","gentemp","no") then " Integer ";
          case("./rmltests/pamtrans/trans.rml","genlabel","no") then " Integer ";

         /*10_pamtrans trans.rml list_append3() types */

          case("./rmltests/pamtrans/trans.rml","list_append3","l1") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append3","l2") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append3","l3") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append3","l12") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append3","l13") then " alist ";

        /*10_pamtrans trans.rml list_append5() types */

          case("./rmltests/pamtrans/trans.rml","list_append5","l1") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append5","l2") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append5","l3") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append5","l4") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append5","l5") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append5","l13") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append5","l15") then " alist ";

        /*10_pamtrans trans.rml list_append6() types */

          case("./rmltests/pamtrans/trans.rml","list_append6","l1") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l2") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l3") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l4") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l5") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l6") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l16") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l13") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append6","l46") then " alist ";

        /*10_pamtrans trans.rml list_append10() types */

          case("./rmltests/pamtrans/trans.rml","list_append10","l1") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l2") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l3") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l4") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l5") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l6") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l7") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l8") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l9") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l10") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l110") then " alist ";
          case("./rmltests/pamtrans/trans.rml","list_append10","l15") then " alist ";

        /*10_pamtrans trans.rml trans_comparison() types */
          case("./rmltests/pamtrans/trans.rml","trans_comparison","cod1") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","cod2") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","cod3") then " list<Mcode.MCode> ";

          case("./rmltests/pamtrans/trans.rml","trans_comparison","operand2") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","lab") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","t1") then " Mcode.MOperand ";

          case("./rmltests/pamtrans/trans.rml","trans_comparison","e1") then " Absyn.Exp ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","e2") then " Absyn.Exp ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","relop") then " Absyn.RelOp ";
          case("./rmltests/pamtrans/trans.rml","trans_comparison","jmpop") then " Mcode.MCondJmp ";

        /*10_pamtrans trans.rml trans_stmt() types */
          case("./rmltests/pamtrans/trans.rml","trans_stmt","cod1") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","cod2") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","cod3") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","s1cod") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","s2cod") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","compcod") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","bodycod") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","tocod") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","s1") then " Absyn.Stmt ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","s2") then " Absyn.Stmt ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","stmt1") then " Absyn.Stmt ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","stmt2") then " Absyn.Stmt ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","l1") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","l2") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","t1") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","e1") then " Absyn.Exp ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","comp") then " Absyn.Exp ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","id") then " String ";
          case("./rmltests/pamtrans/trans.rml","trans_stmt","idlist_rest") then " list<String> ";

         /*10_pamtrans trans.rml trans_program() types */
          case("./rmltests/pamtrans/trans.rml","trans_program","cod1") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_program","programcode") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/trans.rml","trans_program","progbody") then " Absyn.Stmt ";

        /*10_pamtrans main.rml trans_program() types */
          case("./rmltests/pamtrans/main.rml","main","mcode") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/main.rml","main","program") then " Absyn.Stmt ";

         /*10_pamtrans emit.rml emit_assembly() types */
          case("./rmltests/pamtrans/emit.rml","emit_assembly","rest") then " list<Mcode.MCode> ";
          case("./rmltests/pamtrans/emit.rml","emit_assembly","instr") then " Mcode.MCode ";

          /*10_pamtrans emit.rml emit_instr() types */
          case("./rmltests/pamtrans/emit.rml","emit_instr","mbinop") then " Mcode.MBinOp ";
          case("./rmltests/pamtrans/emit.rml","emit_instr","op") then " String ";
          case("./rmltests/pamtrans/emit.rml","emit_instr","mopr") then " Mcode.MOperand ";
          case("./rmltests/pamtrans/emit.rml","emit_instr","jmpop") then " Mcode.MCondJmp ";
          case("./rmltests/pamtrans/emit.rml","emit_instr","mlab") then " Mcode.MOperand ";


        /*10_pamtrans emit.rml emit_op_operand() types */
          case("./rmltests/pamtrans/emit.rml","emit_op_operand","mopr") then " Mcode.MOperand  ";
          case("./rmltests/pamtrans/emit.rml","emit_op_operand","opstr") then " String  ";

        /* 10_pamtrans emit.rml emit_int() types */
          case("./rmltests/pamtrans/emit.rml","emit_int","i") then " Integer  ";
          case("./rmltests/pamtrans/emit.rml","emit_int","s") then " String  ";

         /* 10_pamtrans emit.rml emit_moperand() types */
          case("./rmltests/pamtrans/emit.rml","emit_moperand","labno") then " Integer  ";
          case("./rmltests/pamtrans/emit.rml","emit_moperand","number") then " Integer  ";
          case("./rmltests/pamtrans/emit.rml","emit_moperand","tempnr") then " Integer  ";
          case("./rmltests/pamtrans/emit.rml","emit_moperand","id") then " String  ";


     /*02a_exp1 exp1.rml eval() types */
         case("./rmltests/exp1/exp1.rml","eval","ival") then "Integer";
         case("./rmltests/exp1/exp1.rml","eval","v1") then "Integer";
         case("./rmltests/exp1/exp1.rml","eval","v2") then "Integer";
         case("./rmltests/exp1/exp1.rml","eval","v3") then "Integer";
         case("./rmltests/exp1/exp1.rml","eval","e") then "Exp";
         case("./rmltests/exp1/exp1.rml","eval","e1") then "Exp";
         case("./rmltests/exp1/exp1.rml","eval","e2") then "Exp";


        /*02b_exp2 exp2.rml eval() types */
         case("./rmltests/exp2/exp2.rml","eval","ival") then "Integer";
         case("./rmltests/exp2/exp2.rml","eval","v1") then "Integer";
         case("./rmltests/exp2/exp2.rml","eval","v2") then "Integer";
         case("./rmltests/exp2/exp2.rml","eval","v3") then "Integer";
         case("./rmltests/exp2/exp2.rml","eval","e") then "Exp";
         case("./rmltests/exp2/exp2.rml","eval","e1") then "Exp";
         case("./rmltests/exp2/exp2.rml","eval","e2") then "Exp";
         case("./rmltests/exp2/exp2.rml","eval","binop") then "BinOp";
         case("./rmltests/exp2/exp2.rml","eval","unop") then "UnOp";

    /*02b_exp2 exp2.rml apply_binop() types */
         case("./rmltests/exp2/exp2.rml","apply_binop","v1") then "Integer";
         case("./rmltests/exp2/exp2.rml","apply_binop","v2") then "Integer";
         case("./rmltests/exp2/exp2.rml","apply_binop","v3") then "Integer";

         /*02b_exp2 exp2.rml apply_unop() types */
         case("./rmltests/exp2/exp2.rml","apply_unop","v") then "Integer";
         case("./rmltests/exp2/exp2.rml","apply_unop","v2") then "Integer";

         case(_,_,_) then "unknowntype";

  end matchcontinue;
end localdeclarationtypes;



public function readFile
  input String instring;
  output list<String> outstringlist;
  algorithm
    outstringlist:= matchcontinue(instring)
    local
      String id;
      case("eval") then {"Exp","Integer"};
      case("apply_binop") then {"BinOp","Integer"};
      case("apply_unop") then {"UnOp","Integer"};

       // dictionary for PAM relations

      case("eval_stmt") then {"State","Stmt","State"};
      case("repeat_eval") then {"State","Integer","Stmt","State"};
      case("lookup") then {"Env","Ident","Value"};
      case("evalPam") then {"Env","Exp"};
      case(id) then {"unknowntype"};
        end matchcontinue;
end readFile;

end Dict;