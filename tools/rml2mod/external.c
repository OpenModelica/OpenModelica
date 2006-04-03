#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <stdlib.h>
#include "rml.h"
 
/* No init for this module */
void External_5finit(void) 
{

}
 
RML_BEGIN_LABEL(External__write_5ffile)
{
  char* filename = RML_STRINGDATA(rmlA0);
  FILE * file=NULL;
  file = fopen(filename,"w");
  if (file == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  fwrite(RML_STRINGDATA(rmlA1), RML_HDRSTRLEN(RML_GETHDR(rmlA1)), 1, file);
  fclose(file);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__to_5flowercase)
{
    void *a0 = rmlA0;
    char *str = RML_STRINGDATA(a0);
	rmlA0=a0;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__toJavaName)
{
    void *a0 = rmlA0;
    char *str = RML_STRINGDATA(a0);
	int i = 0;
	int j = 1;
	rml_uint_t len = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght */
	if (len < 1) RML_TAILCALLK(rmlSC);
    /* check if are all caps or "_" 
	 * if they are, do nothing!
	 */
	for (; i < len;)
    if (str[i] != '_' && str[i] != toupper(str[i])) 
		break;
	else i++;
	if (i==len) RML_TAILCALLK(rmlSC); /* all caps or "_"; return the same */
	i = 1;
	char *newstr = (char*)malloc(len+1);
	newstr[0] = tolower(str[0]); /* make the first one lowercase */
	char *freeme = newstr;
	for (; i < len;)
	if (str[i] != '_') 
	{
		newstr[j++] = str[i];
		i++;
	}
	else /* is equal */
	{ 
       if (i+1 < len)
	   {
		    newstr[j++]=toupper(str[i+1]);
			i += 2;
	   }
	   else
	   {
			newstr[j++] = str[i];
			i++;
	   }
	}
	newstr[j] = '\0';
	len = strlen(newstr);
	/* alloc the new string */
	struct rml_string *strnew = rml_prim_mkstring(len, 1);
	unsigned char *snew = (unsigned char*)strnew->data;
	for(; len > 0; --len)
		*snew++ = *newstr++;
	*snew = '\0';	
	rmlA0 = RML_TAGPTR(strnew);
	free(freeme);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(External__startsWith)
{
    char *str1 = RML_STRINGDATA(rmlA0);
	char *str2 = RML_STRINGDATA(rmlA1);
	int i = 0;
	rml_uint_t len1 = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght1 */
	rml_uint_t len2 = RML_HDRSTRLEN(RML_GETHDR(rmlA1)); /* string lenght1 */
	/* if the second one is longer than the first we return false */
	if (len2 > len1) 
	{
		rmlA0 = RML_FALSE;
		RML_TAILCALLK(rmlSC);
	}

	for (; i < len2; i++)
	if (str1[i] != str2[i])
	{
		rmlA0 = RML_FALSE;
		RML_TAILCALLK(rmlSC);
	}
	/* else, everything is dandy */
	rmlA0 = RML_TRUE;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(External__endsWith)
{
    char *str1 = RML_STRINGDATA(rmlA0);
	char *str2 = RML_STRINGDATA(rmlA1);
	int i = 0;
	rml_uint_t len1 = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght1 */
	rml_uint_t len2 = RML_HDRSTRLEN(RML_GETHDR(rmlA1)); /* string lenght1 */
	/* if the second one is longer than the first we return false */
	if (len2 > len1) 
	{
		rmlA0 = RML_FALSE;
		RML_TAILCALLK(rmlSC);
	}

	for (; i < len2; i++)
		if (str1[len1-len2+i] != str2[i])
		{
			rmlA0 = RML_FALSE;
			RML_TAILCALLK(rmlSC);
		}
	/* else, everything is dandy */
	rmlA0 = RML_TRUE;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__substring)
{
	rml_uint_t len = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght */
	int index1 = RML_UNTAGFIXNUM(rmlA1);
	int index2 = RML_UNTAGFIXNUM(rmlA2);
	rml_uint_t newlen = 0;
	int i = 0;
	if (index2 < 0) index2 = len-1;
	if (index1 < 0) index1 = 0;
	if (index1 > index2) 
	{
		index1 = RML_UNTAGFIXNUM(rmlA2);
		index2 = RML_UNTAGFIXNUM(rmlA1);
	}
	if (index2 >= len) index2 = len-1; 
	newlen = index2-index1 + 1;
	/* alloc the new string */
	struct rml_string *strnew = rml_prim_mkstring(newlen, 3);
	char *str = RML_STRINGDATA(rmlA0);
	unsigned char *snew = (unsigned char*)strnew->data;
	for(i=index1; i <= index2; i++)
	{
		*snew++ = str[i];
	}
	*snew = '\0';
	rmlA0 = RML_TAGPTR(strnew);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__strcmp)
{
	char *str1 = RML_STRINGDATA(rmlA0);
	char *str2 = RML_STRINGDATA(rmlA1);
	int result = strcmp(str1, str2);
	rmlA0 = RML_IMMEDIATE(RML_TAGFIXNUM(result));
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(External__strstr)
{
	char *str1 = RML_STRINGDATA(rmlA0);
	char *str2 = RML_STRINGDATA(rmlA1);
	char* result = NULL;
	if (strlen(str2) == 0 || (strlen(str1) < strlen(str2))) /* according to strstr */
	{
		rmlA0 = RML_FALSE;
		RML_TAILCALLK(rmlSC);
	}
	result = strstr(str1, str2);
	if (result) rmlA0 = RML_TRUE; 
	else rmlA0 = RML_FALSE;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__trim)
{
	char *str = RML_STRINGDATA(rmlA0);
	rml_uint_t len = strlen(str); /* string lenght */
	int i = 0;
	int j = len-1;
	int l = 0;
	for (; i < len;) if (isspace(str[i])) i++; else break;
	for (; j >= 0; ) if (isspace(str[j])) j--; else break;
	/* printf("i=%d, j=%d", i, j); */
	if (j <= i) /* the string is actually only whitespace, return "" */
	{
		/* alloc the new string */
		struct rml_string *strnew = rml_prim_mkstring(0, 1);
		unsigned char *snew = (unsigned char*)strnew->data;
		snew[0] = '\0';	
		rmlA0 = RML_TAGPTR(strnew);
		RML_TAILCALLK(rmlSC);
	}
	/* alloc the new string */
	struct rml_string *strnew = rml_prim_mkstring(j-i+1, 1);
	unsigned char *snew = (unsigned char*)strnew->data;
    str = RML_STRINGDATA(rmlA0);
	for(l=i; l <= j; l++)
		*snew++ = str[l];
	*snew = '\0';	
	rmlA0 = RML_TAGPTR(strnew);
	/*
	printf("sss:%s|\nstr:%s|\nact:",str, RML_STRINGDATA(rmlA0));
	fwrite(RML_STRINGDATA(rmlA0), RML_HDRSTRLEN(RML_GETHDR(rmlA0)), 1, stdout);
	printf("|\n");
	*/
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__strrpl)
{
	rml_uint_t len1 = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght */
	rml_uint_t len2 = RML_HDRSTRLEN(RML_GETHDR(rmlA1)); /* string lenght */
	rml_uint_t len3 = RML_HDRSTRLEN(RML_GETHDR(rmlA2)); /* string lenght */
	char *str1 = RML_STRINGDATA(rmlA0);
	char *str2 = RML_STRINGDATA(rmlA1);
	char *str3 = RML_STRINGDATA(rmlA2);
	char *strpos;
	if (len1 == 0 || len2==0) 
	{
		rmlA0 = rmlA0; /* return the first string unchanged */
		RML_TAILCALLK(rmlSC);
	}
	if ((strpos = strstr(str1, str2)) == NULL) /* the string is not there */
	{
		rmlA0 = rmlA0; /* return the first string unchanged */
		RML_TAILCALLK(rmlSC);
	}
	else
	{
		/* string is there */
		rml_uint_t len = len1-len2+len3;
		/* find where */
		rml_uint_t pos = (int)(strpos - str1);
		/* alloc the new string */
		struct rml_string *strnew = rml_prim_mkstring(len, 3);
		int i, j, k;
		/* reread the rmlAX, it could have been moved by the GC */
		str1 = RML_STRINGDATA(rmlA0);
		str2 = RML_STRINGDATA(rmlA1);
		str3 = RML_STRINGDATA(rmlA2);
		unsigned char *snew = (unsigned char*)strnew->data;
		/* until pos, use the first string */
		for(i=0; i < pos; i++)
		{
			*snew++ = str1[i];
		}
		/* now use str3 */
		for(i=0; i < len3; i++)
		{
			*snew++ = str3[i];
		}
		/* until end, use the first string again */
		for(i=pos+len2; i < len1; i++)
		{
			*snew++ = str1[i];
		}
		*snew = '\0';
		rmlA0 = RML_TAGPTR(strnew);
		RML_TAILCALLK(rmlSC);
	}
}
RML_END_LABEL


RML_BEGIN_LABEL(External__strrplall)
{
	rml_uint_t len1 = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght */
	rml_uint_t len2 = RML_HDRSTRLEN(RML_GETHDR(rmlA1)); /* string lenght */
	rml_uint_t len3 = RML_HDRSTRLEN(RML_GETHDR(rmlA2)); /* string lenght */
	char *str1 = RML_STRINGDATA(rmlA0);
	char *str2 = RML_STRINGDATA(rmlA1);
	char *str3 = RML_STRINGDATA(rmlA2);
	char *strpos;
	if (len1 == 0 || len2==0) 
	{
		rmlA0 = rmlA0; /* return the first string unchanged */
		RML_TAILCALLK(rmlSC);
	}
	if ((strpos = strstr(str1, str2)) == NULL) /* the string is not there */
	{
		rmlA0 = rmlA0; /* return the first string unchanged */
		RML_TAILCALLK(rmlSC);
	}
	else
	{
		/* string is there */
		rml_uint_t len = 0;
		/* find where */
		rml_uint_t pos = (int)(strpos - str1);
		rml_uint_t count = 1; /* we already find it once above */
		/* how many times the string is there? */
		strpos += len2; /* advance the position */
		/* 
		printf ("str1 [%s], str2[%s], str3[%s]\n", str1, str2, str3);
		printf ("strpos:%s\n", strpos);
		*/
		/* how many times the string is there? */
		while ((strpos = strstr(strpos, str2)) != NULL) 
		{
			count++;
			/* printf ("strpos:%s\n", strpos); */
			strpos += len2;
		}
		/* calculate the lenght of the new string */
		len = len1+(len3-len2)*count;
		/* print len 
		printf("len:%d, len1:%d, len2:%d, len3:%d, count:%d\n", len, len1, len2, len3, count);
		*/
		/* now alloc the new string */
		struct rml_string *strnew = rml_prim_mkstring(len, 3);
		int i, j, k;
		/* reread the rmlAX, it could have been moved by the GC */
		str1 = RML_STRINGDATA(rmlA0);
		str2 = RML_STRINGDATA(rmlA1);
		str3 = RML_STRINGDATA(rmlA2);
		unsigned char *snew = (unsigned char*)strnew->data;
		/* until pos, use the first string */
		/* go to first */
		strpos = strstr(str1, str2); 
		pos = (int)(strpos - str1);
		do 
		{
			/* until pos, use the first string */
			/* printf("pos1:%d\n", pos); */
			for(i=0; i < pos; i++)
			{
				*snew++ = str1[i];
			}
			for(i=0; i < len3; i++)
			{
				*snew++ = str3[i];
			}
			/* move the str1 pointer after str2 */
			str1 += (pos+len2);
			strpos = strstr(str1, str2); 
			if (!strpos) 
			{
				/* copy stuff left from str1 */
				for(i=0; i < strlen(str1); i++)
				{
					*snew++ = str1[i];
				}
				break;
			}
			pos = (int)(strpos - str1);
			/* printf("pos2:%d and str1:%s\n", pos, str1); */
		}
		while (1);			
		*snew = '\0';
		rmlA0 = RML_TAGPTR(strnew);
		RML_TAILCALLK(rmlSC);
	}
}
RML_END_LABEL

RML_BEGIN_LABEL(External__strtok)
{
  char *s;
  char *delimit = RML_STRINGDATA(rmlA1);
  char *str = strdup(RML_STRINGDATA(rmlA0));

  void * res = (void*)mk_nil();
  s=strtok(str,delimit);
  if (s == NULL) 
  {
          /* adrpo added 2004-10-27 */
          free(str);      
          rmlA0=res; RML_TAILCALLK(rmlFC); 
  }
  res = (void*)mk_cons(mk_scon(s),res);
  while (s=strtok(NULL,delimit)) 
  {
    res = (void*)mk_cons(mk_scon(s),res);
  }
  rmlA0=res;

  /* adrpo added 2004-10-27 */
  free(str);      

  /* adrpo changed 2004-10-29 
  rml_prim_once(RML__list_5freverse);
  RML_TAILCALLK(rmlSC);
  */
  RML_TAILCALLQ(RML__list_5freverse,1);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__sst)
{
	char *s;
	char *str = strdup(RML_STRINGDATA(rmlA0));
	char *delimit = RML_STRINGDATA(rmlA1);
	char *separator = RML_STRINGDATA(rmlA2);
	char *strTmp1 = 0;
	char *strTmp2 = 0;
	int i;
	rml_uint_t lenseparator = strlen(separator);
	rml_uint_t len1 = 0;
	rml_uint_t len2 = 0;
	rml_uint_t len = 0;

	void * res = (void*)mk_nil();
	s=strtok(str,delimit);
	if (s == NULL) 
	{
			/* adrpo added 2004-10-27 */
			free(str);      
			rmlA0=res; RML_TAILCALLK(rmlFC); 
	}
	strTmp1 = strdup(s); /* first token */
	while (s=strtok(NULL,delimit)) 
	{
		len1 = strlen(strTmp1);
		len2 = strlen(s);
		len = len1+lenseparator+len2;
		strTmp2 = (char*)malloc(len+1);
		strTmp2[0] = '\0';
		strncat(strTmp2,strTmp1,len1);
		strncat(strTmp2,separator,lenseparator);
		strncat(strTmp2,s,len2);
		strTmp2[len] = '\0';
		free(strTmp1);
		strTmp1 = strTmp2;
	}
	/* now we have everything in strTmp2 */
	/* now alloc the new string */
	struct rml_string *strnew = rml_prim_mkstring(len, 3);
	unsigned char *snew = (unsigned char*)strnew->data;
	for(i=0; i < len; i++)
	{
		*snew++ = strTmp2[i];
	}
	*snew = '\0';
	free(strTmp2);
	rmlA0 = RML_TAGPTR(strnew);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__trimstring)
{
	char *str = RML_STRINGDATA(rmlA0);
	char *what = RML_STRINGDATA(rmlA1);
	rml_uint_t len = strlen(str); /* string lenght */
	rml_uint_t lenwhat = strlen(what); /* string lenght */
	int i = 0;
	int j = len;
	int l = 0;
	if (!lenwhat) RML_TAILCALLK(rmlSC);
	for (; i < len;) if (!strncmp(str+i,what,lenwhat)) i+=lenwhat; else break;
	for (; j >= 0; ) if (!strncmp(str+j-lenwhat,what,lenwhat)) j-=lenwhat; else break;
	/* printf("i=%d, j=%d, lenwhat=%d, len=%d", i, j, lenwhat, len); */
	if (j <= i) /* the string is actually only whitespace, return "" */
	{
		/* alloc the new string */
		struct rml_string *strnew = rml_prim_mkstring(0, 2);
		unsigned char *snew = (unsigned char*)strnew->data;
		snew[0] = '\0';	
		rmlA0 = RML_TAGPTR(strnew);
		RML_TAILCALLK(rmlSC);
	}
	/* alloc the new string */
	struct rml_string *strnew = rml_prim_mkstring(j-i, 2);
	unsigned char *snew = (unsigned char*)strnew->data;
    str = RML_STRINGDATA(rmlA0);
	for(l=i; l < j; l++)
		*snew++ = str[l];
	*snew = '\0';	
	rmlA0 = RML_TAGPTR(strnew);
	/*
	printf("sss:%s|\nstr:%s|\ndlm:%s|\nact:",str, RML_STRINGDATA(rmlA0), RML_STRINGDATA(rmlA1));
	fwrite(RML_STRINGDATA(rmlA0), RML_HDRSTRLEN(RML_GETHDR(rmlA0)), 1, stdout);
	printf("|\n");
	*/
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


RML_BEGIN_LABEL(External__getFirstIdent)
{
	rml_uint_t len = RML_HDRSTRLEN(RML_GETHDR(rmlA0)); /* string lenght */
	rml_uint_t newlen = 0;
	int index = 1, i=0;
	char *str = RML_STRINGDATA(rmlA0);
	if (!isalpha(str[0])) RML_TAILCALLK(rmlFC); /* fail if we don't start with alpha */
	while((isalpha(str[index]) || 
		  (str[index] >= '0' && str[index] <= '9')) && 
		  index < len) index++;
	/* alloc the new string */
	struct rml_string *strnew = rml_prim_mkstring(index, 3);
	str = RML_STRINGDATA(rmlA0);
	unsigned char *snew = (unsigned char*)strnew->data;
	for(i=0; i < index; i++)
	{
		*snew++ = str[i];
	}
	*snew = '\0';
	rmlA0 = RML_TAGPTR(strnew);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(External__string_5freal)
{
	char *str = RML_STRINGDATA(rmlA0);
	double real = atof(str);
	rmlA0 = rml_prim_mkreal(real);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(External__stringEscape)
{
	char *str = RML_STRINGDATA(rmlA0);
	rml_uint_t len = strlen(str);
	char *strnew = (char*)malloc(2*len); /* should be enough */
	int i=0, j=0, c=0, n=0;
	rml_uint_t lennew = 0;
	unsigned char *snew = 0;
	struct rml_string *rml_strnew = 0;
	while (1)
	{
		if (i >= len) break;
		c = str[i];
		if (c == '\\')
		{
			strnew[lennew] = c; lennew++; i++;
			if (i >= len) break;
			c = str[i];
			switch (c)
			{
			case 'f':
				strnew[lennew] = '\f'; 
				break;
			case 'b':
				strnew[lennew] = '\b'; 
				break;
			case 'e':
				strnew[lennew] = 033; 
				break;
			case 'v':
				strnew[lennew] = '\v';
				break;
			case 'a':
				strnew[lennew] = '\a';
				break;
			case '?':
				strnew[lennew] = '\?';
				break;
			case 'n':
				strnew[lennew] = '\n';
				break;
			case 't':
				strnew[lennew] = '\t';
				break;
			case 'r':
				strnew[lennew] = '\r';
				break;
			case '"':
				strnew[lennew] = '\"';
				break;
			default: 
				strnew[lennew] = '\\'; lennew++; 
				strnew[lennew] = c; 
			}
			lennew++;
		}
		else if(c == '"' || c == '\'')
		{
			strnew[lennew++] = '\\';
			strnew[lennew++] = c;
		}
		else /* leave the char as it is */
		{
			strnew[lennew++] = c;
		}
		i++;
	}
	strnew[lennew]='\0';
	/* now alloc the new string */
	rml_strnew = rml_prim_mkstring(lennew, 1);
	snew = (unsigned char*)rml_strnew->data;
	for(i = 0; i < lennew; i++)
	{
		*snew++ = strnew[i];
	}
	*snew = '\0';
	free(strnew);
	rmlA0 = RML_TAGPTR(rml_strnew);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(External__commentEscape)
{
	char *str = RML_STRINGDATA(rmlA0);
	rml_uint_t len = strlen(str);
	char *strnew = (char*)malloc(2*len); /* should be enough */
	int i=0, j=0, c=0, n=0;
	rml_uint_t lennew = 0;
	unsigned char *snew = 0;
	struct rml_string *rml_strnew = 0;
	while (1)
	{
		if (i >= len) break;
		c = str[i];
		if (c == '\\')
		{
			strnew[lennew] = c; lennew++; i++;
			if (i >= len) break;
			c = str[i]; 
			switch (c)
			{
			/*
			case 'n':
				strnew[lennew] = '\n';
				break;
			case 't':
				strnew[lennew] = '\t';
				break;
			case 'r':
				strnew[lennew] = '\r';
				break;
			*/
			case '\\': 
				strnew[lennew] = '\\';
				break;
			case '"': 
				/* already escaped */
				strnew[lennew] = '"';
				break;
			default: /* don't know the escape sequence, escape the \ */
				strnew[lennew] = '\\'; 
				lennew++;
				strnew[lennew] = c;
			}
			lennew++;
		}
		else if(c == '"' || c == '\'')
		{
			strnew[lennew++] = '\\';
			strnew[lennew++] = c;
		}
		else 
		{
			strnew[lennew++] = c;
		}
		i++;
	}
	strnew[lennew]='\0';
	/* now alloc the new string */
	rml_strnew = rml_prim_mkstring(lennew, 1);
	snew = (unsigned char*)rml_strnew->data;
	for(i = 0; i < lennew; i++)
	{
		*snew++ = strnew[i];
	}
	*snew = '\0';
	free(strnew);
	rmlA0 = RML_TAGPTR(rml_strnew);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
