// stdafx.h : include file for standard system include files,
//  or project specific include files that are used frequently, but
//      are changed infrequently
//
#define _WIN32_WINNT 0x0500
#if !defined(AFX_STDAFX_H__197D03DA_5478_11D2_82E0_00A0246A5B7A__INCLUDED_)
#define AFX_STDAFX_H__197D03DA_5478_11D2_82E0_00A0246A5B7A__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#pragma warning(disable:4290) // Disable: C++ Exception Specification ignored.
#pragma warning(disable:4786) // Disable: identifier was truncated to '255' characters in the debug information
#endif // _MSC_VER >= 1000

#define VC_EXTRALEAN		// Exclude rarely-used stuff from Windows headers

//#include <afxwin.h>         // MFC core and standard components
//#include <afxext.h>         // MFC extensions
//#include <afxcview.h>
#ifndef _AFX_NO_AFXCMN_SUPPORT
//#include <afxcmn.h>			// MFC support for Windows Common Controls
#endif // _AFX_NO_AFXCMN_SUPPORT

#include <comcat.h> // CLSID_StdComponentCategoriesMgr
#include <comdef.h> // _bstr_t
//#include <objbase.h> // includes rpc.h, defines BOOL operator(const UUID&, const UUID&);
//#include <rpc.h> // UuidCreate
#pragma comment(lib, "rpcrt4") // Load rpc library automatically

// ANSI C++ headers.
#include <list>
#include <map>
#include <string>
#include <vector>
using namespace std;

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STDAFX_H__197D03DA_5478_11D2_82E0_00A0246A5B7A__INCLUDED_)
