/*
$Id$
Copyright 2005 Eric L. Smith <eric@brouhaha.com>

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


#define unused __attribute__((unused))

#define SSIZE 14
#define WSIZE 14
#define MAX_STACK 4
#define MAX_RAM 1024

#define LCD_PERIPH_ADDR 0xfd

typedef struct
{
  uint64_t a;
  uint64_t b;
  uint64_t c;
  uint64_t ann;
  bool enable;
} lcd_regs_t;

typedef struct
{
  uint64_t a;
  uint64_t b;
  uint64_t c;
  uint64_t m;
  uint64_t n;
  uint64_t g;  // 8 bit
  uint64_t p;  // 4 bit
  uint64_t q;  // 4 bit
  uint64_t pc;  // 16 bit
  uint64_t stack [MAX_STACK];  // 16 bit
  uint64_t status;  // 14 bit
  bool awake;
  bool carry;
  bool decimal;
  bool q_selected;
  lcd_regs_t lcd;
} regs_t;

extern regs_t regs;

extern bool ram_used [MAX_RAM];
extern uint64_t ram [MAX_RAM];


void state_read_xml (char *fn);
void state_write_xml (char *fn);

void state_read_nsim (char *fn);
void state_write_nsim (char *fn);

