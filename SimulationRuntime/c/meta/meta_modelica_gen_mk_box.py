#!/usr/bin/env python

start = 0
end = 20

for i in range(start,end+1):
  print 'static inline void *mmc_mk_box%d(unsigned int ctor' % i +''.join([', void *x%d' % j for j in range(0,i)]) + ')'
  print '{'
  print '  struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(%d);' % (i+1)
  print '  void **data = p->data;'
  print '  p->header = MMC_STRUCTHDR(%d, ctor);' % i
  for j in range(0,i):
    print '  data[%d] = (void*) x%d;' % (j,j)
  print '  return MMC_TAGPTR(p);'
  print '}'
