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
extern int pc;

void do_label (char *s);

void emit (int op);

void endline (void);

void range (int val, int min, int max);

char *newstr (char *orig);
