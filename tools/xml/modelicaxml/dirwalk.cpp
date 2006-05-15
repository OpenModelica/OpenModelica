//
//   dirwalk.c
//
//   Adrian Pop
//   adrpo@ida.liu.se
//   2004-11-01


#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "dirwalk.h"
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
			if ( strncmp( &DirName[strlen(DirName)-1], "\\", 1 ) )
				(void) strcat( DirName, "\\" );

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
			char *tmpFile = new char[sizeof(char)*strlen(WFD.cFileName)+1];
			strcpy(tmpFile, WFD.cFileName);
			tmpFile[strlen(WFD.cFileName)] = '\0';
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
