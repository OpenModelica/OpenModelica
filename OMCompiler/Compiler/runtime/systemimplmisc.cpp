
/* Miscellaneous C++ file for systemimpl. */


#include <string>
#include <stack>

#if !defined(__has_include)
#define __has_include(X) 0
#endif

#if __has_include(<unordered_set>) && __has_include(<unordered_map>)
#include <unordered_set>
#include <unordered_map>
#else
#define unordered_set set
#define unordered_map map
#include <set>
#include <map>
#endif

using namespace std;

void FindAndReplace( std::string& tInput, std::string tFind, std::string tReplace )
{
  size_t uPos = 0; size_t uFindLen = tFind.length(); size_t uReplaceLen = tReplace.length();

  if( uFindLen == 0 )
  {
      return;
  }

  for( ;(uPos = tInput.find( tFind, uPos )) != std::string::npos; )
  {
      tInput.replace( uPos, uFindLen, tReplace );
      uPos += uReplaceLen;
  }

}


extern "C" {

#include <string.h>
#include "meta/meta_modelica.h"

  char* _replace(const char* source_str, const char* search_str, const char* replace_str)
  {
    string str(source_str);
    size_t len;
    FindAndReplace(str,string(search_str),string(replace_str));

    len = strlen(str.c_str());
    char* res = (char *)omc_alloc_interface.malloc_atomic(len + 1);
    strcpy(res, str.c_str());
    res[len] = '\0';
    return res;
  }

#define GC_GRANULE_BYTES (2*sizeof(void*))

static inline size_t actualByteSize(size_t sz)
{
  /* GC uses 2 words as the minimum allocation unit: a granule
   * GC also uses up 1 byte of the allocation for its internal use.
   */
  size_t res = GC_GRANULE_BYTES*((sz+GC_GRANULE_BYTES-1+1) / GC_GRANULE_BYTES);
  return res;
}
#include <stdio.h>
double SystemImpl__getSizeOfData(void *data, double *raw_size_res, double *nonshared_str_res)
{
  size_t sz=0, raw_sz=0, nonshared_str_sz=0;
  std::unordered_map<void*,void*> handled;
  std::stack<void*> work;
  std::unordered_set<std::string> strings;
  work.push(data);
  while (!work.empty()) {
    void *item = work.top();
    work.pop();
    if (handled.find(item) != handled.end()) {
      continue;
    }
    handled[item] = 0;
    if (MMC_IS_IMMEDIATE(item)) {
      /* Uses up zero space */
      continue;
    }
    mmc_uint_t hdr = MMC_GETHDR(item);
    if (MMC_HDR_IS_FORWARD(hdr) || hdr==MMC_NILHDR || hdr==MMC_NONEHDR) {
      /* Uses up zero space */
      continue;
    }
    if (hdr==MMC_REALHDR) {
      raw_sz += sizeof(void*)+sizeof(double);
      sz += actualByteSize(sizeof(void*)+sizeof(double));
      continue;
    }
    if (MMC_HDRISSTRING(hdr)) {
      size_t t = sizeof(void*)+MMC_STRLEN(item)+1;
      size_t actual = actualByteSize(t);
      std::string s(MMC_STRINGDATA(item));
      if (strings.find(s) != strings.end()) {
        nonshared_str_sz += actual;
      } else {
        strings.insert(s);
      }
      raw_sz += t;
      sz += actual;
      continue;
    }
    if (MMC_HDRISSTRUCT(hdr)) {
      mmc_uint_t slots = MMC_HDRSLOTS(hdr);
      mmc_uint_t ctor  = MMC_HDRCTOR(hdr);
      raw_sz += sizeof(void*)*(slots+1);
      sz += actualByteSize(sizeof(void*)*(slots+1));
      // Push the sub-objects to the stack
      for (int i = (ctor>=3 && ctor != MMC_ARRAY_TAG) ? 2 /* MM record description */ : 1; i <= slots; i++) {
        void *ptr = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(item), i)));
        work.push(ptr);
      }
      continue;
    }
    fprintf(stderr, "abort... bytes=%ld num items=%ld\n", sz, handled.size());
    printAny(item);
    abort();
  }
  *raw_size_res = raw_sz;
  *nonshared_str_res = nonshared_str_sz;
  return sz;
}

}
