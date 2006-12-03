/*
$Id$
Copyright 1995, 2004, 2005, 2006 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

%name-prefix="wasm_"

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "asm.h"

int ptr_load_map [14];
int ptr_test_map [14];

void wasm_error (char *s);
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
%token LARROW

%token A B C F M1 M2 P S Y

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
%token KEY
%token KEYS
%token LEFT
%token LEGAL
%token LOAD
%token NC
%token NOP
%token OFF
%token PIK
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

%type <integer> stat_bit
%type <integer> stat_bit_name

%%

line		:	label
		|	label operation
		|	operation
		|
		;

label:		IDENT ':'	{ do_label ($1); }
		;

operation	:	instruction
		|	pseudo_op
		|	error
		;

expr		: INTEGER { $$ = $1; }
		| IDENT { if (pass == 1)
                            $$ = 0;
                          else
                            {
			      symtab_t *table;
			      if (local_label_flag && ($1 [0] != '$'))
				table = symtab [local_label_current_rom];
			      else
				table = global_symtab;
			      if (! lookup_symbol (table, $1, &$$))
				{
				  error ("undefined symbol '%s'\n", $1);
				  $$ = 0;
				}
			    }
			}
		;

pseudo_op	: ps_rom
		| ps_symtab
		| ps_legal
		;

ps_rom		: '.' ROM expr { $3 = range ($3, 0, MAXROM - 1);
				 if (pc != ($3 << 8))
				   {
				     fprintf (stderr, ".rom pseudo-op skipping locations\n");
				     fprintf (stderr, "current pc %05o\n", pc);
				     fprintf (stderr, "arg: %o\n", $3);
				     last_instruction_type = OTHER_INST;
				   }
				 pc = ($3 << 8);
				 local_label_flag = true;
				 local_label_current_rom = $3;
			         printf (" %d", $3); }
		;

ps_symtab	: '.' SYMTAB { symtab_pseudoop_flag = true; }
	;

ps_legal	: '.' LEGAL { legal_flag = true; }
		;

instruction	: jsb_inst
	        | goto_inst
		| then_inst
	        | arith_inst
		| status_inst
	        | pointer_inst
		| ram_inst
		| misc_inst
		| pik_inst
	        ;

jsb_inst        : JSB expr { if ((pass == 2) && ($2 >> 8) != get_next_pc () >> 8)
		               asm_warning ("target in incorrect rom (incorrect or missing delayed select?)\n");
		             emit ((001 << 12) | (($2 & 0377) << 2) | 00001); 
			     target ($2); }
                ;

goto_inst	: goto_form { emit ((013 << 12) | (($1 & 0377) << 2) | 00003);
			      target ($1); }
		;

goto_form       :  GO TO expr { $$ = $3; 
				if ((last_instruction_type == ARITH_INST) &&
				    ! legal_flag)
				  asm_warning ("unconditional goto shouldn't follow  arithmetic instruction\n"); 
				if ((pass == 2) && ($3 >> 8) != get_next_pc () >> 8)
				  asm_warning ("target in incorrect rom (incorrect or missing delayed select?)\n");
				legal_flag = false;
                              }
                | IF NC GO TO expr { $$ = $5;
				     if (last_instruction_type != ARITH_INST)
				       asm_warning ("'if no carry go to' should only follow arithmetic instructions\n");
				     if ((pass == 2) && ($5 >> 8) != get_next_pc () >> 8)
				       asm_warning ("target in incorrect rom (incorrect or missing delayed select?)\n");
		                   }
		;

then_inst	: THEN GO TO expr { if (last_instruction_type != TEST_INST)
				      asm_warning ("'then go to' should only follow 'if' instructions\n");
		                    if ((pass == 2) && ($4 >> 10) != get_next_pc () >> 10)
				      asm_warning ("target in incorrect rom (incorrect or missing delayed select?)\n");
				    emit ((014 << 12) | ($4 & 01777));
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
		| inst_test_b_eq_0
                | inst_test_c_eq_0
                | inst_test_a_ge_c
                | inst_test_a_ge_b
                | inst_test_a_ne_0
                | inst_test_c_ne_0
                | inst_a_min_c_a
                | inst_shr_a
                | inst_shr_b
                | inst_shr_c
                ;

inst_test_b_eq_0   : IF B FIELDSPEC '=' expr { $5 = range ($5, 0, 0);
                                               emit_test (($3 << 2) | 01302); }
		   | IF expr '=' B FIELDSPEC { $2 = range ($2, 0, 0);
                                               emit_test (($5 << 2) | 01302); } ;
inst_test_c_eq_0   : IF C FIELDSPEC '=' expr { $5 = range ($5, 0, 0); 
                                               emit_test (($3 << 2) | 01342); }
		   | IF expr '=' C FIELDSPEC { $2 = range ($2, 0, 0);
                                               emit_test (($5 << 2) | 01342); } ;

inst_test_a_ne_0   : IF A FIELDSPEC '#' expr { $5 = range ($5, 0, 0);
                                               emit_test (($3 << 2) | 01502); }
		   | IF expr '#' A FIELDSPEC { $2 = range ($2, 0, 0);
                                               emit_test (($5 << 2) | 01502); } ;
inst_test_c_ne_0   : IF C FIELDSPEC '#' expr { $5 = range ($5, 0, 0);
                                               emit_test (($3 << 2) | 01542); }
		   | IF expr '#' C FIELDSPEC { $2 = range ($2, 0, 0);
                                               emit_test (($5 << 2) | 01542); } ;

inst_test_a_ge_c   : IF A GE C FIELDSPEC { emit_test (($5 << 2) | 01402); } ;
inst_test_a_ge_b   : IF A GE B FIELDSPEC { emit_test (($5 << 2) | 01442); } ;

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

stat_bit_name	: IDENT { $$ = 0; }
		| KEY { $$ = 0; }
		| F { $$ = 0; };

stat_bit	: S stat_bit_name expr { $$ = range ($3, 0, 15); }
		| S expr { $$ = range ($2, 0, 15); };

inst_set_stat   : expr ARROW stat_bit { $1 = range ($1, 0, 1);
                                  emit (($3 << 6) | ($1 ? 00004 : 00014)); } ;
inst_clr_stat   : CLEAR STATUS { emit (00110); } ;

inst_tst_stat_e : IF stat_bit '=' expr { $4 = range ($4, 0, 1);
                                        emit_test (($2 << 6) | ($4 ? 00024 : 00034)); }
		| IF expr '=' stat_bit { $2 = range ($2, 0, 1);
                                        emit_test (($4 << 6) | ($2 ? 00024 : 00034)); } ;

inst_tst_stat_n : IF stat_bit '#' expr { $4 = range ($4, 0, 1);
                                        emit_test (($2 << 6) | ($4 ? 00034 : 00024)); }
		| IF expr '#' stat_bit { $2 = range ($2, 0, 1);
                                        emit_test (($4 << 6) | ($2 ? 00034 : 00024)); } ;

pointer_inst    : inst_load_p
                | inst_test_eq_p
                | inst_test_ne_p
                | inst_incr_p
                | inst_decr_p
                ;

inst_load_p     : expr ARROW P       { $1 = range ($1, 0, 13);
                                       emit ((ptr_load_map [$1] << 6) | 00074); }
		| P LARROW expr      { $3 = range ($3, 0, 13);
                                       emit ((ptr_load_map [$3] << 6) | 00074); } ;

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
		| inst_clear_data_regs
		;

inst_c_to_addr	: C ARROW DATA ADDRESS      { emit (01160); } ;
inst_c_to_data	: C ARROW DATA              { emit (01360); } ;
inst_data_to_c	: DATA ARROW C              { emit (00070); } ;
inst_c_to_reg	: C ARROW REGISTER expr     { $4 = range ($4, 0, 15);
					      emit (($4 << 6) | 00050); } ;
inst_reg_to_c	: REGISTER ARROW C expr     { $4 = range ($4, 1, 15);
					      emit (($4 << 6) | 00070); } ;
inst_clear_data_regs: CLEAR DATA REGISTERS  { emit (01260); } ;

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
		| inst_key_to_a
                | inst_reset_twf
		| inst_rotate_left_a
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
inst_m1_to_c    : M1 ARROW C                { emit (00510); } ;
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
					      emit (01710); }
		| A FIELDSPEC EXCHANGE F    { $2 = range ($2, 3, 3);
					      emit (01710); } ;
inst_clr_reg    : CLEAR REGISTERS           { emit (00010); } ;

inst_sel_rom    : SELECT ROM expr           { addr_t tgt = ($3 << 8) + ((pc + 1) & 0377);
					      $3 = range ($3, 0, 15);
                                              emit (($3 << 6) | 00040);
					      target (tgt);
					      flag_char = '*'; }
		| SELECT ROM expr '(' expr ')'
					    { addr_t tgt = ($3 << 8) + ((pc + 1) & 0377);
					      $3 = range ($3, 0, 15);
					      emit (($3 << 6) | 00040);
					      target (tgt);
					      if ((pass == 2) && ($5 != tgt))
						{
						  error ("'select rom' target value incorrect - requested %05o, actual %05o\n", $5, tgt);
						}
					      flag_char = '*'; }
		;

inst_del_rom    : DELAYED ROM expr          { $3 = range ($3, 0, 15); 
                                              emit (($3 << 6) | 00064);
					      delayed_select (017 << 8, $3 << 8);
					      flag_char = '$'; } ;

inst_key_to_rom	: KEYS ARROW ROM ADDRESS    { emit (00020); } ;

inst_key_to_a	: KEYS ARROW A              { emit (00120); } ;

inst_a_to_rom	: A ARROW ROM ADDRESS       { emit (00220); } ;

inst_reset_twf  : RESET TWF                 { emit (00320); } ;

inst_decimal	: DECIMAL		    { emit (01410); } ;
inst_binary	: BINARY		    { emit (00420); } ;

inst_rotate_left_a : ROTATE LEFT A          { emit (00520); } ;

inst_return	: RETURN                    { emit (01020); } ;

inst_noop       : NOP			    { emit (00000); } ;

inst_woodstock	: HI IAM WOODSTOCK	    { emit (01760); } ;

pik_inst        : pik_key_inst ;

pik_key_inst	: PIK KEY '?'               { emit (01320); } ;

%%

int ptr_load_map [14] =
  { 014, 010, 005, 011, 001, 016, 013, 002, 003, 015, 006, 004, 007, 012 };

int ptr_test_map [14] =
  { 013, 005, 003, 007, 000, 012, 006, 016, 001, 004, 015, 014, 002, 011 };

void wasm_error (char *s)
{
  error ("%s\n", s);
}
