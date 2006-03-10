/* yacclib.h */

extern void *alloc_bytes(unsigned nbytes);
extern void *alloc_words(unsigned nwords);

extern void print_icon(FILE*, void*);
extern void print_rcon(FILE*, void*);
extern void print_scon(FILE*, void*);

extern void *mk_icon(int);
extern void *mk_rcon(double);
extern void *mk_scon(char*);
extern void *mk_nil(void);
extern void *mk_cons(void*, void*);
extern void *mk_none(void);
extern void *mk_some(void*);
extern void *mk_box0(unsigned ctor);
extern void *mk_box1(unsigned ctor, void*);
extern void *mk_box2(unsigned ctor, void*, void*);
extern void *mk_box3(unsigned ctor, void*, void*, void*);
extern void *mk_box4(unsigned ctor, void*, void*, void*, void*);
extern void *mk_box5(unsigned ctor, void*, void*, void*, void*, void*);
extern void *mk_box6(unsigned ctor, void*, void*, void*, void*, void*, void*);
extern void *mk_box7(unsigned ctor, void*, void*, void*, void*, void *,
		     void*, void*);
extern void *mk_box8(unsigned ctor, void*, void*, void*, void*, void *,
		     void*, void*, void*);
extern void *mk_box9(unsigned ctor, void*, void*, void*, void*, void *,
		     void*, void*, void*, void*);
