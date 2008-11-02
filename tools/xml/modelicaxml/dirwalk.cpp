//
//   dirwalk.c
//
//   Adrian Pop
//   adrpo@ida.liu.se
//   2004-11-01
//   updates: 2006-12-15 added walking for Linux.
//                       this one is generic!
#include "dirwalk.h"

// windows part!
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <iostream>
#include <sstream>
#include <cstdlib>
#include <fstream>



//------------------------------------------------
int getDirectoryStructure(char *_current, l_list &dirList, int _dlevel)
//------------------------------------------------
{
	char            DirName[MAX_PATH];
	static char     CurrDirName[MAX_PATH];
	HANDLE          Hnd;
	WIN32_FIND_DATA WFD;

	if (!_dlevel)
	{
		GetCurrentDirectory( MAX_PATH, CurrDirName );
		//std::cout << "Get:" << CurrDirName << std::endl;
	}

	//  Set the new current directory
	if (!SetCurrentDirectory( _current ))
	{
		std::cerr << "Error: could not open directory: " << _current << std::endl;
		exit(1);
	}

	//std::cout << "+" << _current << " + " << _dlevel << std::endl;

	//  Starts the search
	Hnd = FindFirstFile( "*.*", &WFD );

	if (!_dlevel)
	{
		GetCurrentDirectory( MAX_PATH, DirName );
		// add DirName to dirList
		char *tmpDir = new char[sizeof(char)*strlen(DirName)+1];
		strcpy(tmpDir, DirName);
		tmpDir[strlen(DirName)]='\0';
		dirList.push_back(tmpDir);
		//printf("%s\n", DirName);
	}

	//  loop to get all inside the current directory
	while ( FindNextFile( Hnd, &WFD ) )
	{
		//    If it is a real directory
		if (
			( WFD.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY ) &&
			( strcmp(WFD.cFileName, "..") && strcmp(WFD.cFileName, ".") )
			)
		{
			//       Get the current directory
			GetCurrentDirectory( MAX_PATH, DirName );

			//       Put a "\" if necessary
			if ( strncmp( &DirName[strlen(DirName)-1], PATH_SEPARATOR, 1 ) )
				(void) strcat( DirName, PATH_SEPARATOR );

			//       Create a new path
			(void) strcat( DirName, WFD.cFileName );

			//       Show the new directory
			// add DirName to dirList
			char *tmpDir = new char[sizeof(char)*strlen(DirName)+1];
			strcpy(tmpDir, DirName);
			tmpDir[strlen(DirName)]='\0';
			dirList.push_back(tmpDir);
			//printf("%s\n", DirName);

			//       Make a new call to itself
			getDirectoryStructure( DirName, dirList, ++_dlevel);

			//       Go back one level
			SetCurrentDirectory( ".." );

			_dlevel--;
		}

	} // End while

	// End the search to this call
	(void) FindClose( Hnd );
	if (!_dlevel)
	{
		SetCurrentDirectory( CurrDirName );
		//std::cout << "Set:" << CurrDirName << " + " << _dlevel << std::endl;
	}
	return 1;
}

//-------------------------------------------------------------------------
int getFileList(char *currentDir, l_list &fileList, char* fileFilter)
//-------------------------------------------------------------------------
{
	char            CurrDirName[MAX_PATH];
	HANDLE          Hnd;
	WIN32_FIND_DATA WFD;
	int fileNo = 0;

	GetCurrentDirectory( MAX_PATH, CurrDirName );

	//  Set the new current directory
	SetCurrentDirectory( currentDir );

	//  Starts the search
	Hnd = FindFirstFile( fileFilter, &WFD );

	if (Hnd == INVALID_HANDLE_VALUE)
	{
		SetCurrentDirectory( CurrDirName );
		return 0;
	}

	//  loop to get all inside the current directory
	do
	{
		//    If it is a real file
		if (
			(( WFD.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY )
			!= FILE_ATTRIBUTE_DIRECTORY) &&
			( strcmp(WFD.cFileName, "..") && strcmp(WFD.cFileName, ".") )
			)
		{
			// add filename to fileList
		  char *tmpFile = new char[sizeof(char)*
					   (strlen(WFD.cFileName) +
					    strlen(PATH_SEPARATOR) +
					    strlen(currentDir))+1];
		  tmpFile[0] = '\0';
		  strcat(tmpFile, currentDir);
		  strcat(tmpFile, PATH_SEPARATOR);
		  strcat(tmpFile, WFD.cFileName);
		  fileList.push_back(tmpFile);
		  fileNo++;
		}
	} // End while
	while ( FindNextFile( Hnd, &WFD ) );

	// End the search to this call
	(void) FindClose( Hnd );
	SetCurrentDirectory( CurrDirName );
	return fileNo;
}

#else /* Linux part! */

#include <iostream>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/param.h> /* MAXPATHLEN */
#include <ftw.h>

#define DEPTH 8
#define ERROR -1
l_list dirListGlobal;

using namespace std;

bool endsWith ( std::string str, std::string suffix )
{
  std::string::size_type i = str.rfind( suffix );
  if (i == std::string::npos)
    return false;
  if (i == ( str.size() - suffix.size()))
    return true;
  return false;
}

void CheckErrNo ( const char * path )
{
  switch ( errno )     //  errno is a system global value
    {
    case  EFAULT  :   std::cout << "Path points outside your addr. space:  " << path << std::endl;
      break;

    case  EACCES  :   std::cout << "Access denied:  " << path << std::endl;
      break;

    case  EPERM   :   std::cout << "Permanent Entry:  " << path << std::endl;
      break;

    case  ENOENT  :   std::cout << path << " does not exist." << std::endl;
      break;

    case  EISDIR  :   std::cout << path << " refers to a directory." << std::endl;
      break;

    case  ENOMEM  :   std::cout << path << ".  Insufficient kernel memory. "
			   << "Exiting..." << std::endl;
      exit ( ENOMEM );
      break;

    case  EROFS   :   std::cout << path << " is read only." << std::endl;
      break;

    case ENOTDIR  :   std::cout << path << ".  Component in path not a directory."
			   << std::endl;
      break;
    }
}

//------------------------------------------------
int push_dir(const char *fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf)
//------------------------------------------------
{
   int result = 0;
   switch ( tflag )
      {
      case FTW_F:       /* do nothing on file now. */
	break;

      case FTW_D:
      case FTW_DP:
	dirListGlobal.push_front ( strdup(fpath) );
	break;
      case FTW_DNR:
	std::cout << "Directory cannot be read:  "
	     << fpath << std::endl;
	CheckErrNo ( fpath );
	break;


      case FTW_NS:
	std::cout << "Stat failure on:  "
	     << fpath << std::endl;
	CheckErrNo ( fpath );
	break;

      default:
	std::cout << "Weird flag for file  " << fpath << std::endl;

      }
   return result;
}

//------------------------------------------------
int getDirectoryStructure(char *_current, l_list &dirList, int _dlevel)
//------------------------------------------------
{
  int flags = 0;
  flags |= FTW_DEPTH; /* handle the directory given first, then dive */
  flags |= FTW_PHYS;  /* do not folow symbolic links */
  dirListGlobal.clear(); /* clear the elements! */

  if ( nftw ( _current, push_dir, DEPTH, flags) == ERROR )
  {
      CheckErrNo ( _current );
  }
  dirList = dirListGlobal;

  return 1;
}

int file_select_mo(const struct dirent *entry)
{
  char fileName[MAXPATHLEN];
  int res; char* ptr;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0)) {
    return (0);
  } else {
    ptr = (char*)rindex(entry->d_name, '.');
    if ((ptr != NULL) &&
	((strcmp(ptr, ".mo") == 0))) {
      return (1);
    } else {
      return (0);
    }
  }
}

//-------------------------------------------------------------------------
int getFileList(char *currentDir, l_list &fileList, char* fileFilter)
//-------------------------------------------------------------------------
{
  struct dirent **namelist;
  int n;

  n = scandir(currentDir, &namelist, file_select_mo, NULL);
  if (n < 0)
    perror("scandir");
  else
  {
    for(int i = 0; i <n; i++)
    {
      char *tmpFile = new char[sizeof(char)*
			       (strlen(namelist[i]->d_name) +
				strlen(PATH_SEPARATOR) +
				strlen(currentDir))+1];
      tmpFile[0] = '\0';
      strcat(tmpFile, currentDir);
      strcat(tmpFile, PATH_SEPARATOR);
      strcat(tmpFile, namelist[i]->d_name);
      fileList.push_back(tmpFile);
    }
    free(namelist);
  }
  return 1;
}

#endif
