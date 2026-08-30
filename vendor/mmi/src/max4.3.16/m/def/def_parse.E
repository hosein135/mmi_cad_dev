# 1 "def_parse.c"
 












# 1 "/volume/mmi/utils/pccts/h/pcctscfg.h" 1


 
































 







 
















# 1 "/volume/mmi/utils/pccts/h/pccts_stdio.h" 1






# 1 "/usr/include/stdio.h" 1 3
 
 

 
 
 

 




 






#pragma ident	"@(#)stdio.h	1.69	98/07/13 SMI"	

# 1 "/usr/include/sys/feature_tests.h" 1 3
 




 
 
 




#pragma ident	"@(#)feature_tests.h	1.17	97/12/04 SMI"

# 1 "/usr/include/sys/isa_defs.h" 1 3
 







#pragma ident	"@(#)isa_defs.h	1.16	99/05/25 SMI"

 












































































































































 






# 218 "/usr/include/sys/isa_defs.h" 3


 






 






 









 
















 






 





 







 








 



# 316 "/usr/include/sys/isa_defs.h" 3


 















# 15 "/usr/include/sys/feature_tests.h" 2 3






 












 








































 



























 



















 






















 
































# 22 "/usr/include/stdio.h" 2 3

# 1 "/usr/include/sys/va_list.h" 1 3
 







#pragma ident	"@(#)va_list.h	1.11	97/11/22 SMI"

 














typedef void *__va_list;









# 23 "/usr/include/stdio.h" 2 3

# 1 "/usr/include/stdio_tag.h" 1 3
 







#pragma ident	"@(#)stdio_tag.h	1.3	98/04/20 SMI"











typedef struct __FILE  __FILE;







# 24 "/usr/include/stdio.h" 2 3

# 1 "/usr/include/stdio_impl.h" 1 3
 







#pragma ident	"@(#)stdio_impl.h	1.7	98/04/17 SMI"












typedef int	ssize_t;		 



# 36 "/usr/include/stdio_impl.h" 3


struct __FILE 	 
{




	ssize_t		_cnt;	 
	unsigned char	*_ptr;	 

	unsigned char	*_base;	 
	unsigned char	_flag;	 
	unsigned char	_file;	 
	unsigned	__orientation:2;  
	unsigned	__filler:6;
};








# 25 "/usr/include/stdio.h" 2 3


 













typedef	__FILE FILE;







typedef unsigned int	size_t;		 




 





typedef	long long	__longlong_t;













typedef long		off_t;







typedef __longlong_t	off64_t;






typedef long		fpos_t;







typedef __longlong_t	fpos64_t;













 










 


































































extern FILE	__iob[20 ];











extern unsigned char	 _sibuf[], _sobuf[];


 
# 227 "/usr/include/stdio.h" 3



extern unsigned char	*_bufendtab[];
extern FILE		*_lastbuf;


 
# 257 "/usr/include/stdio.h" 3




extern int	remove(const char *);
extern int	rename(const char *, const char *);
extern FILE	*tmpfile(void);
extern char	*tmpnam(char *);



extern int	fclose(FILE *);
extern int	fflush(FILE *);
extern FILE	*fopen(const char *, const char *);
extern FILE	*freopen(const char *, const char *, FILE *);
extern void	setbuf(FILE *, char *);


extern void setbuffer(FILE *, char *, size_t);
extern int setlinebuf(FILE *);

extern int	setvbuf(FILE *, char *, int, size_t);
 
extern int	fprintf(FILE *, const char *, ...);
 
extern int	fscanf(FILE *, const char *, ...);
 
extern int	printf(const char *, ...);
 
extern int	scanf(const char *, ...);



 
extern int	snprintf(char *, size_t, const char *, ...);

 
extern int	sprintf(char *, const char *, ...);
 
extern int	sscanf(const char *, const char *, ...);
extern int	vfprintf(FILE *, const char *, __va_list);
extern int	vprintf(const char *, __va_list);



extern int	vsnprintf(char *, size_t, const char *, __va_list);

extern int	vsprintf(char *, const char *, __va_list);
extern int	fgetc(FILE *);
extern char	*fgets(char *, int, FILE *);
extern int	fputc(int, FILE *);
extern int	fputs(const char *, FILE *);
extern int	getc(FILE *);
extern int	getchar(void);
extern char	*gets(char *);
extern int	putc(int, FILE *);
extern int	putchar(int);
extern int	puts(const char *);
extern int	ungetc(int, FILE *);
extern size_t	fread(void *, size_t, size_t, FILE *);
extern size_t	fwrite(const void *, size_t, size_t, FILE *);
extern int	fgetpos(FILE *, fpos_t *);
extern int	fseek(FILE *, long, int);
extern int	fsetpos(FILE *, const fpos_t *);
extern long	ftell(FILE *);
extern void	rewind(FILE *);
extern void	clearerr(FILE *);
extern int	feof(FILE *);
extern int	ferror(FILE *);
extern void	perror(const char *);


extern int	__filbuf(FILE *);
extern int	__flsbuf(int, FILE *);


 





extern FILE	*fdopen(int, const char *);
extern char	*ctermid(char *);
extern int	fileno(FILE *);



 


# 358 "/usr/include/stdio.h" 3


 




extern FILE	*popen(const char *, const char *);
extern char	*cuserid(char *);
extern char	*tempnam(const char *, const char *);
extern int	getopt(int, char *const *, const char *);

extern int	getsubopt(char **, char *const *, char **);

extern char	*optarg;
extern int	optind, opterr, optopt;
extern int	getw(FILE *);
extern int	putw(int, FILE *);
extern int	pclose(FILE *);



 



extern int	fseeko(FILE *, off_t, int);
extern off_t	ftello(FILE *);


 





extern FILE	*fopen64(const char *, const char *);
extern FILE	*freopen64(const char *, const char *, FILE *);
extern FILE	*tmpfile64(void);
extern int	fgetpos64(FILE *, fpos64_t *);
extern int	fsetpos64(FILE *, const fpos64_t *);
extern int	fseeko64(FILE *, off64_t, int);
extern off64_t	ftello64(FILE *);


# 515 "/usr/include/stdio.h" 3





























# 567 "/usr/include/stdio.h" 3









# 7 "/volume/mmi/utils/pccts/h/pccts_stdio.h" 2




# 61 "/volume/mmi/utils/pccts/h/pcctscfg.h" 2

# 1 "/volume/mmi/utils/pccts/h/pccts_stdlib.h" 1






# 1 "/usr/include/stdlib.h" 1 3
 




 
 

 
 
 




#pragma ident	"@(#)stdlib.h	1.44	98/01/22 SMI"	












typedef	struct {
	int	quot;
	int	rem;
} div_t;

typedef struct {
	long	quot;
	long	rem;
} ldiv_t;


typedef struct {
	long long	quot;
	long long	rem;
} lldiv_t;
















typedef long	uid_t;			 




















typedef long	wchar_t;





 
# 101 "/usr/include/stdlib.h" 3


 
# 117 "/usr/include/stdlib.h" 3


extern unsigned char	__ctype[];



extern double atof(const char *);
extern int atoi(const char *);
extern long int atol(const char *);
extern double strtod(const char *, char **);
extern long int strtol(const char *, char **, int);
extern unsigned long int strtoul(const char *, char **, int);

extern int rand(void);
extern void srand(unsigned int);





extern void *calloc(size_t, size_t);
extern void free(void *);
extern void *malloc(size_t);
extern void *realloc(void *, size_t);

extern void abort(void);
extern int atexit(void (*)(void));
extern void exit(int);
extern void _exithandle(void);
extern char *getenv(const char *);
extern int system(const char *);

extern void *bsearch(const void *, const void *, size_t, size_t,
	int (*)(const void *, const void *));
extern void qsort(void *, size_t, size_t,
	int (*)(const void *, const void *));

extern int abs(int);
extern div_t div(int, int);
extern long int labs(long);
extern ldiv_t ldiv(long, long);

extern int mbtowc(wchar_t *, const char *, size_t);
extern int mblen(const char *, size_t);
extern int wctomb(char *, wchar_t);

extern size_t mbstowcs(wchar_t *, const char *, size_t);
extern size_t wcstombs(char *, const wchar_t *, size_t);




extern double drand48(void);
extern double erand48(unsigned short *);
extern long jrand48(unsigned short *);
extern void lcong48(unsigned short *);
extern long lrand48(void);
extern long mrand48(void);
extern long nrand48(unsigned short *);
extern unsigned short *seed48(unsigned short *);
extern void srand48(long);
extern int putenv(char *);
extern void setkey(const char *);





extern void swab(const char *, char *, int);




extern int	mkstemp(char *);


extern int	mkstemp64(char *);






extern long a64l(const char *);
extern char *ecvt(double, int, int *, int *);
extern char *fcvt(double, int, int *, int *);
extern char *gcvt(double, int, char *);
extern int getsubopt(char **, char *const *, char **);
extern int  grantpt(int);
extern char *initstate(unsigned, char *, size_t);
extern char *l64a(long);
extern char *mktemp(char *);
extern char *ptsname(int);
extern long random(void);
extern char *realpath(const char *, char *);
extern char *setstate(const char *);
extern void srandom(unsigned);
extern int ttyslot(void);
extern int  unlockpt(int);
extern void *valloc(size_t);




extern int dup2(int, int);
extern char *qecvt(long double, int, int *, int *);
extern char *qfcvt(long double, int, int *, int *);
extern char *qgcvt(long double, int, char *);
extern char *getcwd(char *, size_t);
extern const char *getexecname(void);
extern char *getlogin(void);
extern int getopt(int, char *const *, const char *);
extern char *optarg;
extern int optind, opterr, optopt;
extern char *getpass(const char *);
extern char *getpassphrase(const char *);
extern int getpw(uid_t, char *);
extern int isatty(int);
extern void *memalign(size_t, size_t);
extern char *ttyname(int);


extern long long atoll(const char *);
extern long long llabs(long long);
extern lldiv_t lldiv(long long, long long);
extern char *lltostr(long long, char *);
extern long long strtoll(const char *, char **, int);
extern unsigned long long strtoull(const char *, char **, int);
extern char *ulltostr(unsigned long long, char *);




# 380 "/usr/include/stdlib.h" 3







# 7 "/volume/mmi/utils/pccts/h/pccts_stdlib.h" 2




# 62 "/volume/mmi/utils/pccts/h/pcctscfg.h" 2


 







 















 
 
 







# 115 "/volume/mmi/utils/pccts/h/pcctscfg.h"



















 

 































       
 















 























# 238 "/volume/mmi/utils/pccts/h/pcctscfg.h"













# 261 "/volume/mmi/utils/pccts/h/pcctscfg.h"


# 273 "/volume/mmi/utils/pccts/h/pcctscfg.h"


 











































































# 14 "def_parse.c" 2



# 1 "remap.h" 1
 








 













































 





















































































































# 17 "def_parse.c" 2

# 1 "def_parse.g"

# 1 "/usr/local/sparc-sun-solaris2.5.1/include/assert.h" 1 3
 








# 19 "/usr/local/sparc-sun-solaris2.5.1/include/assert.h" 3




 






extern void __eprintf (const char *, const char *, unsigned, const char *)
    __attribute__ ((noreturn));









# 52 "/usr/local/sparc-sun-solaris2.5.1/include/assert.h" 3



# 2 "def_parse.g" 2


# 1 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/stdarg.h" 1 3
 




























# 1 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/va-sparc.h" 1 3
 


 








 

typedef void * __gnuc_va_list;



 





 









# 47 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/va-sparc.h" 3



void va_end (__gnuc_va_list);		 

 

enum __va_type_classes {
  __no_type_class = -1,
  __void_type_class,
  __integer_type_class,
  __char_type_class,
  __enumeral_type_class,
  __boolean_type_class,
  __pointer_type_class,
  __reference_type_class,
  __offset_type_class,
  __real_type_class,
  __complex_type_class,
  __function_type_class,
  __method_type_class,
  __record_type_class,
  __union_type_class,
  __array_type_class,
  __string_type_class,
  __set_type_class,
  __file_type_class,
  __lang_type_class
};




 




 




# 134 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/va-sparc.h" 3





 

 



# 159 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/va-sparc.h" 3



 



# 30 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/stdarg.h" 2 3

# 128 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/stdarg.h" 3








 
 














 










typedef __gnuc_va_list va_list;




# 200 "/usr/local/lib/gcc-lib/sparc-sun-solaris2.5.1/2.8.1/include/stdarg.h" 3






# 4 "def_parse.g" 2

# 1 "def2max.h" 1
 
 

# 1 "remap.h" 1
 








 













































 





















































































































# 4 "def2max.h" 2



 
 
 
 
 
 







typedef struct { char *text; } Attrib;















 
typedef long pnl_port;
typedef long pnl_net;
typedef long pnl_segment;
typedef long pnl_route;
typedef long pnl_branch;
enum pnl_routekind {
  pnl_routekind_null, pnl_routekind_ROUTED, pnl_routekind_FIXED,
  pnl_routekind_COVER
};
typedef enum pnl_routekind pnl_routekind;


enum pnl_segmentkind {
  pnl_segmentkind_null, pnl_segmentkind_via, pnl_segmentkind_x,
  pnl_segmentkind_y
};
typedef enum pnl_segmentkind pnl_segmentkind;


enum pnl_loctype {
  pnl_loctype_null, pnl_loctype_UNPLACED, pnl_loctype_PLACED,
  pnl_loctype_FIXED, pnl_loctype_COVER
};
typedef enum pnl_loctype pnl_loctype;

enum pnl_pattern {
  pnl_pattern_null, pnl_pattern_STEINER, pnl_pattern_BALANCED,
  pnl_pattern_WIREDLOGIC, pnl_pattern_TRUNK
};
typedef enum pnl_pattern pnl_pattern;

enum pnl_orientation {
  pnl_orientation_null, pnl_orientation_none, pnl_orientation_N,
  pnl_orientation_S, pnl_orientation_E, pnl_orientation_W, pnl_orientation_FN,
  pnl_orientation_FS, pnl_orientation_FE, pnl_orientation_FW
};
typedef enum pnl_orientation pnl_orientation;

enum pnl_use {
  pnl_use_null, pnl_use_SIGNAL, pnl_use_POWER, pnl_use_GROUND, pnl_use_CLOCK,
  pnl_use_TIEOFF, pnl_use_ANALOG
};
typedef enum pnl_use pnl_use;




extern void def2max_design (char *);
extern void def2max_history (char *);
extern void def2max_die_area (int, int, int, int);
extern void def2max_divider_char (char *);
extern void def2max_component (char *, char *, pnl_loctype, int, int, pnl_orientation);
extern void def2max_distance_units (char *, int);
extern pnl_port def2max_pin (char *);
extern pnl_net def2max_net (char *, int);

 

 
 

 
 
 
 
# 5 "def_parse.g" 2


 
 

 
 






 
 
 


extern int def2max_pre_comment_mode;



  

# 1 "/volume/mmi/utils/pccts/h/antlr.h" 1
 



































 





 
















# 1 "/volume/mmi/utils/pccts/h/pccts_string.h" 1






# 15 "/volume/mmi/utils/pccts/h/pccts_string.h"

# 1 "/usr/include/string.h" 1 3
 
 

 
 
 

 







#pragma ident	"@(#)string.h	1.22	97/12/22 SMI"	


























extern void *memcpy(void *, const void *, size_t);
extern void *memmove(void *, const void *, size_t);
extern char *strcpy(char *, const char *);
extern char *strncpy(char *, const char *, size_t);

extern char *strcat(char *, const char *);
extern char *strncat(char *, const char *, size_t);

extern int memcmp(const void *, const void *, size_t);
extern int strcmp(const char *, const char *);
extern int strcoll(const char *, const char *);
extern int strncmp(const char *, const char *, size_t);
extern size_t strxfrm(char *, const char *, size_t);

extern void *memchr(const void *, int, size_t);
extern char *strchr(const char *, int);
extern size_t strcspn(const char *, const char *);
extern char *strpbrk(const char *, const char *);
extern char *strrchr(const char *, int);
extern size_t strspn(const char *, const char *);
extern char *strstr(const char *, const char *);
extern char *strtok(char *, const char *);




extern void *memset(void *, int, size_t);
extern char *strerror(int);
extern size_t strlen(const char *);



extern void *memccpy(void *, const void *, int, size_t);




extern char *strsignal(int);
extern int ffs(int);
extern int strcasecmp(const char *, const char *);
extern int strncasecmp(const char *, const char *, size_t);





extern char *strdup(const char *);


# 143 "/usr/include/string.h" 3







# 16 "/volume/mmi/utils/pccts/h/pccts_string.h" 2





# 60 "/volume/mmi/utils/pccts/h/antlr.h" 2







typedef int ANTLRTokenType;
typedef unsigned char SetWordType;

typedef char ANTLRChar;

						 














 



















# 119 "/volume/mmi/utils/pccts/h/antlr.h"


 





























						 

# 177 "/volume/mmi/utils/pccts/h/antlr.h"









typedef struct _zzantlr_state {




			int asp;
			int ast_sp;
# 206 "/volume/mmi/utils/pccts/h/antlr.h"











			int token;
			char text[2050 ];








		} zzantlr_state;









extern int def_zzGuessSeq ;                       
extern int def_zzSyntaxErrCount ;                 
extern int def_zzLexErrCount ;                    

                  


# 252 "/volume/mmi/utils/pccts/h/antlr.h"




# 294 "/volume/mmi/utils/pccts/h/antlr.h"



# 321 "/volume/mmi/utils/pccts/h/antlr.h"




# 333 "/volume/mmi/utils/pccts/h/antlr.h"
# 343 "/volume/mmi/utils/pccts/h/antlr.h"

	



# 369 "/volume/mmi/utils/pccts/h/antlr.h"


# 379 "/volume/mmi/utils/pccts/h/antlr.h"












# 408 "/volume/mmi/utils/pccts/h/antlr.h"























 











# 452 "/volume/mmi/utils/pccts/h/antlr.h"
						

# 464 "/volume/mmi/utils/pccts/h/antlr.h"
						

# 475 "/volume/mmi/utils/pccts/h/antlr.h"


# 486 "/volume/mmi/utils/pccts/h/antlr.h"








					 































extern int def__zzsetmatch (SetWordType *, char **, char **, int *, int *, SetWordType **);
extern int def__zzsetmatch_wsig (SetWordType *);

















extern int def__zzmatch (int, char **, char **, int *, int *, SetWordType **);
extern int def__zzmatch_wsig (int);











extern int def__zzmatch_wdfltsig (int, SetWordType *);
extern int def__zzsetmatch_wdfltsig (SetWordType *tokensWanted,
								int tokenTypeOfSet,
								SetWordType *whatFollows);
































# 615 "/volume/mmi/utils/pccts/h/antlr.h"


# 625 "/volume/mmi/utils/pccts/h/antlr.h"












# 647 "/volume/mmi/utils/pccts/h/antlr.h"








            






 
 






            
















 









				 


extern Attrib def_zzempty_attr (void);
extern Attrib def_zzconstr_attr (int, char *);
extern void def_zzsyn (char *, int, char *, SetWordType *, int, int, char *);
extern int def_zzset_el (unsigned, SetWordType *);
extern int def_zzset_deg (SetWordType *);
extern void def_zzedecode (SetWordType *);
extern void def_zzFAIL (int k, ...);
extern void def_zzresynch (SetWordType *, SetWordType);
extern void def_zzTraceGuessDone (zzantlr_state *);
extern void def_zzsave_antlr_state (zzantlr_state *);
extern void def_zzrestore_antlr_state (zzantlr_state *);
extern void def_zzfill_inf_look (void);
extern void def_zzconsumeUntil (SetWordType *st);                          
extern void def_zzconsumeUntilToken (int t);                               
extern void def_zzTraceIn (char * ruleName);                               
extern void def_zzTraceOut (char * ruleName);                              
extern int  def_zzTraceOption (int delta);                                 
extern int  def_zzTraceGuessOption (int delta);                            
extern void def_zzTraceReset (void);                                       
extern void def_zzTraceGuessFail (void);                                   



# 746 "/volume/mmi/utils/pccts/h/antlr.h"


				 

 
 

extern char * def_zztokens [];






extern int def_zztoken ;


extern char def_zzStackOvfMsg [];
extern int def_zzasp ;
extern Attrib def_zzaStack [];
















 



extern char  * def_zzlextext ;      
extern int      def_zzbufsize ;       


# 29 "def_parse.g" 2

# 1 "tokens.h" 1


 
































































































void def_def_file (void);





void def_header (void);





void def_version (void);





void def_namescasesensitive (void);





void def_dividerchar (void);





void def_busbitchars (void);





void def_def_design (void);





void def_declaration (void);





void def_units_decl (void);





void def_diearea_decl (void);





void def_tracks_decl (void);





void def_history_decl (void);





void def_row_decl (void);





void def_gcellgrid_decl (void);





void def_propertydefinitions_decl (void);





void def_propertydefinition (void);





void def_constituent (void);





void def_vias (void);





void def_via (void);





void def_via_plus (void);





void def_components (void);





void def_component (void);





void def_pins (void);





void def_pin (void);





void def_nets (void);





void def_specialnets (void);





void def_net ( int special );





void def_net_connection (void);





void def_component_plus ( char *inst_name, char *mod_name );





void def_pin_plus ( pnl_port pport );





void def_net_plus ( pnl_net pnet, int special );




struct _rv32 {
	pnl_loctype loctype;
	int x;
	int y;
	pnl_orientation orient ;
};


extern struct _rv32 def_placed_clause (void);





void def_net_clause (void);





void def_dir_clause (void);





extern  pnl_use   def_use_clause (void);





extern  pnl_pattern   def_pattern_clause (void);





extern  pnl_route   def_route_clause ( int special );





extern  pnl_branch   def_route_branch ( int special );





extern  pnl_segment   def_route_segment (void);





void def_layer_clause ( pnl_port pport );





void def_rect_clause (void);




struct _rv42 {
	int x;
	int y ;
};


extern struct _rv42 def_coordinate (void);





extern  pnl_orientation   def_orientation (void);





extern  int   def_number (void);





extern SetWordType def_err1 [];
extern SetWordType def_err2 [];
extern SetWordType def_setwd1 [];
extern SetWordType def_err3 [];
extern SetWordType def_err4 [];
extern SetWordType def_err5 [];
extern SetWordType def_setwd2 [];
extern SetWordType def_err6 [];
extern SetWordType def_setwd3 [];
extern SetWordType def_setwd4 [];
extern SetWordType def_err7 [];
extern SetWordType def_err8 [];
extern SetWordType def_err9 [];
extern SetWordType def_err10 [];
extern SetWordType def_err11 [];
extern SetWordType def_err12 [];
extern SetWordType def_setwd5 [];
extern SetWordType def_err13 [];
extern SetWordType def_err14 [];
extern SetWordType def_err15 [];
extern SetWordType def_err16 [];
extern SetWordType def_err17 [];
extern SetWordType def_setwd6 [];
extern SetWordType def_err18 [];
extern SetWordType def_setwd7 [];
# 30 "def_parse.g" 2

# 1 "/volume/mmi/utils/pccts/h/dlgdef.h" 1
 











































struct zzdlg_state {
	FILE *stream;

	int (*func_ptr)(void);



	char  *str;
	int auto_num;
	int add_erase;
	int lookc;
	int char_full;
	int begcol, endcol;
	int line;
	char  *lextext, *begexpr, *endexpr;
	int bufsize;
	int bufovf;
	char  *nextpos;
	int	class_num;
};

extern char 	* def_zzlextext ;  	 
extern char 	* def_zzbegexpr ;	 
extern char 	* def_zzendexpr ;	 
extern int	def_zzbufsize ;	 
extern int	def_zzbegcol ;	 
extern int	def_zzendcol ;	 
extern int	def_zzline ;		 
extern int	def_zzreal_line ;		 
extern int	def_zzchar ;		 
extern int	def_zzbufovf ;	 

extern void	(* def_zzerr )(const char *); 









extern void	def_zzadvance (void);
extern void	def_zzskip (void);	 
extern void	def_zzmore (void);	 
extern void	def_zzmode (int k);	 
extern void	def_zzrdstream (FILE *); 
extern void	def_zzclose_stream (void); 
extern void	def_zzrdfunc (int (*)(void)); 
extern void def_zzrdstr ( char  * );
extern void	def_zzgettok (void);	 
extern void	def_zzreplchar (char  c); 

extern void	def_zzreplstr (char  *s); 

extern void def_zzsave_dlg_state (struct zzdlg_state *);
extern void def_zzrestore_dlg_state (struct zzdlg_state *);
extern int def_zzerr_in (void);
extern void	def_zzerrstd (const char *);
extern void def_zzerraction (void);

# 126 "/volume/mmi/utils/pccts/h/dlgdef.h"



# 31 "def_parse.g" 2

# 1 "mode.h" 1







# 32 "def_parse.g" 2




Attrib def_zzempty_attr (void) {static Attrib a; return a;}	Attrib def_zzconstr_attr (int _tok, char *_text)	{Attrib a; (( (&a) )-> _text  = ( _text ))) ; return a;}	int def_zzasp = 400 ;	char def_zzStackOvfMsg []="fatal: attrib/AST stack overflow %s(%d)!\n"; Attrib def_zzaStack [400 ];  	    
# 30 "def_parse.g"




int def_parse_fprintf(FILE*somewhere,char *fmt, ...)
{
	va_list args;
	(__builtin_next_arg ( fmt ),  args  = (char *) __builtin_saveregs ()) ;
	if (somewhere== (&__iob[2]) ) {
		MsgErrorV(fmt,args);
	} else {
		vfprintf(somewhere,fmt,args);
	}
	((void)0) ;
	return 0;
}

 
 


int def2max_pre_comment_mode;

void

def_def_file (void)



{
# 215 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 218);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 215 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 218);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_setwd1 [def_zztoken  ]&0x1) ) {
# 215 "def_parse.g"

			def_header ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 216 "def_parse.g"

	def_def_design ();
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd1 , 0x2);
	}
}

void

def_header (void)



{
# 219 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 222);	exit(1 ); } ; -- def_zzasp ;} ;
	{
	if ( (def_zztoken  == 69 ) ) {
# 219 "def_parse.g"

		def_version ();
	}
	else {
		if ( (def_zztoken  == 31 ) ) {
# 220 "def_parse.g"

			def_namescasesensitive ();
		}
		else {
			if ( (def_zztoken  == 18 ) ) {
# 221 "def_parse.g"

				def_dividerchar ();
			}
			else {
				if ( (def_zztoken  == 6 ) ) {
# 222 "def_parse.g"

					def_busbitchars ();
				}
				else {def_zzFAIL (1,def_err1 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd1 , 0x4);
	}
}

void

def_version (void)



{
# 225 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 228);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 225 "def_parse.g"

	if ( ! def__zzmatch ( 69  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 225 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 225 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 225 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd1 , 0x8);
	}
}

void

def_namescasesensitive (void)



{
# 228 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 231);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 229 "def_parse.g"

	if ( ! def__zzmatch ( 31  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 229 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 232);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 36 ) ) {
# 229 "def_parse.g"

			if ( ! def__zzmatch ( 36  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
		}
		else {
			if ( (def_zztoken  == 35 ) ) {
# 229 "def_parse.g"

				if ( ! def__zzmatch ( 35  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
			}
			else {def_zzFAIL (1,def_err2 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 229 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd1 , 0x10);
	}
}

void

def_dividerchar (void)



{
# 232 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib str;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 236);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 232 "def_parse.g"

	if ( ! def__zzmatch ( 18  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 232 "def_parse.g"

	if ( ! def__zzmatch ( 99  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	str = (def_zzaStack [def_zzasp ]) ;

# 233 "def_parse.g"

	def2max_divider_char ( str.text);
 def_zzgettok (); ;

# 234 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd1 , 0x20);
	}
}

void

def_busbitchars (void)



{
# 237 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 240);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 237 "def_parse.g"

	if ( ! def__zzmatch ( 6  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 237 "def_parse.g"

	if ( ! def__zzmatch ( 99  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 237 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd1 , 0x40);
	}
}

void

def_def_design (void)



{
# 240 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib name;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 244);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 240 "def_parse.g"

	if ( ! def__zzmatch ( 13  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 240 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 240 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	name = (def_zzaStack [def_zzasp ]) ;

# 241 "def_parse.g"

	def2max_design ( name.text);
 def_zzgettok (); ;

# 242 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 243 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 246);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_setwd1 [def_zztoken  ]&0x80) ) {
# 243 "def_parse.g"

			def_declaration ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 244 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 247);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_setwd2 [def_zztoken  ]&0x1) ) {
# 244 "def_parse.g"

			def_constituent ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 245 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 245 "def_parse.g"

	if ( ! def__zzmatch ( 13  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x2);
	}
}

void

def_declaration (void)



{
# 248 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 251);	exit(1 ); } ; -- def_zzasp ;} ;
	{
	if ( (def_zztoken  == 65 ) ) {
# 248 "def_parse.g"

		def_units_decl ();
	}
	else {
		if ( (def_zztoken  == 14 ) ) {
# 249 "def_parse.g"

			def_diearea_decl ();
		}
		else {
			if ( (def_zztoken  == 63 ) ) {
# 250 "def_parse.g"

				def_tracks_decl ();
			}
			else {
				if ( (def_zztoken  == 24 ) ) {
# 251 "def_parse.g"

					def_history_decl ();
				}
				else {
					if ( (def_zztoken  == 48 ) ) {
# 252 "def_parse.g"

						def_row_decl ();
					}
					else {
						if ( (def_zztoken  == 44 ) ) {
# 253 "def_parse.g"

							def_propertydefinitions_decl ();
						}
						else {
							if ( (def_zztoken  == 22 ) ) {
# 254 "def_parse.g"

								def_gcellgrid_decl ();
							}
							else {def_zzFAIL (1,def_err3 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
						}
					}
				}
			}
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x4);
	}
}

void

def_units_decl (void)



{
# 257 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib id;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 261);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 257 "def_parse.g"

	char *name;
	int num;
# 260 "def_parse.g"

	if ( ! def__zzmatch ( 65  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 260 "def_parse.g"

	if ( ! def__zzmatch ( 17  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 260 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 261 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	id = (def_zzaStack [def_zzasp ]) ;

# 261 "def_parse.g"

	name = (  id.text ) ;
 def_zzgettok (); ;

# 262 "def_parse.g"

	 num  = def_number ();

# 263 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 264 "def_parse.g"

	def2max_distance_units (name, num);
 def_zzgettok (); ;

	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x8);
	}
}

void

def_diearea_decl (void)



{
# 267 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 270);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 267 "def_parse.g"

	int x0, y0;
	int x1, y1;
# 270 "def_parse.g"

	if ( ! def__zzmatch ( 14  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 270 "def_parse.g"

	{ struct _rv42 _trv; _trv = def_coordinate ();

	x0 = _trv.x; y0  = _trv.y; }
# 270 "def_parse.g"

	{ struct _rv42 _trv; _trv = def_coordinate ();

	x1 = _trv.x; y1  = _trv.y; }
# 271 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 272 "def_parse.g"

	def2max_die_area (x0, y0, x1, y1);
 def_zzgettok (); ;

	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x10);
	}
}

void

def_tracks_decl (void)



{
# 275 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib id;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 279);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 275 "def_parse.g"

	if ( ! def__zzmatch ( 63  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 276 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 279);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 73 ) ) {
# 276 "def_parse.g"

			if ( ! def__zzmatch ( 73  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
		}
		else {
			if ( (def_zztoken  == 74 ) ) {
# 276 "def_parse.g"

				if ( ! def__zzmatch ( 74  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
			}
			else {def_zzFAIL (1,def_err4 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 277 "def_parse.g"

	def_number ();
# 278 "def_parse.g"

	if ( ! def__zzmatch ( 19  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 278 "def_parse.g"

	def_number ();
# 279 "def_parse.g"

	if ( ! def__zzmatch ( 58  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 279 "def_parse.g"

	def_number ();
# 280 "def_parse.g"

	if ( ! def__zzmatch ( 29  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 280 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 281 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		int zzcnt=1;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 285);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		do {
# 281 "def_parse.g"

			if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
			id = (def_zzaStack [def_zzasp ]) ;
 def_zzgettok (); ;
			def_zzasp =(  zztasp2  );  ;
		} while ( (def_zztoken  == 91 ) );
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 282 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x20);
	}
}

void

def_history_decl (void)



{
# 285 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib hist;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 289);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 285 "def_parse.g"

	if ( ! def__zzmatch ( 24  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 285 "def_parse.g"

	def_zzmode  (4 );
 def_zzgettok (); ;

# 285 "def_parse.g"

	if ( ! def__zzmatch ( 105  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	hist = (def_zzaStack [def_zzasp ]) ;

# 286 "def_parse.g"

	def2max_history ( hist.text);
 def_zzgettok (); ;

	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x40);
	}
}

void

def_row_decl (void)



{
# 289 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib name_id, core_id;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 293);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 290 "def_parse.g"

	if ( ! def__zzmatch ( 48  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 290 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 291 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	name_id = (def_zzaStack [def_zzasp ]) ;

# 291 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 292 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	core_id = (def_zzaStack [def_zzasp ]) ;
 def_zzgettok (); ;
# 293 "def_parse.g"

	def_number ();
# 293 "def_parse.g"

	def_number ();
# 293 "def_parse.g"

	def_orientation ();
# 294 "def_parse.g"

	if ( ! def__zzmatch ( 19  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 294 "def_parse.g"

	def_number ();
# 294 "def_parse.g"

	if ( ! def__zzmatch ( 7  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 294 "def_parse.g"

	def_number ();
# 295 "def_parse.g"

	if ( ! def__zzmatch ( 58  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 295 "def_parse.g"

	def_number ();
# 295 "def_parse.g"

	def_number ();
# 296 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd2 , 0x80);
	}
}

void

def_gcellgrid_decl (void)



{
# 299 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 302);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 299 "def_parse.g"

	if ( ! def__zzmatch ( 22  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 299 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 302);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 73 ) ) {
# 299 "def_parse.g"

			if ( ! def__zzmatch ( 73  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
		}
		else {
			if ( (def_zztoken  == 74 ) ) {
# 299 "def_parse.g"

				if ( ! def__zzmatch ( 74  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
			}
			else {def_zzFAIL (1,def_err5 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 299 "def_parse.g"

	def_number ();
# 300 "def_parse.g"

	if ( ! def__zzmatch ( 19  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 300 "def_parse.g"

	def_number ();
# 300 "def_parse.g"

	if ( ! def__zzmatch ( 58  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 300 "def_parse.g"

	def_number ();
# 300 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x1);
	}
}

void

def_propertydefinitions_decl (void)



{
# 303 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 306);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 304 "def_parse.g"

	if ( ! def__zzmatch ( 44  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 305 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 308);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  == 13 ) ) {
# 305 "def_parse.g"

			def_propertydefinition ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 306 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 306 "def_parse.g"

	if ( ! def__zzmatch ( 44  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x2);
	}
}

void

def_propertydefinition (void)



{
# 309 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 312);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 310 "def_parse.g"

	if ( ! def__zzmatch ( 13  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 310 "def_parse.g"

	if ( ! def__zzmatch ( 68  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 311 "def_parse.g"

	if ( ! def__zzmatch ( 60  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 311 "def_parse.g"

	if ( ! def__zzmatch ( 99  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 311 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x4);
	}
}

void

def_constituent (void)



{
# 314 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 317);	exit(1 ); } ; -- def_zzasp ;} ;
	{
	if ( (def_zztoken  == 71 ) ) {
# 314 "def_parse.g"

		def_vias ();
	}
	else {
		if ( (def_zztoken  == 10 ) ) {
# 315 "def_parse.g"

			def_components ();
		}
		else {
			if ( (def_zztoken  == 55 ) ) {
# 316 "def_parse.g"

				def_specialnets ();
			}
			else {
				if ( (def_zztoken  == 33 ) ) {
# 317 "def_parse.g"

					def_nets ();
				}
				else {
					if ( (def_zztoken  == 41 ) ) {
# 318 "def_parse.g"

						def_pins ();
					}
					else {def_zzFAIL (1,def_err6 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x8);
	}
}

void

def_vias (void)



{
# 321 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 324);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 321 "def_parse.g"

	if ( ! def__zzmatch ( 71  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 321 "def_parse.g"

	def_number ();
# 321 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 322 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 325);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  ==111) ) {
# 322 "def_parse.g"

			def_via ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 323 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 323 "def_parse.g"

	if ( ! def__zzmatch ( 71  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x10);
	}
}

void

def_via (void)



{
# 326 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 329);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 326 "def_parse.g"

	if ( ! def__zzmatch ( 111 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 326 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 326 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 326 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 329);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  == 83 ) ) {
# 326 "def_parse.g"

			def_via_plus ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 326 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x20);
	}
}

void

def_via_plus (void)



{
# 329 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 332);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 329 "def_parse.g"

	if ( ! def__zzmatch ( 83  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 329 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 332);	exit(1 ); } ; -- def_zzasp ;} ;
		{
# 329 "def_parse.g"

		def_rect_clause ();
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x40);
	}
}

void

def_components (void)



{
# 332 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 335);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 332 "def_parse.g"

	if ( ! def__zzmatch ( 10  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 332 "def_parse.g"

	def_number ();
# 332 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 333 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 336);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  ==111) ) {
# 333 "def_parse.g"

			def_component ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 334 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 334 "def_parse.g"

	if ( ! def__zzmatch ( 10  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd3 , 0x80);
	}
}

void

def_component (void)



{
# 337 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib i, m;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 341);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 337 "def_parse.g"

	char *inst_name;
	char *mod_name;
# 340 "def_parse.g"

	if ( ! def__zzmatch ( 111 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 340 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 340 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	i = (def_zzaStack [def_zzasp ]) ;

# 341 "def_parse.g"

	inst_name = (  i.text ) ;
	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 344 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	m = (def_zzaStack [def_zzasp ]) ;

# 345 "def_parse.g"

	mod_name = (  m.text ) ;
 def_zzgettok (); ;

# 346 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 349);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  == 83 ) ) {
# 346 "def_parse.g"

			def_component_plus ( inst_name, mod_name );
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 346 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x1);
	}
}

void

def_pins (void)



{
# 349 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 352);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 349 "def_parse.g"

	if ( ! def__zzmatch ( 41  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 349 "def_parse.g"

	def_number ();
# 349 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 350 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 353);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  ==111) ) {
# 350 "def_parse.g"

			def_pin ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 351 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 351 "def_parse.g"

	if ( ! def__zzmatch ( 41  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x2);
	}
}

void

def_pin (void)



{
# 354 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib n;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 358);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 354 "def_parse.g"

	pnl_port pport;
# 355 "def_parse.g"

	if ( ! def__zzmatch ( 111 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 355 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 355 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	n = (def_zzaStack [def_zzasp ]) ;

# 356 "def_parse.g"

	pport = def2max_pin ( n.text);
 def_zzgettok (); ;

# 357 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 360);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  == 83 ) ) {
# 357 "def_parse.g"

			def_pin_plus ( pport );
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 357 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x4);
	}
}

void

def_nets (void)



{
# 360 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 363);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 360 "def_parse.g"

	if ( ! def__zzmatch ( 33  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 360 "def_parse.g"

	def_number ();
# 360 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 361 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 364);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  ==111) ) {
# 361 "def_parse.g"

			def_net ( 0 );
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 362 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 362 "def_parse.g"

	if ( ! def__zzmatch ( 33  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x8);
	}
}

void

def_specialnets (void)



{
# 365 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 368);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 365 "def_parse.g"

	if ( ! def__zzmatch ( 55  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 365 "def_parse.g"

	def_number ();
# 365 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 366 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 369);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  ==111) ) {
# 366 "def_parse.g"

			def_net ( 1 );
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 367 "def_parse.g"

	if ( ! def__zzmatch ( 20  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 367 "def_parse.g"

	if ( ! def__zzmatch ( 55  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x10);
	}
}

void

def_net ( int special )




{
# 370 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib id;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 374);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 371 "def_parse.g"

	pnl_net pnet;
# 372 "def_parse.g"

	if ( ! def__zzmatch ( 111 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 372 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 372 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	id = (def_zzaStack [def_zzasp ]) ;

# 373 "def_parse.g"

	pnet = def2max_net ( id.text, special);
 def_zzgettok (); ;

# 374 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 377);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  ==112) ) {
# 374 "def_parse.g"

			def_net_connection ();
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 374 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 377);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  == 83 ) ) {
# 374 "def_parse.g"

			def_net_plus ( pnet, special );
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 374 "def_parse.g"

	if ( ! def__zzmatch ( 84  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x20);
	}
}

void

def_net_connection (void)



{
# 377 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib cell;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 381);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 377 "def_parse.g"

	if ( ! def__zzmatch ( 112 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 377 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 377 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	cell = (def_zzaStack [def_zzasp ]) ;

# 378 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 378 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 378 "def_parse.g"

	if ( ! def__zzmatch ( 113 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x40);
	}
}

void

def_component_plus ( char *inst_name, char *mod_name )





{
# 386 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 389);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 387 "def_parse.g"

	pnl_loctype loctype;
	int x, y;
	pnl_orientation orient;
# 391 "def_parse.g"

	if ( ! def__zzmatch ( 83  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 391 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 394);	exit(1 ); } ; -- def_zzasp ;} ;
		{
# 391 "def_parse.g"

		{ struct _rv32 _trv; _trv = def_placed_clause ();

		loctype = _trv.loctype; x = _trv.x; y = _trv.y; orient  = _trv.orient; }
# 392 "def_parse.g"

		def2max_component (inst_name, mod_name,
		loctype, x, y, orient);
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd4 , 0x80);
	}
}

void

def_pin_plus ( pnl_port pport )




{
# 398 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 401);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 399 "def_parse.g"

	pnl_loctype loctype;
	int x, y;
	pnl_orientation orient;
# 403 "def_parse.g"

	if ( ! def__zzmatch ( 83  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 404 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 407);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_setwd5 [def_zztoken  ]&0x1) ) {
# 404 "def_parse.g"

			{ struct _rv32 _trv; _trv = def_placed_clause ();

			loctype = _trv.loctype; x = _trv.x; y = _trv.y; orient  = _trv.orient; }
# 405 "def_parse.g"

			 
			 
			 
		}
		else {
			if ( (def_zztoken  == 32 ) ) {
# 409 "def_parse.g"

				def_net_clause ();
			}
			else {
				if ( (def_zztoken  == 15 ) ) {
# 410 "def_parse.g"

					def_dir_clause ();
				}
				else {
					if ( (def_zztoken  == 67 ) ) {
# 411 "def_parse.g"

						def_use_clause ();
					}
					else {
						if ( (def_zztoken  == 29 ) ) {
# 412 "def_parse.g"

							def_layer_clause ( pport );
						}
						else {def_zzFAIL (1,def_err7 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
					}
				}
			}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd5 , 0x2);
	}
}

void

def_net_plus ( pnl_net pnet, int special )





{
# 416 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 419);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 417 "def_parse.g"

	pnl_use use;
	pnl_pattern pattern;
	pnl_route route;
# 421 "def_parse.g"

	if ( ! def__zzmatch ( 83  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 422 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 425);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 67 ) ) {
# 422 "def_parse.g"

			 use  = def_use_clause ();

# 423 "def_parse.g"

			 
		}
		else {
			if ( (def_zztoken  == 39 ) ) {
# 424 "def_parse.g"

				 pattern  = def_pattern_clause ();

# 425 "def_parse.g"

				 
			}
			else {
				if ( (def_setwd5 [def_zztoken  ]&0x4) ) {
# 426 "def_parse.g"

					 route  = def_route_clause ( special );

# 427 "def_parse.g"

					 
				}
				else {def_zzFAIL (1,def_err8 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd5 , 0x8);
	}
}

struct _rv32

def_placed_clause (void)



{
	struct _rv32 _retv;
# 431 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof(struct _rv32) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 435);	exit(1 ); } ; -- def_zzasp ;} ;
	{
	if ( (def_setwd5 [def_zztoken  ]&0x10) ) {
# 432 "def_parse.g"

		{
			int  zztasp2  = def_zzasp  - 1 ;
			{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 435);	exit(1 ); } ; -- def_zzasp ;} ;
			{
			if ( (def_zztoken  == 42 ) ) {
# 432 "def_parse.g"

				if ( ! def__zzmatch ( 42  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 432 "def_parse.g"

				_retv.loctype = pnl_loctype_PLACED;
 def_zzgettok (); ;

			}
			else {
				if ( (def_zztoken  == 21 ) ) {
# 433 "def_parse.g"

					if ( ! def__zzmatch ( 21  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 433 "def_parse.g"

					_retv.loctype = pnl_loctype_FIXED;
 def_zzgettok (); ;

				}
				else {
					if ( (def_zztoken  == 11 ) ) {
# 434 "def_parse.g"

						if ( ! def__zzmatch ( 11  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 434 "def_parse.g"

						_retv.loctype = pnl_loctype_COVER;
 def_zzgettok (); ;

					}
					else {def_zzFAIL (1,def_err9 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
			def_zzasp =(  zztasp2  );  ;
			}
		}
# 436 "def_parse.g"

		{ struct _rv42 _trv; _trv = def_coordinate ();

		_retv.x = _trv.x; _retv.y  = _trv.y; }
# 436 "def_parse.g"

		 _retv.orient  = def_orientation ();

	}
	else {
		if ( (def_zztoken  == 66 ) ) {
# 438 "def_parse.g"

			if ( ! def__zzmatch ( 66  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 438 "def_parse.g"

			_retv.loctype = pnl_loctype_UNPLACED;
			_retv.x = 0;
			_retv.y = 0;
			_retv.orient = pnl_orientation_none;
 def_zzgettok (); ;

		}
		else {def_zzFAIL (1,def_err10 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd5 , 0x20);
	return _retv;
	}
}

void

def_net_clause (void)



{
# 445 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 448);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 445 "def_parse.g"

	if ( ! def__zzmatch ( 32  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 445 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 445 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd5 , 0x40);
	}
}

void

def_dir_clause (void)



{
# 448 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 451);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 448 "def_parse.g"

	if ( ! def__zzmatch ( 15  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 448 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 451);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 28 ) ) {
# 448 "def_parse.g"

			if ( ! def__zzmatch ( 28  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
		}
		else {
			if ( (def_zztoken  == 38 ) ) {
# 448 "def_parse.g"

				if ( ! def__zzmatch ( 38  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
			}
			else {
				if ( (def_zztoken  == 27 ) ) {
# 448 "def_parse.g"

					if ( ! def__zzmatch ( 27  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
				}
				else {def_zzFAIL (1,def_err11 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd5 , 0x80);
	}
}

 pnl_use  

def_use_clause (void)



{
	 pnl_use  	 _retv;
# 451 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( pnl_use  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 455);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 452 "def_parse.g"

	if ( ! def__zzmatch ( 67  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 453 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 456);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 50 ) ) {
# 453 "def_parse.g"

			if ( ! def__zzmatch ( 50  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 453 "def_parse.g"

			_retv = pnl_use_SIGNAL;
 def_zzgettok (); ;

		}
		else {
			if ( (def_zztoken  == 43 ) ) {
# 454 "def_parse.g"

				if ( ! def__zzmatch ( 43  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 454 "def_parse.g"

				_retv = pnl_use_POWER;
 def_zzgettok (); ;

			}
			else {
				if ( (def_zztoken  == 23 ) ) {
# 455 "def_parse.g"

					if ( ! def__zzmatch ( 23  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 455 "def_parse.g"

					_retv = pnl_use_GROUND;
 def_zzgettok (); ;

				}
				else {
					if ( (def_zztoken  == 8 ) ) {
# 456 "def_parse.g"

						if ( ! def__zzmatch ( 8  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 456 "def_parse.g"

						_retv = pnl_use_CLOCK;
 def_zzgettok (); ;

					}
					else {
						if ( (def_zztoken  == 62 ) ) {
# 457 "def_parse.g"

							if ( ! def__zzmatch ( 62  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 457 "def_parse.g"

							_retv = pnl_use_TIEOFF;
 def_zzgettok (); ;

						}
						else {
							if ( (def_zztoken  == 4 ) ) {
# 458 "def_parse.g"

								if ( ! def__zzmatch ( 4  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 458 "def_parse.g"

								_retv = pnl_use_ANALOG;
 def_zzgettok (); ;

							}
							else {def_zzFAIL (1,def_err12 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
						}
					}
				}
			}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x1);
	return _retv;
	}
}

 pnl_pattern  

def_pattern_clause (void)



{
	 pnl_pattern  	 _retv;
# 462 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( pnl_pattern  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 466);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 463 "def_parse.g"

	if ( ! def__zzmatch ( 39  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 464 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 467);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 57 ) ) {
# 464 "def_parse.g"

			if ( ! def__zzmatch ( 57  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 464 "def_parse.g"

			_retv = pnl_pattern_STEINER;
 def_zzgettok (); ;

		}
		else {
			if ( (def_zztoken  == 5 ) ) {
# 465 "def_parse.g"

				if ( ! def__zzmatch ( 5  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 465 "def_parse.g"

				_retv = pnl_pattern_BALANCED;
 def_zzgettok (); ;

			}
			else {
				if ( (def_zztoken  == 72 ) ) {
# 466 "def_parse.g"

					if ( ! def__zzmatch ( 72  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 466 "def_parse.g"

					_retv = pnl_pattern_WIREDLOGIC;
 def_zzgettok (); ;

				}
				else {
					if ( (def_zztoken  == 64 ) ) {
# 467 "def_parse.g"

						if ( ! def__zzmatch ( 64  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 467 "def_parse.g"

						_retv = pnl_pattern_TRUNK;
 def_zzgettok (); ;

					}
					else {def_zzFAIL (1,def_err13 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x2);
	return _retv;
	}
}

 pnl_route  

def_route_clause ( int special )




{
	 pnl_route  	 _retv;
# 471 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( pnl_route  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 475);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 472 "def_parse.g"

	pnl_routekind routekind;
	pnl_branch branch;
# 475 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 478);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 47 ) ) {
# 475 "def_parse.g"

			if ( ! def__zzmatch ( 47  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 475 "def_parse.g"

			routekind = pnl_routekind_ROUTED; def_zzmode  (1 ) ;
 def_zzgettok (); ;

		}
		else {
			if ( (def_zztoken  == 21 ) ) {
# 476 "def_parse.g"

				if ( ! def__zzmatch ( 21  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 476 "def_parse.g"

				routekind = pnl_routekind_FIXED; def_zzmode  (1 ) ;
 def_zzgettok (); ;

			}
			else {
				if ( (def_zztoken  == 11 ) ) {
# 477 "def_parse.g"

					if ( ! def__zzmatch ( 11  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 477 "def_parse.g"

					routekind = pnl_routekind_COVER; def_zzmode  (1 ) ;
 def_zzgettok (); ;

				}
				else {def_zzFAIL (1,def_err14 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 479 "def_parse.g"

	_retv = 0;  
# 480 "def_parse.g"

	 branch  = def_route_branch ( special );

# 481 "def_parse.g"

	 
# 486 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 489);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		while ( (def_zztoken  == 34 ) ) {
# 482 "def_parse.g"

			if ( ! def__zzmatch ( 34  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 483 "def_parse.g"

			def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 484 "def_parse.g"

			 branch  = def_route_branch ( special );

# 485 "def_parse.g"

			 
			def_zzasp =(  zztasp2  );  ;
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x4);
	return _retv;
	}
}

 pnl_branch  

def_route_branch ( int special )




{
	 pnl_branch  	 _retv;
# 489 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib id;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( pnl_branch  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 494);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 490 "def_parse.g"

	int x0;
	int y0;
	int width = -1;
	pnl_segment segment;
	char *layer;
# 496 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	id = (def_zzaStack [def_zzasp ]) ;

# 497 "def_parse.g"

	layer = (  id.text ) ;
 def_zzgettok (); ;

# 498 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 501);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 85 ) ) {
			if (!(
# 498 "def_parse.g"

special )) {def2max_failed_pred( "   special " ); ;}
# 498 "def_parse.g"

			 width  = def_number ();

		}
		else {
			if ( (def_zztoken  ==112) ) {
				if (!(
# 499 "def_parse.g"

!special)) {def2max_failed_pred( "   !special" ); ;}
			}
			else {def_zzFAIL (1,def_err15 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
# 501 "def_parse.g"

	if ( ! def__zzmatch ( 112 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 501 "def_parse.g"

	 x0  = def_number ();

# 501 "def_parse.g"

	 y0  = def_number ();

# 501 "def_parse.g"

	if ( ! def__zzmatch ( 113 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 502 "def_parse.g"

	_retv = 0;  
	def_zzmode  (2 );
 def_zzgettok (); ;

# 505 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		int zzcnt=1;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 509);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		do {
# 505 "def_parse.g"

			 segment  = def_route_segment ();

# 506 "def_parse.g"

			 
			def_zzasp =(  zztasp2  );  ;
		} while ( (def_setwd6 [def_zztoken  ]&0x8) );
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x10);
	return _retv;
	}
}

 pnl_segment  

def_route_segment (void)



{
	 pnl_segment  	 _retv;
# 511 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib via_name;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( pnl_segment  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 516);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 512 "def_parse.g"

	int x, y;
# 513 "def_parse.g"

	{
		int  zztasp2  = def_zzasp  - 1 ;
		{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 516);	exit(1 ); } ; -- def_zzasp ;} ;
		{
		if ( (def_zztoken  == 95 ) ) {
# 513 "def_parse.g"

			if ( ! def__zzmatch ( 95  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 513 "def_parse.g"

			{
				int  zztasp3  = def_zzasp  - 1 ;
				{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 516);	exit(1 ); } ; -- def_zzasp ;} ;
				{
				if ( (def_zztoken  == 85 ) ) {
# 513 "def_parse.g"

					 x  = def_number ();

# 513 "def_parse.g"

					if ( ! def__zzmatch ( 114 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 514 "def_parse.g"

					_retv = 0; 
 def_zzgettok (); ;

				}
				else {
					if ( (def_zztoken  ==114) ) {
# 515 "def_parse.g"

						if ( ! def__zzmatch ( 114 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 515 "def_parse.g"

						 y  = def_number ();

# 516 "def_parse.g"

						_retv = 0; 
					}
					else {def_zzFAIL (1,def_err16 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
				def_zzasp =(  zztasp3  );  ;
				}
			}
# 517 "def_parse.g"

			if ( ! def__zzmatch ( 113 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 518 "def_parse.g"

			def_zzmode  (2 );
 def_zzgettok (); ;

		}
		else {
			if ( (def_zztoken  == 91 ) ) {
# 519 "def_parse.g"

				if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
				via_name = (def_zzaStack [def_zzasp ]) ;

# 520 "def_parse.g"

				_retv = 0; 
				def_zzmode  (2 );
 def_zzgettok (); ;

			}
			else {def_zzFAIL (1,def_err17 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		def_zzasp =(  zztasp2  );  ;
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x20);
	return _retv;
	}
}

void

def_layer_clause ( pnl_port pport )




{
# 526 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib id;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 530);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 527 "def_parse.g"

	char *name;
	int x0, y0;
	int x1, y1;
# 531 "def_parse.g"

	if ( ! def__zzmatch ( 29  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 531 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 532 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	id = (def_zzaStack [def_zzasp ]) ;

# 532 "def_parse.g"

	name = (  id.text ) ;
 def_zzgettok (); ;

# 533 "def_parse.g"

	{ struct _rv42 _trv; _trv = def_coordinate ();

	x0 = _trv.x; y0  = _trv.y; }
# 533 "def_parse.g"

	{ struct _rv42 _trv; _trv = def_coordinate ();

	x1 = _trv.x; y1  = _trv.y; }
# 534 "def_parse.g"

	 
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x40);
	}
}

void

def_rect_clause (void)



{
# 538 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 541);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 538 "def_parse.g"

	if ( ! def__zzmatch ( 45  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 538 "def_parse.g"

	def_zzmode  (1 ) ;
 def_zzgettok (); ;

# 538 "def_parse.g"

	if ( ! def__zzmatch ( 91  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 538 "def_parse.g"

	def_coordinate ();
# 538 "def_parse.g"

	def_coordinate ();
	def_zzasp =(  zztasp1  );  ;
	return;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd6 , 0x80);
	}
}

struct _rv42

def_coordinate (void)



{
	struct _rv42 _retv;
# 541 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof(struct _rv42) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 545);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 542 "def_parse.g"

	if ( ! def__zzmatch ( 112 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
# 542 "def_parse.g"

	 _retv.x  = def_number ();

# 542 "def_parse.g"

	 _retv.y  = def_number ();

# 542 "def_parse.g"

	if ( ! def__zzmatch ( 113 , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ; def_zzgettok (); ;
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd7 , 0x1);
	return _retv;
	}
}

 pnl_orientation  

def_orientation (void)



{
	 pnl_orientation  	 _retv;
# 545 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( pnl_orientation  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 549);	exit(1 ); } ; -- def_zzasp ;} ;
	{
	if ( (def_zztoken  == 75 ) ) {
# 546 "def_parse.g"

		if ( ! def__zzmatch ( 75  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 546 "def_parse.g"

		_retv = pnl_orientation_N;
 def_zzgettok (); ;

	}
	else {
		if ( (def_zztoken  == 76 ) ) {
# 547 "def_parse.g"

			if ( ! def__zzmatch ( 76  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 547 "def_parse.g"

			_retv = pnl_orientation_S;
 def_zzgettok (); ;

		}
		else {
			if ( (def_zztoken  == 77 ) ) {
# 548 "def_parse.g"

				if ( ! def__zzmatch ( 77  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 548 "def_parse.g"

				_retv = pnl_orientation_E;
 def_zzgettok (); ;

			}
			else {
				if ( (def_zztoken  == 78 ) ) {
# 549 "def_parse.g"

					if ( ! def__zzmatch ( 78  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 549 "def_parse.g"

					_retv = pnl_orientation_W;
 def_zzgettok (); ;

				}
				else {
					if ( (def_zztoken  == 79 ) ) {
# 550 "def_parse.g"

						if ( ! def__zzmatch ( 79  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 550 "def_parse.g"

						_retv = pnl_orientation_FN;
 def_zzgettok (); ;

					}
					else {
						if ( (def_zztoken  == 80 ) ) {
# 551 "def_parse.g"

							if ( ! def__zzmatch ( 80  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 551 "def_parse.g"

							_retv = pnl_orientation_FS;
 def_zzgettok (); ;

						}
						else {
							if ( (def_zztoken  == 81 ) ) {
# 552 "def_parse.g"

								if ( ! def__zzmatch ( 81  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 552 "def_parse.g"

								_retv = pnl_orientation_FE;
 def_zzgettok (); ;

							}
							else {
								if ( (def_zztoken  == 82 ) ) {
# 553 "def_parse.g"

									if ( ! def__zzmatch ( 82  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
# 553 "def_parse.g"

									_retv = pnl_orientation_FW;
 def_zzgettok (); ;

								}
								else {def_zzFAIL (1,def_err18 ,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
							}
						}
					}
				}
			}
		}
	}
	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd7 , 0x2);
	return _retv;
	}
}

 int  

def_number (void)



{
	 int  	 _retv;
# 556 "def_parse.g"

	Attrib *zzaRetPtr = &(def_zzaStack [def_zzasp -1]);	int zzBadTok=0; char *zzBadText="";	int zzErrk=1,zzpf=0;	  SetWordType *zzMissSet= 0 ; int zzMissTok=0; char *zzMissText="" ;
	Attrib n;
	int  zztasp1  = def_zzasp  - 1 ;
	memset((char *) &( _retv ),'\0',( sizeof( int  	) )); 
	{ if ( def_zzasp  <= 0 ) { def_parse_fprintf ((&__iob[2]) , def_zzStackOvfMsg , "def_parse.g", 561);	exit(1 ); } ; -- def_zzasp ;} ;
	{
# 557 "def_parse.g"

	if ( ! def__zzmatch ( 85  , &zzBadText, &zzMissText, &zzMissTok, &zzBadTok, &zzMissSet) ) goto fail; ;
	n = (def_zzaStack [def_zzasp ]) ;

# 557 "def_parse.g"

	_retv = atoi ( n.text);
 def_zzgettok (); ;

	def_zzasp =(  zztasp1  );  ;
	return _retv;
fail:
	def_zzasp =(  zztasp1  );  ;
	def_zzsyn (zzMissText, zzBadTok, (ANTLRChar *)"", zzMissSet, zzMissTok, zzErrk, zzBadText);
	def_zzresynch (def_setwd7 , 0x4);
	return _retv;
	}
}
