/*
 * casm.h
 *
 * CASM is an assembler for the processor used in the HP "Classic" series
 * of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
 * and HP-80.
 *
 * Copyright 1995 Eric Smith
 */

extern int pass;
extern int lineno;
extern int errors;

extern int group;	/* current rom group */
extern int rom;		/* current rom */
extern int pc;		/* current pc */

extern int dsr;		/* delayed select rom */
extern int dsg;		/* delayed select group */

extern char flag_char;  /* used to mark jumps across rom banks */

#define MAX_LINE 256
extern char linebuf [MAX_LINE];
extern char *lineptr;

void do_label (char *s);

void emit (int op);
void etarget (int targrom, int targpc);  /* for branch target info */

void endline (void);

void range (int val, int min, int max);

char *newstr (char *orig);
