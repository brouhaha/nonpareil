// Brute-force CRC polynomial finder for HP Spice series calculator ROM images
// $Id$
// Copyright 2004 Eric Smith <eric@brouhaha.com>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#undef DALLAS_SEMI_TEST

#ifdef DALLAS_SEMI_TEST
  #define INIT_ONES 1
  #define INVERT_RESULT 1
#else
  #define INIT_ONES 1
  #define INVERT_RESULT 1
#endif

uint32_t crc_block (uint32_t *data, int width, int count,
		    int order, uint32_t poly)
{
  uint32_t crc;
  uint32_t d;
  int b;
  int i;

  uint32_t crc_mask = (1 << order) - 1;

#if INIT_ONES
  crc = crc_mask;
#else
  crc = 0;
#endif

  while (count--)
    {
      d = *(data++);
      for (i = 0; i < width; i++)
	{
	  b = crc & 1;
	  crc >>= 1;
	  if (b ^ (d & 1))
	    crc ^= poly;
	  d >>= 1;
#if 0
	  printf ("%02x\n", crc);
#endif
	}
#if 0
      printf ("\n");
#endif
    }

#if INVERT_RESULT
  crc = ~crc;
#endif

  crc &= crc_mask;

  return (crc);
}


#ifdef DALLAS_SEMI_TEST
int width = 8;
int count = 7;

int order = 8;
uint32_t poly = 0x8c;

uint32_t data1 [7] = { 0x02, 0x1c, 0xb8, 0x01, 0x00, 0x00, 0x00 };

int main (int argc, char *argv[])
{
  uint32_t crc;

  crc = crc_block (data1, width, count, order, poly);

  printf ("%x\n", crc);
  exit (0);
}
#endif

#ifndef DALLAS_SEMI_TEST
int width = 10;
int count = 1024;

typedef uint32_t rom_word_t;

#define MAX_ROM 4096
#define MAX_BANK 2

bool breakpoint [MAX_BANK * MAX_ROM];
rom_word_t ucode [MAX_BANK * MAX_ROM];


void munge_banks (void)
{
  int i;
  bool swap = 0;
  rom_word_t temp;

  for (i = 0; i < MAX_ROM; i++)
    {
      if (ucode [i] == 01060)
	swap = ! swap;
      if (swap)
	{
	  temp = ucode [i];
	  ucode [i] = ucode [i + MAX_ROM];
	  ucode [i + MAX_ROM] = temp;
	}
    }
}


void trim_trailing_whitespace (char *s)
{
  int i;
  char c;

  i = strlen (s);
  while (--i >= 0)
    {
      c = s [i];
      if ((c == '\n') || (c == '\r') || (c == ' ') || (c == '\t'))
	s [i] = '\0';
      else
	break;
    }
}


static bool parse_octal (char *oct, int digits, int *val)
{
  *val = 0;

  while (digits--)
    {
      if (((*oct) < '0') || ((*oct) > '7'))
	return (false);
      (*val) = ((*val) << 3) + ((*(oct++)) - '0');
    }
  return (true);
}


static bool woodstock_parse_object_line (char *buf, int *bank, int *addr,
					 rom_word_t *opcode)
{
  bool has_bank;
  int b = 0;
  int a, o;

  if (buf [0] == '#')  /* comment? */
    return (false);

  if ((strlen (buf) < 9) || (strlen (buf) > 10))
    return (false);

  if (buf [4] == ':')
    has_bank = false;
  else if (buf [5] == ':')
    has_bank = true;
  else
    {
      fprintf (stderr, "invalid object file format\n");
      return (false);
    }

  if (has_bank && ! parse_octal (& buf [0], 1, & b))
    {
      fprintf (stderr, "invalid bank in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_octal (& buf [has_bank ? 1 : 0], 4, & a))
    {
      fprintf (stderr, "invalid address in object line '%s'\n", buf);
      return (false);
    }

  if (! parse_octal (& buf [has_bank ? 6 : 5], 4, & o))
    {
      fprintf (stderr, "invalid opcode in object line '%s'\n", buf);
      return (false);
    }

  *bank = b;
  *addr = a;
  *opcode = o;
  return (true);
}


int word_count = 0;

bool sim_read_object_file (char *fn)
{
  FILE *f;
  int bank, addr, i;
  rom_word_t opcode;
  char buf [80];

  f = fopen (fn, "r");
  if (! f)
    {
      fprintf (stderr, "error opening object file\n");
      return (false);
    }

  while (fgets (buf, sizeof (buf), f))
    {
      trim_trailing_whitespace (buf);
      if (! buf [0])
	continue;
      if (woodstock_parse_object_line (buf, & bank, & addr, & opcode))
	{
	  i = bank * MAX_ROM + addr;
#if 0
	  printf ("i %5o bank %o addr %4o opcode %4o\n", i, bank, addr, opcode);
#endif
	  if (! breakpoint [i])
	    {
	      fprintf (stderr, "duplicate object code for bank %d address %o\n",
		       bank, addr);
	      fprintf (stderr, "dup:  %s\n", buf);
	    }
	  ucode      [i] = opcode;
	  breakpoint [i] = 0;
	  word_count++;
	}
    }

#if 1
  fprintf (stderr, "read %d words from '%s'\n", word_count, fn);
#endif

  if (word_count == MAX_BANK * MAX_ROM)
    {
      munge_banks ();
    }

  return (true);
}


int main (int argc, char *argv[])
{
  int order;
  uint32_t poly;
  int i;

  uint32_t crc1, crc2, crc3, crc4;

  if (argc != 2)
    {
      fprintf (stderr, "usage:\n");
      fprintf (stderr, "%s romfile:\n", argv [0]);
    }

  for (i = 0; i < MAX_BANK * MAX_ROM; i++)
    breakpoint [i] = true;

  if (! sim_read_object_file (argv [1]))
    {
      fprintf (stderr, "error reading object file\n");
      exit (2);
    }

  for (order = 3; order <= 16; order++)
    {
      printf ("order %d\n", order);
      fflush (stdout);
      for (poly = (1 << (order - 1)); poly < (1 << order); poly += 1)
	{
#if 0
	  printf ("  poly %x\n", poly);
#endif
#if 1
	  crc1 = crc_block (& ucode [   0], width, 1024, order, poly);
	  crc2 = crc_block (& ucode [1024], width, 1024, order, poly);
	  if (crc1 == crc2)
	    {
	      printf ("  match blocks 0 & 1 for order %d poly 0x%x, crc=0x%x\n", order, poly, crc1);
	      crc3 = crc_block (& ucode [2048], width, 1024, order, poly);
	      if (crc1 == crc3)
		{
		  printf ("  match blocks 0, 1 & 2 for order %d poly 0x%x, crc=0x%x\n", order, poly, crc1);
		  if (word_count > 3072)
		    {
		      crc4 = crc_block (& ucode [3072], width, 1024, order, poly);
		      if (crc1 == crc4)
			{
			  printf ("  match blocks 0, 1, 2 & 3 for order %d poly 0x%x, crc=0x%x\n", order, poly, crc1);
			}
		    }
		}
	    }
#endif
	}
    }
  exit (0);
}
#endif
