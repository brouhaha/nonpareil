/*
 * casm.y: grammar
 *
 * CASM is an assembler for the processor used in the HP "Classic" series
 * of calculators, which includes the HP-35, HP-45, HP-55, HP-65, HP-70,
 * and HP-80.
 *
 * Copyright 1995 Eric Smith
 */

%{
#include <stdio.h>
#include "casm.h"
#include "symtab.h"
%}

%union {
    int integer;
    char *string;
  }

%token <integer> INTEGER
%token <string> IDENT
%token <integer> FIELDSPEC

%token GE
%token ARROW

%token <integer> STATBIT

%token A B C M P

%token ADDRESS
%token CARRY
%token CLEAR
%token CONSTANT
%token DATA
%token DELAYED
%token DISPLAY
%token DOWN
%token EXCHANGE
%token GO
%token GROUP
%token IF
%token JSB
%token LEFT
%token LOAD
%token NO
%token OFF
%token OPERATION
%token REGISTERS
%token RIGHT
%token ROM
%token ROTATE
%token SELECT
%token SHIFT
%token STACK
%token STATUS
%token THEN
%token TO
%token TOGGLE

%type <integer> expr

%%

file		:	/* nothing */
		|	file line
		;

line		:	label instruction '\n' { endline (); }
		|	label '\n' { endline (); }
		|	instruction '\n' { endline (); }
		|	'\n' { endline (); }
		;

label:		IDENT ':'	{ do_label ($1); }
		;

expr		: INTEGER { $$ = $1; }
		| IDENT { if (pass == 1)
                            $$ = 0;
                          else if (! lookup_symbol ($1, &$$))
                            {
                              fprintf (stderr, "undefined symbol '%s' on line %d\n", $1, lineno);
			      errors++;
                            }
			}
		;

instruction	: jsb_inst
	        | goto_inst
	        | arith_inst
		| status_inst
	        | pointer_inst
		| misc_inst
	        ;

jsb_inst        : JSB expr { emit (($2 << 2) | 0x001); }
                ;

goto_inst       : GO TO expr { emit (($3 << 2) | 0x003); }
                | THEN GO TO expr { emit (($4 << 2) | 0x003); }
                | IF NO CARRY GO TO expr { emit (($6 << 2) | 0x003); }

arith_inst      : inst_test_b_0
                | inst_0_to_b
                | inst_test_a_c
                | inst_test_c_1
                | inst_b_to_c
                | inst_tens_comp
                | inst_0_to_c
                | inst_nines_comp
                | inst_shl_a
                | inst_a_to_b
                | inst_a_min_c_c
                | inst_c_minus_1
                | inst_c_to_a
                | inst_test_c_0
                | inst_a_plus_c_c
                | inst_c_plus_1
                | inst_test_a_b
                | inst_b_exch_c
                | inst_shr_c
                | inst_test_a_1
                | inst_shr_b
                | inst_c_plus_c_c
                | inst_shr_a
                | inst_0_to_a
                | inst_a_min_b_a
                | inst_a_exch_b
                | inst_a_min_c_a
                | inst_a_minus_1
                | inst_a_plus_b_a
                | inst_a_exch_c
                | inst_a_plus_c_a
                | inst_a_plus_1
                ;

inst_test_b_0   : IF B FIELDSPEC '=' expr { range ($5, 0, 0);
                                            emit (($3 << 2) | 0x002); } ;
inst_test_c_0   : IF C FIELDSPEC '=' expr { range ($5, 0, 0); 
                                            emit (($3 << 2) | 0x1a2); } ;

inst_test_a_1   : IF A FIELDSPEC GE expr { range ($5, 1, 1);
                                           emit (($3 << 2) | 0x262); } ;
inst_test_c_1   : IF C FIELDSPEC GE expr { range ($5, 1, 1);
                                           emit (($3 << 2) | 0x062); } ;

inst_test_a_c   : IF A GE C FIELDSPEC { emit (($5 << 2) | 0x042); } ;
inst_test_a_b   : IF A GE B FIELDSPEC { emit (($5 << 2) | 0x202); } ;

inst_0_to_a     : expr ARROW A FIELDSPEC { range ($1, 0, 0); 
                                           emit (($4 << 2) | 0x2e2); } ;
inst_0_to_b     : expr ARROW B FIELDSPEC { range ($1, 0, 0); 
                                           emit (($4 << 2) | 0x022); } ;
inst_0_to_c     : expr ARROW C FIELDSPEC { range ($1, 0, 0);
                                           emit (($4 << 2) | 0x0c2); } ;

inst_nines_comp : expr '-' C '-' expr ARROW C FIELDSPEC { range ($1, 0, 0);
                                                          range ($5, 1, 1); 
                                                 emit (($8 << 2) | 0x0e2); } ;
inst_tens_comp  : expr '-' C ARROW C FIELDSPEC { range ($1, 0, 0);
                                                 emit (($6 << 2) | 0x0a2); } ;

inst_shl_a      : SHIFT LEFT A FIELDSPEC { emit (($4 << 2) | 0x102); } ;
inst_shr_a      : SHIFT RIGHT A FIELDSPEC { emit (($4 << 2) | 0x2c2); } ;
inst_shr_b      : SHIFT RIGHT B FIELDSPEC { emit (($4 << 2) | 0x282); } ;
inst_shr_c      : SHIFT RIGHT C FIELDSPEC { emit (($4 << 2) | 0x242); } ;

inst_a_to_b     : A ARROW B FIELDSPEC { emit (($4 << 2) | 0x122); } ;
inst_b_to_c     : B ARROW C FIELDSPEC { emit (($4 << 2) | 0x082); } ;
inst_c_to_a     : C ARROW A FIELDSPEC { emit (($4 << 2) | 0x182); } ;

inst_a_exch_b   : A EXCHANGE B FIELDSPEC { emit (($4 << 2) | 0x322); }
                | B EXCHANGE A FIELDSPEC { emit (($4 << 2) | 0x322); } ;
inst_b_exch_c   : B EXCHANGE C FIELDSPEC { emit (($4 << 2) | 0x222); } 
                | C EXCHANGE B FIELDSPEC { emit (($4 << 2) | 0x222); } ;
inst_a_exch_c   : A EXCHANGE C FIELDSPEC { emit (($4 << 2) | 0x3a2); } 
                | C EXCHANGE A FIELDSPEC { emit (($4 << 2) | 0x3a2); } ;

inst_a_min_b_a  : A '-' B ARROW A FIELDSPEC { emit (($6 << 2) | 0x302); } ;
inst_a_min_c_a  : A '-' C ARROW A FIELDSPEC { emit (($6 << 2) | 0x342); } ;
inst_a_min_c_c  : A '-' C ARROW C FIELDSPEC { emit (($6 << 2) | 0x142); } ;
inst_a_plus_b_a : A '+' B ARROW A FIELDSPEC { emit (($6 << 2) | 0x382); } 
                | B '+' A ARROW A FIELDSPEC { emit (($6 << 2) | 0x382); } ;
inst_a_plus_c_a : A '+' C ARROW A FIELDSPEC { emit (($6 << 2) | 0x3c2); } 
                | C '+' A ARROW A FIELDSPEC { emit (($6 << 2) | 0x3c2); } ;
inst_a_plus_c_c : A '+' C ARROW C FIELDSPEC { emit (($6 << 2) | 0x1c2); } 
                | C '+' A ARROW C FIELDSPEC { emit (($6 << 2) | 0x1c2); } ;
inst_c_plus_c_c : C '+' C ARROW C FIELDSPEC { emit (($6 << 2) | 0x2a2); } ;

inst_a_minus_1  : A '-' expr ARROW A FIELDSPEC { range ($3, 1, 1); 
                                                 emit (($6 << 2) | 0x362); } ;
inst_a_plus_1   : A '+' expr ARROW A FIELDSPEC { range ($3, 1, 1);  
                                                 emit (($6 << 2) | 0x3e2); } ;
inst_c_minus_1  : C '-' expr ARROW C FIELDSPEC { range ($3, 1, 1);  
                                                 emit (($6 << 2) | 0x162); } ;
inst_c_plus_1   : C '+' expr ARROW C FIELDSPEC { range ($3, 1, 1);  
                                                 emit (($6 << 2) | 0x1e2); } ;

status_inst     : inst_set_stat
                | inst_clr_stat
                | inst_tst_stat_e
                | inst_tst_stat_n
                ;

inst_set_stat   : expr ARROW STATBIT { range ($1, 0, 1);
                                  emit (($3 << 6) | ($1 ? 0x004 : 0x024)); } ;
inst_clr_stat   : CLEAR STATUS { emit (0x034); } ;
inst_tst_stat_n : IF STATBIT '#' expr { range ($4, 1, 1);
                                        emit (($2 << 6) | 0x014); } ;
inst_tst_stat_e : IF STATBIT '=' expr { range ($4, 0, 0);
                                        emit (($2 << 6) | 0x014); } ;

pointer_inst    : inst_load_p
                | inst_test_p
                | inst_incr_p
                | inst_decr_p
                ;

inst_load_p     : expr ARROW P       { range ($1, 0, 15);
                                       emit (($1 << 6) | 0x00c); } ;
inst_test_p     : IF P '#' expr      { range ($4, 0, 15);
                                       emit (($4 << 6) | 0x02c); } ;
inst_incr_p     : P '+' expr ARROW P { range ($3, 1, 1); emit (0x03c); } ;
inst_decr_p     : P '-' expr ARROW P { range ($3, 1, 1); emit (0x01c); } ;

misc_inst       : inst_load_const
                | inst_disp_off
                | inst_disp_tog
                | inst_c_exch_m
                | inst_m_to_c
                | inst_c_to_stack
                | inst_stack_to_a
                | inst_down_rot
                | inst_clr_reg
                | inst_sel_rom
                | inst_del_rom
                | inst_del_grp
                | inst_noop
                ;

inst_load_const : LOAD CONSTANT expr        { range ($3, 0, 9); 
                                              emit (($3 << 6) | 0x018); } ;
inst_disp_off   : DISPLAY OFF               { emit (0x228); } ;
inst_disp_tog   : DISPLAY TOGGLE            { emit (0x028); } ;
inst_c_exch_m   : C EXCHANGE M              { emit (0x0a8); } ;
inst_m_to_c     : M ARROW C                 { emit (0x288); } ;
inst_c_to_stack : C ARROW STACK             { emit (0x128); } ;
inst_stack_to_a : STACK ARROW A             { emit (0x1a8); } ;
inst_down_rot   : DOWN ROTATE               { emit (0x328); } ;
inst_clr_reg    : CLEAR REGISTERS           { emit (0x3a8); } ;
inst_sel_rom    : SELECT ROM expr           { range ($3, 0, 7);
                                              emit (($3 << 7) | 0x010); } ;
inst_del_rom    : DELAYED SELECT ROM expr   { range ($4, 0, 7); 
                                              emit (($4 << 7) | 0x074); } ;
inst_del_grp    : DELAYED SELECT GROUP expr { range ($4, 0, 1); 
                                              emit (($4 << 7) | 0x234); } ;
inst_noop       : NO OPERATION              { emit (0); } ;

%%
