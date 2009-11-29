<Functions:{
<cond
case IsExternal : {}
else {
<ReturnType> <FunctionName>(<ArgDecl:{<it>}", ">)\n
\{
<VariableDecl:{\n<it>}>
<cond case VariableDecl : {\n}>

<InitStatement:{\n<it>}>
<cond case InitStatement : {\n}>

<StatementList:{\n<it>}>
<cond case StatementList : {\n}>

<Cleanup:{\n<it>}>
\}\n
\n
}>
}>
