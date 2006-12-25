
#ifndef _DIRWALK_H_
#define _DIRWALK_H_

#include <list>

// windows part!
#if defined(__MINGW32__) || defined(_MSC_VER)
#define PATH_SEPARATOR "\\"
#else /* Linux */
#define PATH_SEPARATOR "/"
#endif 


typedef std::list <char *> l_list;

extern int getDirectoryStructure(char *, l_list &dirList, int _dlevel=0);
extern int getFileList(char *currentDir, l_list &fileList, char* fileFilter="*.*");
extern bool endsWith( std::string str, std::string suffix ); 

#endif
