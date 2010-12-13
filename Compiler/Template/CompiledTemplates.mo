/*
 * Auto-generated file containing pre-compiled templates for
 * fast code generation. Do not edit manually.
 */

package CompiledTemplates

import TemplCG;

record CompiledTemplateSet
  String name;
  TemplCG.TemplateTreeSequence generateFunctions;
  TemplCG.TemplateTreeSequence generateFunctionBodies;
end CompiledTemplateSet;

uniontype TemplateType
  record GEN_FUNCTIONS end GEN_FUNCTIONS;
  record GEN_BODIES end GEN_BODIES;
end TemplateType;

public function getTemplateFromSet
  input CompiledTemplateSet set;
  input TemplateType ty;
  output TemplCG.TemplateTreeSequence out;
algorithm
  out := matchcontinue (set,ty)
    local
      TemplCG.TemplateTreeSequence out;
    case (CompiledTemplateSet(generateFunctions = out), GEN_FUNCTIONS()) then out;
    case (CompiledTemplateSet(generateFunctionBodies = out), GEN_BODIES()) then out;
  end matchcontinue;
end getTemplateFromSet;

constant list<CompiledTemplateSet> availableTemplates = {
CompiledTemplateSet("C89",{
  TemplCG.TEMPLATE_TEXT("#ifdef __cplusplus\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("extern \"C\" {\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("#endif\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("/* header part */\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_FOR_EACH("Functions","",{
    TemplCG.TEMPLATE_FOR_EACH("ReturnTypeStruct","",{
      TemplCG.TEMPLATE_FOR_EACH("it","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT("\n"),
      TemplCG.TEMPLATE_INDENT()
    }),
    TemplCG.TEMPLATE_COND({
    TemplCG.KeyBody("IsExternal",true,{
      TemplCG.TEMPLATE_FOR_EACH("ReturnType","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT(" "),
      TemplCG.TEMPLATE_FOR_EACH("FunctionName","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT("("),
      TemplCG.TEMPLATE_FOR_EACH("ArgDecl",", ",{
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_TEXT(");\n"),
      TemplCG.TEMPLATE_INDENT()
    })
    }, /* else */ {
      TemplCG.TEMPLATE_TEXT("#ifdef __cplusplus\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("extern \"C\" {\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("#endif\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_FOR_EACH("ExtIncludes","",{
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        }),
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("FunctionName",false,{
        TemplCG.TEMPLATE_TEXT("extern "),
        TemplCG.TEMPLATE_FOR_EACH("ReturnType","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        }),
        TemplCG.TEMPLATE_TEXT(" "),
        TemplCG.TEMPLATE_FOR_EACH("FunctionName","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        }),
        TemplCG.TEMPLATE_TEXT("("),
        TemplCG.TEMPLATE_FOR_EACH("ArgDecl",", ",{
          TemplCG.TEMPLATE_FOR_EACH("it","",{
            TemplCG.TEMPLATE_LOOKUP_KEY("it")
          })
        }),
        TemplCG.TEMPLATE_TEXT(");\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_TEXT("#ifdef __cplusplus\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("}\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("#endif\n"),
      TemplCG.TEMPLATE_INDENT()
    }
    ),
    TemplCG.TEMPLATE_TEXT(" ")
  }),
  TemplCG.TEMPLATE_TEXT(" /* End of header part */\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("/* Body */\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_FOR_EACH("Functions","",{
    TemplCG.TEMPLATE_COND({
    TemplCG.KeyBody("IsExternal",false,{

    })
    }, /* else */ {
      TemplCG.TEMPLATE_FOR_EACH("ReturnType","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT(" "),
      TemplCG.TEMPLATE_FOR_EACH("FunctionName","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT("("),
      TemplCG.TEMPLATE_FOR_EACH("ArgDecl",", ",{
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_TEXT(")\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("{"),
      TemplCG.TEMPLATE_FOR_EACH("VariableDecl","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("VariableDecl",false,{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_FOR_EACH("InitStatement","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("InitStatement",false,{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_FOR_EACH("StatementList","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("StatementList",false,{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_FOR_EACH("Cleanup","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_TEXT("}\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("\n"),
      TemplCG.TEMPLATE_INDENT()
    }
    )
  }),
  TemplCG.TEMPLATE_TEXT("/* End Body */\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("#ifdef __cplusplus\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("}\n"),
  TemplCG.TEMPLATE_INDENT(),
  TemplCG.TEMPLATE_TEXT("#endif\n"),
  TemplCG.TEMPLATE_INDENT()
},{
  TemplCG.TEMPLATE_FOR_EACH("Functions","",{
    TemplCG.TEMPLATE_COND({
    TemplCG.KeyBody("IsExternal",false,{

    })
    }, /* else */ {
      TemplCG.TEMPLATE_FOR_EACH("ReturnType","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT(" "),
      TemplCG.TEMPLATE_FOR_EACH("FunctionName","",{
        TemplCG.TEMPLATE_LOOKUP_KEY("it")
      }),
      TemplCG.TEMPLATE_TEXT("("),
      TemplCG.TEMPLATE_FOR_EACH("ArgDecl",", ",{
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_TEXT(")\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("{"),
      TemplCG.TEMPLATE_FOR_EACH("VariableDecl","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("VariableDecl",false,{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_FOR_EACH("InitStatement","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("InitStatement",false,{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_FOR_EACH("StatementList","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_COND({
      TemplCG.KeyBody("StatementList",false,{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT()
      })
      }, /* else */ {

      }
      ),
      TemplCG.TEMPLATE_FOR_EACH("Cleanup","",{
        TemplCG.TEMPLATE_TEXT("\n"),
        TemplCG.TEMPLATE_INDENT(),
        TemplCG.TEMPLATE_FOR_EACH("it","",{
          TemplCG.TEMPLATE_LOOKUP_KEY("it")
        })
      }),
      TemplCG.TEMPLATE_TEXT("}\n"),
      TemplCG.TEMPLATE_INDENT(),
      TemplCG.TEMPLATE_TEXT("\n"),
      TemplCG.TEMPLATE_INDENT()
    }
    )
  })
})
};
end CompiledTemplates;
