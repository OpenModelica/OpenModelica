#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>

struct ClassItem { int *cl; int *env; }; // int or void does not matter...

using namespace std;

typedef map<string, ClassItem*> CacheItem;
typedef map<string, CacheItem* > Cache;

Cache *classCache=0;
//Cache *variableCache=0;
//Cache *typeCache=0;

extern "C"
{
#include "rml.h"
  void rml_user_gc(struct rml_xgcstate *state) 
  {
    unsigned int size=0;
    if (classCache) {
      set<int*> refSet;
      int i=0,size=0;
      Cache::iterator it;
      CacheItem::iterator it2;

      for (it = classCache->begin(); it != classCache->end(); ++it) {
	for (it2 = it->second->begin(); it2 != it->second->end(); ++it2) {
	  size+=2;
	  rml_user_gc_callback(state,(void**)&it2->second->cl,1);
	  rml_user_gc_callback(state,(void**)&it2->second->env,1);
	}
      }
    }
    // std::cerr <<  "leaving user_gc" << endl;
  }

  void Cache_5finit(void)
  {
    if (classCache) delete classCache;
    classCache = new Cache(); 
  }
  
  RML_BEGIN_LABEL(Cache__add_5fclass)
  {
    //RML_TAILCALLK(rmlSC);

    int *cl = (int*)rmlA0;
    int *env = (int*)rmlA1;
    string scope = RML_STRINGDATA(rmlA2);
    string className = RML_STRINGDATA(rmlA3);
    if (scope == "") scope = "$TOP$";
    
    //cerr << " Adding class" << className <<" scope : " << scope << endl;
    if (!classCache) {
      cerr << "Cache is not initialized\n";
      RML_TAILCALLK(rmlFC);
    }
    Cache::iterator it = classCache->find(className);
    if (it == classCache->end()) {
      //cerr << "Did not find " << className << "hash table.\n";
      (*classCache)[className] = new CacheItem();
      it = classCache->find(className);
    }
    if ((it->second->size() == 0 || 
	 it->second->size() == 1 && it->second->begin()->second->cl != cl) ) 
      // Only add class if different or not exist before
      {
	//cerr << "Different or new, adding class." << endl;
	ClassItem *newItem = new ClassItem;
	newItem->cl = cl;
	newItem->env = env;
	//cerr << "Adding refs:      " << cl << "  " << env << endl;
	(*(*classCache)[className])[scope] = newItem;
	//  cerr << "Added class " << className << " to cache.\n" << endl ;
      }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL
  
  RML_BEGIN_LABEL(Cache__add_5fvariable)
  {
    cerr << "Not implemented yet\n";
    RML_TAILCALLK(rmlFC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(Cache__add_5ftype)
  {
    cerr << "Not implemented yet\n";
    RML_TAILCALLK(rmlFC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(Cache__get_5fclass)
  {
    RML_TAILCALLK(rmlFC);

    string scope = RML_STRINGDATA(rmlA0);
    string className = RML_STRINGDATA(rmlA1);
    if (scope == "") scope ="$TOP$";
    Cache::iterator it;
    CacheItem::iterator it2;
    //cerr << "Get_class " << className << " in scope " << scope << endl;
    it = classCache->find(className);
    if (it == classCache->end()) {
      //cerr << "class " << className << " not found in cache\n";
      RML_TAILCALLK(rmlFC);
    } else {
      if (it->second->size() == 1) {
	//cerr << "got class, size =1" << endl;
	ClassItem *item=it->second->begin()->second;
	rmlA0=item->cl;
	rmlA1=item->env;
	RML_TAILCALLK(rmlSC);
      }
      it2 = it->second->find(scope);
      if (it2 == it->second->end()) {
	//cerr << "class " << className << " not found in cache, size =" << it->second->size() << endl;
	RML_TAILCALLK(rmlFC);

      }
      ClassItem *item=it2->second;
      rmlA0=item->cl;
      rmlA1=item->env;
      //cerr << "Found class " << className << " in cache.\n";
      RML_TAILCALLK(rmlSC);
    }
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(Cache__get_5fvariable)
  {
    cerr << "Not implemented yet\n";
    RML_TAILCALLK(rmlFC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(Cache__get_5ftype)
  {
    cerr << "Not implemented yet\n";
    RML_TAILCALLK(rmlFC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(Cache__init_5fcache)
  {
    if (classCache) delete classCache;
    classCache = new Cache();
	RML_TAILCALLK(rmlSC);
  }

  RML_BEGIN_LABEL(Cache__clear_5fcache)
  {
    if (classCache) {
      delete classCache;
    }
    classCache = new Cache();
	RML_TAILCALLK(rmlSC);
  }

  RML_BEGIN_LABEL(Cache__print_5fcache)
  {
    cerr << "print_cache not implemented yet\n";
    RML_TAILCALLK(rmlFC);
  }

} // extern "C"
