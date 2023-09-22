// name: WithinComment
// keywords:
// status: incorrect
// cflags: -d=-newInst
//
// Checks that the parser doesn't crash on a within-statement followed by a
// commment and nothing else.
//

within P;//

// Result:
// Error processing file: WithinComment1.mo
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
