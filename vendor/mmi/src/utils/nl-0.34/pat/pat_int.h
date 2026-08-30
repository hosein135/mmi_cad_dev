

extern void pat_cmd_register_commands (Tcl_Interp *, char *, nl_context);

extern int pat_string_to_ori(char *ori);
extern void pat_trans_invert(Pat_transform *in, Pat_transform *out);
extern void pat_trans_rect(Pat_transform *tr, Pat_rect *box);
extern void pat_can_rect(Pat_rect *box);
extern void pat_trans_xy(Pat_transform *tr,int *px,int *py);
extern void pat_trans_trans(Pat_transform *t1, Pat_transform *t2, Pat_transform *out);
