/*
wasm.y: grammar
$Id$
Copyright 1995, 2004 Eric L. Smith

wasm is an assembler for the HP "Woodstock" processor architecture as
used in the second and third generation HP calculators:
  Woodstock:  HP-21, HP-22, HP-25, HP-25C, HP-27, HP-29C
  Topcat: HP-91, HP-92, HP-95C (unreleased), HP-97, HP-97S
  Hawkeye:  HP-67
  Sting:  HP-10, HP-19C
  Spice:  HP-31E, HP-32E, HP-33E, HP-37E, HP-38E, HP-33C, HP-34C, HP-38C

wasm is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.  Note that I am not granting permission to redistribute
or modify CASM under the terms of any later version of the General Public
License.

This program is distributed in the hope that it will be useful (or at least
amusing), but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
this program (in the file "COPYING"); if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

%{
#include <stdio.h>
#include "symtab.h"
#include "asm.h"

extern int ptr_load_map [14];
extern int ptr_test_map [14];
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
%token <integer> FLAGBIT

%token A B C F M1 M2 P Y

%token ADDRESS
%token BINARY
%token CLEAR
%token CONSTANT
%token DATA
%token DECIMAL
%token DELAYED
%token DISPLAY
%token DOWN
%token EXCHANGE
%token GO
%token HI
%token IAM
%token IF
%token JSB
%token KEYS
%token LEFT
%token LOAD
%token NC
%token NOP
%token OFF
%token REGISTER
%token REGISTERS
%token RESET
%token RETURN
%token RIGHT
%token ROM
%token ROTATE
%token SELECT
%token SHIFT
%token STACK
%token STATUS
%token SYMTAB
%token THEN
%token TO
%token TOGGLE
%token TWF
%token WOODSTOCK

%type <integer> expr
%type <integer> goto_form

%%

line		:	label instruction
		|	label
		|	instruction
		|	pseudo_op
		|	
		|	error
		;

label:		IDENT ':'	{ do_label ($1); }
		;

expr		: INTEGER { $$ = $1; }
		| IDENT { if (pass == 1)
                            $$ = 0;
                          else if (! lookup_symbol (symtab [group] [rom], $1, &$$))
			    {
			      error ("undefined symbol '%s'\n", $1);
			      $$ = 0;
			    }
			}
		;

pseudo_op	: ps_rom
		| ps_symtab
		;

ps_rom		: '.' ROM expr { $3 = range ($3, 0, MAXGROUP * MAXROM - 1);
				 group = dsg = ($3 >> 3);
				 rom = dsr = ($3 & 7); 
				 pc = 0;
				 last_instruction_type = OTHER_INST;
			         printf (" %d", $3); }
		;

ps_symtab	: '.' SYMTAB { symtab_flag = 1; }
		;

instruction	: jsb_inst
	        | goto_inst
		| then_inst
	        | arith_inst
		| status_inst
	        | pointer_inst
		| ram_inst
		| misc_inst
	        ;

jsb_inst        : JSB expr { emit (($2 << 2) | 00001); 
			     target (dsg, dsr, $2);
			     dsg = group;
			     dsr = rom; }
                ;

goto_inst	: goto_form { emit (($1 << 2) | 00003);
			      target (dsg, dsr, $1);
			      dsg = group;
			      dsr = rom; }
		;

goto_form       :  GO TO expr { $$ = $3; 
				     if (last_instruction_type == ARITH_INST)
				       warning ("unconditional goto shouldn't follow  arithmetic instruction\n"); 
				   }
                | IF NC GO TO expr { $$ = $5;
				    if (last_instruction_type != ARITH_INST)
				      warning ("'if no carry go to' should only follow arithmetic instructions\n"); }
		;

then_inst	: THEN GO TO expr { if (last_instruction_type != TEST_INST)
				      warning ("'then go to' should only follow 'if' instructions\n");
				    emit ($4 & 01377);
				  }
		;


arith_inst      : inst_0_to_a
                | inst_0_to_b
                | inst_a_exch_b
                | inst_a_to_b
                | inst_a_exch_c
                | inst_c_to_a
                | inst_b_to_c
                | inst_b_exch_c
                | inst_0_to_c
                | inst_a_plus_b_a
                | inst_a_plus_c_a
                | inst_c_plus_c_c
                | inst_a_plus_c_c
                | inst_a_plus_1
                | inst_shl_a
                | inst_c_plus_1
                | inst_a_min_b_a
                | inst_a_min_c_c
                | inst_a_minus_1
                | inst_c_minus_1
                | inst_tens_comp
                | inst_nines_comp
		| inst_test_b_0
                | inst_test_c_0
                | inst_test_a_c
                | inst_test_a_b
                | inst_test_a_1
                | inst_test_c_1
                | inst_a_min_c_a
                | inst_shr_a
                | inst_shr_b
                | inst_shr_c
                ;

inst_test_b_0   : IF B FIELDSPEC '=' expr { $5 = range ($5, 0, 0);
                                            emit_test (($3 << 2) | 01302); } ;
inst_test_c_0   : IF C FIELDSPEC '=' expr { $5 = range ($5, 0, 0); 
                                            emit_test (($3 << 2) | 01342); } ;

inst_test_a_1   : IF A FIELDSPEC GE expr { $5 = range ($5, 1, 1);
                                           emit_test (($3 << 2) | 01502); } ;
inst_test_c_1   : IF C FIELDSPEC GE expr { $5 = range ($5, 1, 1);
                                           emit_test (($3 << 2) | 01542); } ;

inst_test_a_c   : IF A GE C FIELDSPEC { emit_test (($5 << 2) | 01402); } ;
inst_test_a_b   : IF A GE B FIELDSPEC { emit_test (($5 << 2) | 01442); } ;

inst_0_to_a     : expr ARROW A FIELDSPEC { $1 = range ($1, 0, 0); 
                                           emit (($4 << 2) | 00002); } ;
inst_0_to_b     : expr ARROW B FIELDSPEC { $1 = range ($1, 0, 0); 
                                           emit (($4 << 2) | 00042); } ;
inst_0_to_c     : expr ARROW C FIELDSPEC { $1 = range ($1, 0, 0);
                                           emit (($4 << 2) | 00402); } ;

inst_nines_comp : expr '-' C '-' expr ARROW C FIELDSPEC { $1 = range ($1, 0, 0);
                                                          $5 = range ($5, 1, 1); 
                                                 emit_arith (($8 << 2) | 01242); } ;
inst_tens_comp  : expr '-' C ARROW C FIELDSPEC { $1 = range ($1, 0, 0);
                                                 emit_arith (($6 << 2) | 01202); } ;

inst_shl_a      : SHIFT LEFT A FIELDSPEC { emit (($4 << 2) | 00702); } ;
inst_shr_a      : SHIFT RIGHT A FIELDSPEC { emit (($4 << 2) | 01642); } ;
inst_shr_b      : SHIFT RIGHT B FIELDSPEC { emit (($4 << 2) | 01702); } ;
inst_shr_c      : SHIFT RIGHT C FIELDSPEC { emit (($4 << 2) | 01742); } ;

inst_a_to_b     : A ARROW B FIELDSPEC { emit (($4 << 2) | 00142); } ;
inst_b_to_c     : B ARROW C FIELDSPEC { emit (($4 << 2) | 00302); } ;
inst_c_to_a     : C ARROW A FIELDSPEC { emit (($4 << 2) | 00242); } ;

inst_a_exch_b   : A EXCHANGE B FIELDSPEC { emit (($4 << 2) | 00102); }
                | B EXCHANGE A FIELDSPEC { emit (($4 << 2) | 00102); } ;
inst_b_exch_c   : B EXCHANGE C FIELDSPEC { emit (($4 << 2) | 00342); } 
                | C EXCHANGE B FIELDSPEC { emit (($4 << 2) | 00342); } ;
inst_a_exch_c   : A EXCHANGE C FIELDSPEC { emit (($4 << 2) | 00202); } 
                | C EXCHANGE A FIELDSPEC { emit (($4 << 2) | 00202); } ;

inst_a_min_b_a  : A '-' B ARROW A FIELDSPEC { emit_arith (($6 << 2) | 01002); } ;
inst_a_min_c_a  : A '-' C ARROW A FIELDSPEC { emit_arith (($6 << 2) | 01602); } ;
inst_a_min_c_c  : A '-' C ARROW C FIELDSPEC { emit_arith (($6 << 2) | 01042); } ;
inst_a_plus_b_a : A '+' B ARROW A FIELDSPEC { emit_arith (($6 << 2) | 00442); } 
                | B '+' A ARROW A FIELDSPEC { emit_arith (($6 << 2) | 00442); } ;
inst_a_plus_c_a : A '+' C ARROW A FIELDSPEC { emit_arith (($6 << 2) | 00502); } 
                | C '+' A ARROW A FIELDSPEC { emit_arith (($6 << 2) | 00502); } ;
inst_a_plus_c_c : A '+' C ARROW C FIELDSPEC { emit_arith (($6 << 2) | 00602); } 
                | C '+' A ARROW C FIELDSPEC { emit_arith (($6 << 2) | 00602); } ;
inst_c_plus_c_c : C '+' C ARROW C FIELDSPEC { emit_arith (($6 << 2) | 00542); } ;

inst_a_minus_1  : A '-' expr ARROW A FIELDSPEC { $3 = range ($3, 1, 1); 
                                                 emit_arith (($6 << 2) | 01102); } ;
inst_a_plus_1   : A '+' expr ARROW A FIELDSPEC { $3 = range ($3, 1, 1);  
                                                 emit_arith (($6 << 2) | 00642); } ;
inst_c_minus_1  : C '-' expr ARROW C FIELDSPEC { $3 = range ($3, 1, 1);  
                                                 emit_arith (($6 << 2) | 01142); } ;
inst_c_plus_1   : C '+' expr ARROW C FIELDSPEC { $3 = range ($3, 1, 1);  
                                                 emit_arith (($6 << 2) | 00742); } ;

status_inst     : inst_set_stat
                | inst_clr_stat
                | inst_tst_stat_n
                | inst_tst_stat_e
                ;

inst_set_stat   : expr ARROW STATBIT { $1 = range ($1, 0, 1);
                                  emit (($3 << 6) | ($1 ? 00014 : 00004)); } ;
inst_clr_stat   : CLEAR STATUS { emit (00110); } ;
inst_tst_stat_e : IF STATBIT '=' expr { $4 = range ($4, 0, 1);
                                        emit_test (($2 << 6) | ($4 ? 00024 : 00034)); } ;
inst_tst_stat_n : IF STATBIT '#' expr { $4 = range ($4, 0, 1);
                                        emit_test (($2 << 6) | ($4 ? 00034 : 00024)); } ;

pointer_inst    : inst_load_p
                | inst_test_eq_p
                | inst_test_ne_p
                | inst_incr_p
                | inst_decr_p
                ;

inst_load_p     : expr ARROW P       { $1 = range ($1, 0, 13);
                                       emit ((ptr_load_map [$1] << 6) | 00074); } ;
inst_test_eq_p  : IF P '=' expr      { $4 = range ($4, 0, 13);
                                       emit_test ((ptr_test_map [$4] << 6) | 00044); } ;
inst_test_ne_p  : IF P '#' expr      { $4 = range ($4, 0, 13);
                                       emit_test ((ptr_test_map [$4] << 6) | 00054); } ;
inst_incr_p     : P '+' expr ARROW P { $3 = range ($3, 1, 1); emit (00720); } ;
inst_decr_p     : P '-' expr ARROW P { $3 = range ($3, 1, 1); emit (00620); } ;

ram_inst	: inst_c_to_addr
		| inst_c_to_data
		| inst_data_to_c
		| inst_c_to_reg
		| inst_reg_to_c
		;

inst_c_to_addr	: C ARROW DATA ADDRESS      { emit (01160); } ;
inst_c_to_data	: C ARROW DATA              { emit (01360); } ;
inst_data_to_c	: DATA ARROW C              { emit (00070); } ;
inst_c_to_reg	: C ARROW REGISTER expr     { $4 = range ($4, 0, 15);
					      emit (($4 << 6) | 00050); } ;
inst_reg_to_c	: REGISTER ARROW C expr     { $4 = range ($4, 1, 15);
					      emit (($4 << 6) | 00070); } ;

misc_inst       : inst_load_const
                | inst_disp_off
                | inst_disp_tog
                | inst_c_exch_m1
                | inst_m1_to_c
                | inst_c_exch_m2
                | inst_m2_to_c
                | inst_c_to_stack
                | inst_stack_to_a
		| inst_y_to_a
                | inst_down_rot
		| inst_f_to_a
		| inst_f_exch_a
                | inst_clr_reg
                | inst_sel_rom
                | inst_del_rom
                | inst_noop
		| inst_key_to_rom
		| inst_a_to_rom
/*		| inst_key_to_a */
		| inst_return
		| inst_binary
		| inst_decimal
		| inst_woodstock
                ;

inst_load_const : LOAD CONSTANT expr        { $3 = range ($3, 0, 15); 
                                              emit (($3 << 6) | 00030); } ;
inst_disp_off   : DISPLAY OFF               { emit (00310); } ;
inst_disp_tog   : DISPLAY TOGGLE            { emit (00210); } ;
inst_c_exch_m1  : C EXCHANGE M1             { emit (00410); }
		| M1 EXCHANGE C             { emit (00410); } ;
inst_m1_to_c    : M1 ARROW C                { emit (00510); }
inst_c_exch_m2  : C EXCHANGE M2             { emit (00610); }
		| M2 EXCHANGE C             { emit (00610); } ;
inst_m2_to_c    : M2 ARROW C                { emit (00710); } ;
inst_c_to_stack : C ARROW STACK             { emit (01310); } ;
inst_stack_to_a : STACK ARROW A             { emit (01010); } ;
inst_y_to_a	: Y ARROW A                 { emit (01210); } ;
inst_down_rot   : DOWN ROTATE               { emit (01110); } ;
inst_f_to_a	: F ARROW A FIELDSPEC 	    { $4 = range ($4, 3, 3);
					      emit (01610); } ;
inst_f_exch_a	: F EXCHANGE A FIELDSPEC    { $4 = range ($4, 3, 3);
					      emit (01610); }
		| A FIELDSPEC EXCHANGE F    { $2 = range ($2, 3, 3);
					      emit (01610); }
inst_clr_reg    : CLEAR REGISTERS           { emit (00010); } ;

inst_sel_rom    : SELECT ROM expr           { $3 = range ($3, 0, 15);
                                              emit (($3 << 6) | 00040);
					      target (dsg, $3, (pc + 1) & 0377);
					      dsr = rom;
					      dsg = group;
					      flag_char = '*'; } ;

inst_del_rom    : DELAYED SELECT ROM expr   { $4 = range ($4, 0, 15); 
                                              emit (($4 << 7) | 00064);
					      dsr = $4;
					      flag_char = '$'; } ;

inst_key_to_rom	: KEYS ARROW ROM ADDRESS    { emit (00020); } ;

inst_a_to_rom	: A ARROW ROM ADDRESS       { emit (00220); } ;

inst_decimal	: DECIMAL		    { emit (01410); } ;
inst_binary	: BINARY		    { emit (01410); } ;

inst_return	: RETURN                    { emit (01020); } ;

inst_noop       : NOP			    { emit (00000); } ;

inst_woodstock	: HI IAM WOODSTOCK	    { emit (01760); } ;

%%

int ptr_load_map [14] =
  { 014, 010, 005, 011, 001, 016, 013, 002, 003, 015, 006, 004, 007, 012 };

extern int ptr_test_map [14] =
  { 013, 005, 003, 007, 000, 012, 006, 016, 001, 004, 015, 014, 002, 011 };
