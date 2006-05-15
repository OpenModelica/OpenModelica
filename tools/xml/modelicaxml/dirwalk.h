
#ifndef _DIRWALK_H_
#define _DIRWALK_H_

#include <list>

typedef std::list <char *> l_list;

extern int getDirectoryStructure(char *, l_list &dirList, int _dlevel=0);
int getFileList(char *currentDir, l_list &fileList, char* fileFilter="*.*");

#endif
