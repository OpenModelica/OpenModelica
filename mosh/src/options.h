#ifndef _MYOPTIONS
#define _MYOPTIONS

#include <string>
#include <algorithm>

/* -f */
bool flagSet(char*, int, char**);

/* -f=value */
const std::string * getOption(const char*, int, char **);

/* -f value */
const std::string* getFlagValue(const char *, int , char **);

#endif
