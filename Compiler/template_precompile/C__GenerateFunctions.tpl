#ifdef __cplusplus\n
extern "C" \{\n
#endif\n

/* header part */\n
<Functions:{
<ReturnTypeStruct:{<it>\n}>

<cond
case !IsExternal then {
<ReturnType> <FunctionName>(<ArgDecl:{<it>}", ">);\n
}
else {
#ifdef __cplusplus\n
extern "C" \{\n
#endif\n
<ExtIncludes:{<it>\n}>

<cond
case FunctionName then {
extern <ReturnType> <FunctionName>(<ArgDecl:{<it>}", ">);\n
}>

#ifdef __cplusplus\n
\}\n
#endif\n
}> <! end case IsExternal !>
}> <! end loop Functions !>
/* End of header part */\n

\n
/* Body */\n
<include "C__GenerateFunctionBodies.tpl">
/* End Body */\n
\n
#ifdef __cplusplus\n
\}\n
#endif\n
