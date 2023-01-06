/*
Copyright 1995-2023 Eric Smith <spacewar@gmail.com>
SPDX-License-Identifier: GPL-3.0-only

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 as
published by the Free Software Foundation.

Note that permission is NOT granted to redistribute and/or modify
this porogram under the terms of any other version, earlier or
later, of the GNU General Public License.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License version 3 for more details.

You should have received a copy of the GNU General Public License
version 3 along with this program (in the file "gpl-3.0.txt"); if not,
see <https://www.gnu.org/licenses/>.
*/

%define api.prefix {nasm_}

%{
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "symtab.h"
#include "arch.h"
#include "asm.h"

const int digit_map[14];

void nasm_error (char *s);
%}

%union {
    int integer;
    char *string;
  }

%token <integer> INTEGER
%token <string> IDENT

%token A B C F G M N P Q S W X

%token AB
%token ABC
%token AC
%token BC
%token BLINK
%token CLR
%token CXISA
%token DATA
%token DEC
%token DISP
%token DW
%token EQU
%token EX
%token EXT
%token GOLONG
%token GOTO
%token GOSUB
%token HEX
%token INC
%token KB
%token KEYS
%token LEGAL
%token LC
%token LDI
%token LLD
%token NC
%token NOP
%token OFF
%token ORG
%token PFAD
%token POP
%token POWOFF
%token PQ
%token PT
%token RAM
%token RCR
%token REG
%token REGS
%token RTN
%token SB
%token SEL
%token SET
%token SL
%token SR
%token ST
%token STK
%token SYMTAB
%token TOGGLE
%token WP
%token XS

%type <integer> factor
%type <integer> term
%type <integer> expr
%type <integer> cond
%type <integer> field_spec

/*
%type <integer> stat_bit
%type <integer> stat_bit_name
*/

%%

line		:	'.' pseudo_op
		|	pseudo_op_special_label
		|	label '.' pseudo_op_label
		|	label
		|	label instruction
		|	instruction
		|
		|	error
		;

label		: IDENT ':'	{ do_label ($1); }
		;

factor		: '(' expr ')'  { $$ = $2; }
		| INTEGER { $$ = $1; }
		| IDENT { symtab_t *table;
			  if (local_label_flag && ($1 [0] != '$'))
			    table = symtab [local_label_current_rom];
			  else
			    table = global_symtab;
			  int value;
			  if (lookup_symbol (table, $1, &value, get_lineno ()))
			    {
			      $$ = value;
			    }
			  else
			    {
			      if (pass == 2)
				error ("undefined symbol '%s'\n", $1);
			      $$ = 0;
			    }
			}
		;

term            : factor          { $$ = $1; }
                | term '*' factor { $$ = $1 * $3; }
                | term '/' factor { $$ = $1 / $3; }
                ;

expr            : term          { $$ = $1; }
                | expr '+' term { $$ = $1 + $3; }
                | expr '-' term { $$ = $1 - $3; }
                ;

pseudo_op	: ps_org
		| ps_symtab
		| ps_legal
		| ps_dw

		;

pseudo_op_label	: ps_dw
		| ps_legal
		;

pseudo_op_special_label	: ps_equ ;

ps_equ		: IDENT '.' EQU expr { $4 = range ($4, 0, 0xffff);
				       define_symbol ($1, $4); };

ps_org		: ORG expr { $2 = range ($2, 0, 0xffff);
			     pc = $2;
			     last_instruction_type = OTHER_INST; };

ps_symtab	: SYMTAB { symtab_pseudoop_flag = true; }
		;

ps_legal	: LEGAL { legal_flag = true; }
		;

dw_item         : expr             { $1 = range_pass2($1, 0, 0x3ff); emit($1); }
                ;

dw_list         : dw_item
                | dw_item ',' dw_list
                ;

ps_dw		: DW dw_list
		;

instruction	      : branch_inst
	              | arith_inst
                      | reg_inst
                      | const_inst
		      | status_inst
	              | pointer_inst
		      | ram_inst
                      | kbd_inst
                      | ext_flag_inst
		      | misc_inst
	              ;

cond                  : '?' C { $$ = 1; }
                      | '?' NC { $$ = 2; }
                      | { $$ = 0; }
                      ;

branch_inst           : goto_inst
                      | golong_inst
                      | gosub_inst
                      | return_inst
                      ;

goto_inst             : cond GOTO expr  { if (($1 == 0) && (last_instruction_type == ARITH_INST))
				            asm_warning ("unconditional goto after instruction that can set carry\n");
                                          else if (($1 != 0) && (last_instruction_type != ARITH_INST) && (! legal_flag))
				            asm_warning ("conditional goto after instruction that cannot set carry\n");
                                          int rel = $3 - pc;
                                          if (pass == 2)
					    {
					      if ((rel < -64) || (rel > 63))
						asm_warning("short goto target out of range\n");
					    }
					  emit(((rel & 0x7f) << 3) + (($1 & 1) << 2) + 3);
					  legal_flag = false;
                                        }
                      ;

golong_inst           : cond GOLONG expr { if (($1 == 0) && (last_instruction_type == ARITH_INST))
				             asm_warning ("unconditional golong after instruction that can set carry\n");
                                           else if (($1 != 0) && (last_instruction_type != ARITH_INST) && (! legal_flag))
				             asm_warning ("conditional golong after instruction that cannot set carry\n");
                                           emit((($3 & 0xff) << 2)+1);
                                           emit((($3 >> 8) << 2) + ($1 & 1) + 2);
                                           legal_flag = false;
                                         }
                      ;

gosub_inst            : cond GOSUB expr  { if (($1 == 0) && (last_instruction_type == ARITH_INST))
				             asm_warning ("unconditional golong after instruction that can set carry\n");
                                           else if (($1 != 0) && (last_instruction_type != ARITH_INST) && (! legal_flag))
				             asm_warning ("conditional golong after instruction that cannot set carry\n");
                                           emit((($3 & 0xff) << 2)+1);
                                           emit((($3 >> 8) << 2) + ($1 & 1));
                                           legal_flag = false;
                                         }
                      ;

return_inst       : cond RTN { switch ($1)
                               {
			       case 0:
				 emit(01740);
				 break;
			       case 1:
				 if (last_instruction_type != ARITH_INST)
				   asm_warning("conditional return after instruction that cannot set carry\n");
				 emit(01540);
				 break;
			       case 2:
				 if (last_instruction_type != ARITH_INST)
				   asm_warning("conditional return after instruction that cannot set carry\n");
				 emit(01640);
			       }
                             }
                  ;

field_spec        : P  { $$ = 0; }
                  | X  { $$ = 1; }
                  | WP { $$ = 2; }
                  | W  { $$ = 3; }
                  | PQ { $$ = 4; }
                  | XS { $$ = 5; }
                  | M  { $$ = 6; }
                  | S  { $$ = 7; }
                  |    { $$ = 3; }
                  ;

arith_inst      : A '=' expr           field_spec { $3 = range($3, 0, 0); emit(($4 << 2) | 00002); }
                | B '=' expr           field_spec { $3 = range($3, 0, 0); emit(($4 << 2) | 00042); }
                | C '=' expr           field_spec { $3 = range($3, 0, 0); emit(($4 << 2) | 00102); }
                | AB EX                field_spec {                       emit(($3 << 2) | 00142); }
                | B '=' A              field_spec {                       emit(($4 << 2) | 00202); }
                | AC EX                field_spec {                       emit(($3 << 2) | 00242); }
                | C '=' B              field_spec {                       emit(($4 << 2) | 00302); }
                | BC EX                field_spec {                       emit(($3 << 2) | 00342); }
                | A '=' C              field_spec {                       emit(($4 << 2) | 00402); }
                | A '=' A '+' B        field_spec {                       emit_arith(($6 << 2) | 00442); }
		| A '=' A '+' C        field_spec {                       emit_arith(($6 << 2) | 00502); }
		| A '=' A '+' expr     field_spec { $5 = range($5, 1, 1); emit_arith(($6 << 2) | 00542); }
		| A '=' A '-' B        field_spec {                       emit_arith(($6 << 2) | 00602); }
		| A '=' A '-' expr     field_spec { $5 = range($5, 1, 1); emit_arith(($6 << 2) | 00642); }
		| A '=' A '-' C        field_spec {                       emit_arith(($6 << 2) | 00702); }
                | C '=' C '+' C        field_spec {                       emit_arith(($6 << 2) | 00742); }
		| C '=' A '+' C        field_spec {                       emit_arith(($6 << 2) | 01002); }
		| C '=' C '+' expr     field_spec { $5 = range($5, 1, 1); emit_arith(($6 << 2) | 01042); }
		| C '=' A '-' C        field_spec {                       emit_arith(($6 << 2) | 01102); }
		| C '=' C '-' expr     field_spec { $5 = range($5, 1, 1); emit_arith(($6 << 2) | 01142); }
		| C '=' '-' C          field_spec {                       emit_arith(($5 << 2) | 01202); }
		| C '=' '-' C '-' expr field_spec { $6 = range($6, 1, 1); emit_arith(($7 << 2) | 01242); }
		| '?' B '#' expr       field_spec { $4 = range($4, 0, 0); emit_arith(($5 << 2) | 01302); }
		| '?' C '#' expr       field_spec { $4 = range($4, 0, 0); emit_arith(($5 << 2) | 01342); }
		| '?' A '<' C          field_spec {                       emit_arith(($5 << 2) | 01402); }
		| '?' A '<' B          field_spec {                       emit_arith(($5 << 2) | 01442); }
		| '?' A '#' expr       field_spec { $4 = range($4, 0, 0); emit_arith(($5 << 2) | 01502); }
		| '?' A '#' C          field_spec {                       emit_arith(($5 << 2) | 01542); }
		| A SR                 field_spec {                       emit(($3 << 2) | 01602); }
		| B SR                 field_spec {                       emit(($3 << 2) | 01642); }
		| C SR                 field_spec {                       emit(($3 << 2) | 01702); }
		| A SL                 field_spec {                       emit(($3 << 2) | 01742); }
                ;

reg_inst        : C '=' G             { emit(00230); }
                | G '=' C             { emit(00130); }
                | C EX G              { emit(00330); }
                | C '=' M             { emit(00630); }
                | M '=' C             { emit(00530); }
                | C EX M              { emit(00730); }
                | C '=' N             { emit(00260); }
                | N '=' C             { emit(00160); }
                | C EX N              { emit(00360); }
                | C '=' STK           { emit(00660); }
                | STK '=' C           { emit(00560); }
                | POP STK             { emit(00040); }
                | CLR ABC             { emit(00640); }
                ;

const_inst      : LDI expr            { $2 = range($2, 0, 0x3ff); emit(00460); emit($2); }
                | LC expr             { $2 = range($2, 0, 0xf);   emit(00020 + ($2 << 6)); }
                ;

status_inst     : S '=' expr expr     { $3 = range($3, 0, 1); $4 = range($4, 0, 13); emit(00000 + ($3 ? 00010 : 00004) + (digit_map[$4] << 6)); }
                | '?' S '=' expr expr { $4 = range($4, 0, 0); $5 = range($5, 0, 13); emit_arith(00014 + (digit_map[$5] << 6)); }
                | CLR ST              { emit(01704); }
		| C EX ST             { emit(01730); }
		| C '=' ST            { emit(01630); }
		| ST '=' C            { emit(01530); }
                ;

pointer_inst    : SEL P               { emit(00240); }
		| SEL Q               { emit(00340); }
		| INC PT              { emit(01734); }
		| DEC PT              { emit(01724); }
                | PT '=' expr         { emit(00034 + (digit_map[$3] << 6)); }
                | '?' PT '=' expr     { emit_arith(00024 + (digit_map[$4] << 6)); }
		| '?' P '=' Q         { emit_arith(00440); }
                ;

ram_inst	: SEL RAM             { emit(01160); }
		| SEL PFAD            { emit(01760); }
		| DATA '=' C          { emit(01360); }
                | C '=' DATA          { emit(00070); }
                | REG '=' C expr      { $4 = range($4, 0, 15); emit(00050 + ($4 << 6)); }
                | C '=' REG expr      { $4 = range($4, 1, 15); emit(00070 + ($4 << 6)); }
                | CLR DATA REG        { emit(01260); }
		;

kbd_inst        : CLR KB              { emit(01710); }
                | '?' KB              { emit_arith(01714); }
                | C '=' KEYS          { emit(01040); }
                ;

ext_flag_inst   : '?' EXT expr        { $3 = range($3, 0, 13); emit_arith(00054 + (digit_map[$3] << 6)); }
                | F EX SB             { emit(01330); }
                | SB '=' F            { emit(01230); }
                | F '=' SB            { emit(01130); }
                ;

misc_inst       : NOP		      { emit(00000); }
                | SET HEX             { emit(01140); }
                | SET DEC             { emit(01240); }
                | C '=' C '|' A       { emit(01560); }
                | C '=' C '&' A       { emit(01660); }
                | RCR expr            { $2 = range($2, 0, 13); emit(00074 + (digit_map[$2] << 6)); }
                | CXISA               { emit(01460); }
                | POWOFF              { emit(00140); }
                | '?' LLD             { emit_arith(00540); }
                | DISP OFF            { emit(01340); }
                | DISP TOGGLE         { emit(01440); }
                | DISP BLINK          { emit(00060); }

%%

const int digit_map[14] =
  {
    [ 0] = 016,
    [ 1] = 014,
    [ 2] = 010,
    [ 3] = 000,
    [ 4] = 001,
    [ 5] = 002,
    [ 6] = 005,
    [ 7] = 012,
    [ 8] = 004,
    [ 9] = 011,
    [10] = 003,
    [11] = 006,
    [12] = 015,
    [13] = 013
  };

void nasm_error (char *s)
{
  error ("%s\n", s);
}
