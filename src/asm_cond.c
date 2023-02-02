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

#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "symtab.h"
#include "asm.h"
#include "asm_cond.h"

#define MAX_COND_NEST_LEVEL 16


typedef struct
{
  unsigned state:          1;
  unsigned true_case_seen: 1;
  unsigned else_seen:      1;
} cond_info_t;


static int cond_nest_level;

static cond_info_t cond[MAX_COND_NEST_LEVEL];


void cond_init (void)
{
  cond_nest_level = 0;
  memset(cond, 0, sizeof(cond));
  cond[cond_nest_level].state = true;
}

bool get_cond_state (void)
{
  return cond[cond_nest_level].state;
}

int get_cond_nest_level(void)
{
  return cond_nest_level;
}

static void cond_set_state(bool new_state)
{
  cond[cond_nest_level].state = new_state;
  cond[cond_nest_level].true_case_seen |= new_state;
}

static void cond_push(bool new_state)
{
  cond_nest_level++;
  memset(&cond[cond_nest_level], 0, sizeof(cond_info_t));
  cond_set_state(new_state);
}

static void cond_pop(void)
{
  cond_nest_level--;  // WARNING: CALLER MUST CHECK level != 0 first
}

void pseudo_if (int val)
{
  if (cond_nest_level >= MAX_COND_NEST_LEVEL)
    {
      error ("conditionals nested too deep");
      return;
    }

  cond_push(val != 0);
}

void pseudo_ifdef (char *s)
{
  symtab_t *table;
  int val;

  if (cond_nest_level >= MAX_COND_NEST_LEVEL)
    {
      error ("conditionals nested too deep");
      return;
    }
  if (local_label_flag && (*s != '$'))
    table = symtab [local_label_current_rom];
  else
    table = global_symtab;

  bool cond_val = lookup_symbol (table, s, & val, get_lineno());

  cond_push(cond_val);
}

void pseudo_ifndef (char *s)
{
  symtab_t *table;
  int val;

  if (cond_nest_level >= MAX_COND_NEST_LEVEL)
    {
      error ("conditionals nested too deep");
      return;
    }
  if (local_label_flag && (*s != '$'))
    table = symtab [local_label_current_rom];
  else
    table = global_symtab;

  bool cond_val = ! lookup_symbol (table, s, & val, get_lineno());

  cond_push(cond_val);
}

void pseudo_else (void)
{
  if (! cond_nest_level)
    {
      error ("else without conditional");
      return;
    }
  if (cond[cond_nest_level].else_seen)
    {
      error ("second else for same conditional");
      return;
    }
  cond_set_state(! cond[cond_nest_level].true_case_seen);
  cond[cond_nest_level].else_seen = true;
}

void pseudo_elseif (int val)
{
  if (! cond_nest_level)
    {
      error ("elseif without conditional");
      return;
    }
  if (cond[cond_nest_level].true_case_seen)
    cond_set_state(false);
  else
    cond_set_state(val);
}

void pseudo_endif (void)
{
  if (! cond_nest_level)
    {
      error ("endif without conditional");
      return;
    }
  cond_pop();
}


