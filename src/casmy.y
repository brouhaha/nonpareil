/*
$Id$
Copyright 1995, 2003, 2004, 2005 Eric L. Smith <eric@brouhaha.com>

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

%name-prefix="casm_"

%{
#include <stdbool.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "asm.h"

void casm_error (char *s);
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

%token A B C M P

%token ADDRESS
%token ADVANCE
%token AND
%token BUFFER
%token CARRY
%token CLEAR
%token CONSTANT
%token DATA
%token DELAYED
%token DELETE
%token DISPLAY
%token DOWN
%token EXCHANGE
%token FOR
%token GO
%token GROUP
%token IF
%token INSERT
%token JSB
%token KEYS
%token LABEL
%token LEFT
%token LOAD
%token MARK
%token MEMORY
%token NO
%token OFF
%token OPERATION
%token POINTER
%token REGISTERS
%token RETURN
%token RIGHT
%token ROM
%token ROTATE
%token SEARCH
%token SELECT
%token SHIFT
%token STACK
%token STATUS
%token SYMTAB
%token THEN
%token TO
%token TOGGLE

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
                          else
                            {
			      symtab_t *table;
			      if (local_label_flag && ($1 [0] != '$'))
				table = symtab [group][rom];
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
		;

ps_rom		: '.' ROM expr { $3 = range ($3, 0, MAXGROUP * MAXROM - 1);
				 group = dsg = ($3 >> 3);
				 rom = dsr = ($3 & 7); 
				 pc = 0;
				 last_instruction_type = OTHER_INST;
				 local_label_flag = true;
			         printf (" %d", $3); }
		;

ps_symtab	: '.' SYMTAB { symtab_flag = 1; }
		;

instruction	: jsb_inst
	        | goto_inst
	        | arith_inst
		| status_inst
		| flag_inst
	        | pointer_inst
		| misc_inst
	        ;

jsb_inst        : JSB expr { emit (($2 << 2) | 0x001); 
			     target (dsg, dsr, $2);
			     dsg = group;
			     dsr = rom; }
                ;

goto_inst	: goto_form { emit (($1 << 2) | 0x003);
			      target (dsg, dsr, $1);
			      dsg = group;
			      dsr = rom; }
		;

goto_form       : GO TO expr      { $$ = $3; 
				    if (last_instruction_type == ARITH_INST)
				      asm_warning ("unconditional goto shouldn't follow  arithmetic instruction\n"); 
				    else if (last_instruction_type == TEST_INST)
				      asm_warning ("unconditional goto shouldn't follow test instruction\n"); }
                | THEN GO TO expr { $$ = $4; 
				    if (last_instruction_type != TEST_INST)
				      asm_warning ("'then go to' should only follow 'if' instructions\n"); }
                | IF NO CARRY GO TO expr { $$ = $6; 
				    if (last_instruction_type != ARITH_INST)
				      asm_warning ("'if no carry go to' should only follow arithmetic instructions\n"); }
		;

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

inst_test_b_0   : IF B FIELDSPEC '=' expr { $5 = range ($5, 0, 0);
                                            emit_test (($3 << 2) | 0x002); } ;
inst_test_c_0   : IF C FIELDSPEC '=' expr { $5 = range ($5, 0, 0); 
                                            emit_test (($3 << 2) | 0x1a2); } ;

inst_test_a_1   : IF A FIELDSPEC GE expr { $5 = range ($5, 1, 1);
                                           emit_test (($3 << 2) | 0x262); } ;
inst_test_c_1   : IF C FIELDSPEC GE expr { $5 = range ($5, 1, 1);
                                           emit_test (($3 << 2) | 0x062); } ;

inst_test_a_c   : IF A GE C FIELDSPEC { emit_test (($5 << 2) | 0x042); } ;
inst_test_a_b   : IF A GE B FIELDSPEC { emit_test (($5 << 2) | 0x202); } ;

inst_0_to_a     : expr ARROW A FIELDSPEC { $1 = range ($1, 0, 0); 
                                           emit (($4 << 2) | 0x2e2); } ;
inst_0_to_b     : expr ARROW B FIELDSPEC { $1 = range ($1, 0, 0); 
                                           emit (($4 << 2) | 0x022); } ;
inst_0_to_c     : expr ARROW C FIELDSPEC { $1 = range ($1, 0, 0);
                                           emit (($4 << 2) | 0x0c2); } ;

inst_nines_comp : expr '-' C '-' expr ARROW C FIELDSPEC { $1 = range ($1, 0, 0);
                                                          $5 = range ($5, 1, 1); 
                                                 emit_arith (($8 << 2) | 0x0e2); } ;
inst_tens_comp  : expr '-' C ARROW C FIELDSPEC { $1 = range ($1, 0, 0);
                                                 emit_arith (($6 << 2) | 0x0a2); } ;

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

inst_a_min_b_a  : A '-' B ARROW A FIELDSPEC { emit_arith (($6 << 2) | 0x302); } ;
inst_a_min_c_a  : A '-' C ARROW A FIELDSPEC { emit_arith (($6 << 2) | 0x342); } ;
inst_a_min_c_c  : A '-' C ARROW C FIELDSPEC { emit_arith (($6 << 2) | 0x142); } ;
inst_a_plus_b_a : A '+' B ARROW A FIELDSPEC { emit_arith (($6 << 2) | 0x382); } 
                | B '+' A ARROW A FIELDSPEC { emit_arith (($6 << 2) | 0x382); } ;
inst_a_plus_c_a : A '+' C ARROW A FIELDSPEC { emit_arith (($6 << 2) | 0x3c2); } 
                | C '+' A ARROW A FIELDSPEC { emit_arith (($6 << 2) | 0x3c2); } ;
inst_a_plus_c_c : A '+' C ARROW C FIELDSPEC { emit_arith (($6 << 2) | 0x1c2); } 
                | C '+' A ARROW C FIELDSPEC { emit_arith (($6 << 2) | 0x1c2); } ;
inst_c_plus_c_c : C '+' C ARROW C FIELDSPEC { emit_arith (($6 << 2) | 0x2a2); } ;

inst_a_minus_1  : A '-' expr ARROW A FIELDSPEC { $3 = range ($3, 1, 1); 
                                                 emit_arith (($6 << 2) | 0x362); } ;
inst_a_plus_1   : A '+' expr ARROW A FIELDSPEC { $3 = range ($3, 1, 1);  
                                                 emit_arith (($6 << 2) | 0x3e2); } ;
inst_c_minus_1  : C '-' expr ARROW C FIELDSPEC { $3 = range ($3, 1, 1);  
                                                 emit_arith (($6 << 2) | 0x162); } ;
inst_c_plus_1   : C '+' expr ARROW C FIELDSPEC { $3 = range ($3, 1, 1);  
                                                 emit_arith (($6 << 2) | 0x1e2); } ;

status_inst     : inst_set_stat
                | inst_clr_stat
                | inst_tst_stat_e
                | inst_tst_stat_n
                ;

inst_set_stat   : expr ARROW STATBIT { $1 = range ($1, 0, 1);
                                  emit (($3 << 6) | ($1 ? 0x004 : 0x024)); } ;
inst_clr_stat   : CLEAR STATUS { emit (0x034); } ;
inst_tst_stat_n : IF STATBIT '#' expr { $4 = range ($4, 1, 1);
                                        emit_test (($2 << 6) | 0x014); } ;
inst_tst_stat_e : IF STATBIT '=' expr { $4 = range ($4, 0, 0);
                                        emit_test (($2 << 6) | 0x014); } ;

flag_inst	: inst_set_flag ;

inst_set_flag	: expr ARROW FLAGBIT { $1 = range ($1, 0, 1);
                                  emit (($3 << 7) | ($1 ? 0x020 : 0x060)); } ;

pointer_inst    : inst_load_p
                | inst_test_p
                | inst_incr_p
                | inst_decr_p
                ;

inst_load_p     : expr ARROW P       { $1 = range ($1, 0, 15);
                                       emit (($1 << 6) | 0x00c); } ;
inst_test_p     : IF P '#' expr      { $4 = range ($4, 0, 15);
                                       emit_test (($4 << 6) | 0x02c); } ;
inst_incr_p     : P '+' expr ARROW P { $3 = range ($3, 1, 1); emit (0x03c); } ;
inst_decr_p     : P '-' expr ARROW P { $3 = range ($3, 1, 1); emit (0x01c); } ;

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
		| inst_c_to_addr
		| inst_c_to_data
		| inst_data_to_c
		| inst_key_to_rom
		| inst_return
		| inst_ptr_adv
		| inst_mem_delete
		| inst_rom_to_buf
		| inst_buf_to_rom
		| inst_mem_insert
		| inst_mark_srch
		| inst_srch_label
                ;

inst_load_const : LOAD CONSTANT expr        { $3 = range ($3, 0, 9); 
                                              emit (($3 << 6) | 0x018); } ;
inst_disp_off   : DISPLAY OFF               { emit (0x228); } ;
inst_disp_tog   : DISPLAY TOGGLE            { emit (0x028); } ;
inst_c_exch_m   : C EXCHANGE M              { emit (0x0a8); } ;
inst_m_to_c     : M ARROW C                 { emit (0x2a8); } ;
inst_c_to_stack : C ARROW STACK             { emit (0x128); } ;
inst_stack_to_a : STACK ARROW A             { emit (0x1a8); } ;
inst_down_rot   : DOWN ROTATE               { emit (0x328); } ;
inst_clr_reg    : CLEAR REGISTERS           { emit (0x3a8); } ;

inst_sel_rom    : SELECT ROM expr           { $3 = range ($3, 0, 7);
                                              emit (($3 << 7) | 0x010);
					      target (dsg, $3, (pc + 1) & 0xff);
					      dsr = rom;
					      dsg = group;
					      flag_char = '*'; } ;

inst_del_rom    : DELAYED SELECT ROM expr   { $4 = range ($4, 0, 7); 
                                              emit (($4 << 7) | 0x074);
					      dsr = $4;
					      flag_char = '$'; } ;

inst_del_grp    : DELAYED SELECT GROUP expr { $4 = range ($4, 0, 1); 
                                              emit (($4 << 7) | 0x234);
					      dsg = $4;
					      flag_char = '#'; } ;

inst_c_to_addr	: C ARROW DATA ADDRESS      { emit (0x270); } ;
inst_c_to_data	: C ARROW DATA              { emit (0x2f0); } ;
inst_data_to_c	: DATA ARROW C              { emit (0x2f8); } ;
inst_key_to_rom	: KEYS ARROW ROM ADDRESS    { emit (0x0d0); } ;
inst_return	: RETURN                    { emit (0x030); } ;
inst_buf_to_rom	: BUFFER ARROW ROM ADDRESS  { emit (0x040); } ;

inst_noop       : NO OPERATION              { emit (0x000); } ;
inst_mem_insert	: MEMORY INSERT             { emit (0x080); } ;
inst_mark_srch	: MARK AND SEARCH           { emit (0x100); } ;
inst_mem_delete : MEMORY DELETE             { emit (0x180); } ;
inst_rom_to_buf	: ROM ADDRESS ARROW BUFFER  { emit (0x200); } ;
inst_srch_label	: SEARCH FOR LABEL          { emit (0x280); } ;
inst_ptr_adv	: POINTER ADVANCE           { emit (0x300); } ;

%%

void casm_error (char *s)
{
  error ("%s\n", s);
}
