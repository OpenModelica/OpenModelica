#include "options.h"

#include <string>

using namespace std;

bool flagSet(char *option, int argc, char** argv)
{
  for (int i=0; i<argc;i++) {
    if (("-"+string(option))==string(argv[i])) return true;
  }
  return false;
}
/* returns the value of a flag on the form -flagname=value
 */
const string* getOption(const char *option, int argc, char **argv)
{
  for (int i=0; i<argc;i++) {
    string tmpStr=string(argv[i]);
    if (("-"+string(option))==(tmpStr.substr(0,tmpStr.find("=")))) {
      string str=string(argv[i]);
      return new string(str.substr(str.find("=")+1));
    }
  }
  return NULL;
}
/* returns the value of a flag on the form -flagname value */
const string* getFlagValue(const char *option, int argc, char **argv)
{
  for (int i=0; i<argc;i++) {
    string tmpStr=string(argv[i]);
    if (("-"+string(option))==string(argv[i])) {
      if (argc >= i+1) {
	return new string(argv[i+1]);
      }
    }
  } 
  return NULL;
}
