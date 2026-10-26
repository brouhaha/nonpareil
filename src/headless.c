/*
Copyright 2026 Warren Young <https://tangentsoft.com/rpn>

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

----

Headless mode for HP-41C/CV/CX: Load MOD1 plug-ins, type faceplate
keys, print or check the coconut LCD.  This replaces the GUI when
flags like --keys are given to script a run.
*/

#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include "util.h"
#include "platform.h"
#include "arch.h"
#include "display.h"  /* proc.h needs segment_bitmap_t */
#include "keyboard.h"
#include "chip.h"
#include "calcdef.h"
#include "proc.h"
#include "headless.h"

#define HEADLESS_LCD_DIGITS 12

/* Key-down length in simulated microseconds.  35 ms of wall clock at the
   old 3x rate is the click the 41 firmware accepts, including +, ÷, and
   1/X.  Those instructions run back to back; words_per_usec stays at the
   hardware rate. */
#define KEY_HOLD_US          (35 * 3 * 1000)
#define RUN_CHUNK            2000
#define DEFAULT_TIMEOUT_S    60
#define MAX_MODS             16
#define MAX_KEY_SEQ          512
#define LCD_BUF              64

#define SEG_CHAR_MASK   ((1ULL << 14) - 1)  /* segments a–n */


extern char *default_path;


typedef struct
{
  const char *name;
  int user_keycode;   /* row/col id from .ncd <keyboard> */
  bool gold;          /* true → press SHIFT then this key */
} key_name_t;


/* Primary faceplate names and gold legends. Case is ignored at lookup. */
static const key_name_t key_names [] =
{
  /* row 0 */
  { "ON",     1,  false },
  { "USER",   2,  false },
  { "PRGM",   3,  false },
  { "ALPHA",  4,  false },

  /* row 1 primary / gold */
  { "SIGMA+", 11, false },
  { "S+",     11, false },
  { "Σ+",     11, false },
  { "1/X",    12, false },
  { "SQRT",   13, false },
  { "√X",     13, false },
  { "LOG",    14, false },
  { "LN",     15, false },
  { "SIGMA-", 11, true  },
  { "S-",     11, true  },
  { "Σ-",     11, true  },
  { "Y^X",    12, true  },
  { "YX",     12, true  },
  { "X^2",    13, true  },
  { "X2",     13, true  },
  { "10^X",   14, true  },
  { "10X",    14, true  },
  { "E^X",    15, true  },
  { "EX",     15, true  },

  /* row 2 */
  { "X<>Y",   21, false },
  { "XY",     21, false },
  { "RDOWN",  22, false },
  { "RDN",    22, false },
  { "R↓",     22, false },
  { "SIN",    23, false },
  { "COS",    24, false },
  { "TAN",    25, false },
  { "CLSIGMA",21, true  },
  { "CLS",    21, true  },
  { "CLΣ",    21, true  },
  { "%",      22, true  },
  { "ASIN",   23, true  },
  { "SIN-1",  23, true  },
  { "ACOS",   24, true  },
  { "COS-1",  24, true  },
  { "ATAN",   25, true  },
  { "TAN-1",  25, true  },

  /* row 3 */
  { "SHIFT",  31, false },
  { "XEQ",    32, false },
  { "STO",    33, false },
  { "RCL",    34, false },
  { "SST",    35, false },
  { "ASN",    32, true  },
  { "LBL",    33, true  },
  { "GTO",    34, true  },
  { "BST",    35, true  },

  /* row 4 */
  { "ENTER",  41, false },
  { "CHS",    42, false },
  { "EEX",    43, false },
  { "BSP",    44, false },
  { "<-",     44, false },
  { "BACK",   44, false },
  { "CATALOG",41, true  },
  { "CAT",    41, true  },
  { "ISG",    42, true  },
  { "RTN",    43, true  },
  { "CLX",    44, true  },
  { "CLA",    44, true  },

  /* row 5 */
  { "-",      51, false },
  { "7",      52, false },
  { "8",      53, false },
  { "9",      54, false },
  { "X=Y?",   51, true  },
  { "SF",     52, true  },
  { "CF",     53, true  },
  { "FS?",    54, true  },

  /* row 6 */
  { "+",      61, false },
  { "4",      62, false },
  { "5",      63, false },
  { "6",      64, false },
  { "X<=Y?",  61, true  },
  { "X≤Y?",   61, true  },
  { "BEEP",   62, true  },
  { "P->R",   63, true  },
  { "P→R",    63, true  },
  { "R->P",   64, true  },
  { "R→P",    64, true  },

  /* row 7 */
  { "*",      71, false },
  { "X",      71, false },
  { "×",      71, false },
  { "1",      72, false },
  { "2",      73, false },
  { "3",      74, false },
  { "X>Y?",   71, true  },
  { "FIX",    72, true  },
  { "SCI",    73, true  },
  { "ENG",    74, true  },

  /* row 8 */
  { "/",      81, false },
  { "÷",      81, false },
  { "0",      82, false },
  { ".",      83, false },
  { "RS",     84, false },
  { "R/S",    84, false },
  { "X=0?",   81, true  },
  { "PI",     82, true  },
  { "π",      82, true  },
  { "LASTX",  83, true  },
  { "LSTX",   83, true  },
  { "VIEW",   84, true  },
};


/* Blue alpha legends under the keys (uppercase). Space is the 0 key. */
static int alpha_keycode (unsigned char ch)
{
  if (ch >= 'a' && ch <= 'z')
    ch = (unsigned char) (ch - 'a' + 'A');
  if (ch >= 'A' && ch <= 'E')
    return 11 + (ch - 'A');
  if (ch >= 'F' && ch <= 'J')
    return 21 + (ch - 'F');
  if (ch >= 'K' && ch <= 'M')
    return 32 + (ch - 'K');
  if (ch == 'N')
    return 41;
  if (ch == 'O')
    return 42;
  if (ch == 'P')
    return 43;
  if (ch >= 'Q' && ch <= 'T')
    return 51 + (ch - 'Q');
  if (ch >= 'U' && ch <= 'X')
    return 61 + (ch - 'U');
  if (ch == 'Y')
    return 71;
  if (ch == 'Z')
    return 72;
  if (ch == '=')
    return 73;
  if (ch == '?')
    return 74;
  if (ch == ' ')
    return 82;  /* blue SPACE on 0 */
  if (ch >= '0' && ch <= '9')
    {
      /* Digit keys in alpha: same as primary digit keycodes. */
      static const int dig [] =
	{ 82, 72, 73, 74, 62, 63, 64, 52, 53, 54 };
      return dig [ch - '0'];
    }
  if (ch == '.')
    return 83;
  return -1;
}


static const key_name_t *lookup_key (const char *tok)
{
  size_t i;
  for (i = 0; i < sizeof (key_names) / sizeof (key_names [0]); i++)
    {
      if (strcasecmp (tok, key_names [i].name) == 0)
	return & key_names [i];
    }
  return NULL;
}


typedef struct
{
  char *path;
  int port;   /* 0 = auto */
} mod_arg_t;


typedef struct
{
  int keycode;
  bool gold;   /* expand to SHIFT then key at press time */
} key_step_t;


typedef struct
{
  int digit_count;
  segment_bitmap_t segments [MAX_DIGIT_POSITION];
} lcd_state_t;


static lcd_state_t lcd;


static void headless_display_update (void *ref UNUSED,
				   int digit_count,
				   segment_bitmap_t *segments)
{
  int i;
  lcd.digit_count = digit_count;
  for (i = 0; i < digit_count && i < MAX_DIGIT_POSITION; i++)
    lcd.segments [i] = segments [i];
}


static void drain_display (void)
{
  while (g_main_context_pending (NULL))
    g_main_context_iteration (NULL, FALSE);
}


static void pump_display (sim_t *sim)
{
  sim_get_display_update (sim);
  drain_display ();
}


/* Instructions corresponding to us microseconds at the hardware rate. */
static int insts_for_us (sim_t *sim, int us)
{
  calcdef_t *calcdef = sim_get_calcdef (sim);
  arch_info_t *arch = get_arch_info ((arch_t) calcdef_get_arch (calcdef));
  double words_per_usec;
  int n;

  if (! arch || arch->word_length <= 0 || us <= 0)
    return 1;
  words_per_usec = calcdef_get_clock_frequency (calcdef) /
		   (1.0e6 * arch->word_length);
  n = (int) (us * words_per_usec + 0.5);
  if (n < 1)
    n = 1;
  return n;
}


static bool nut_awake (sim_t *sim)
{
  chip_t *chip;
  int reg;
  uint64_t val;

  chip = sim_find_chip (sim, "Nut", 0);
  if (! chip)
    return false;
  reg = sim_find_register (sim, chip, "awake");
  if (reg < 0)
    return false;
  if (! sim_read_register (sim, chip, reg, 0, & val))
    return false;
  return val != 0;
}


/* Run until op_powoff, then one more chunk so a one-instruction nap
   does not look like the idle sleep.  Wall time is only the host's
   cost of those instructions, plus the timeout if the CPU never sleeps. */
static bool run_until_sleep (sim_t *sim, int timeout_s)
{
  gint64 end = g_get_monotonic_time () + (gint64) timeout_s * 1000000;
  int asleep_streak = 0;

  while (g_get_monotonic_time () < end)
    {
      sim_run_instructions (sim, RUN_CHUNK);
      drain_display ();
      if (! nut_awake (sim))
	{
	  asleep_streak++;
	  if (asleep_streak >= 2)
	    {
	      pump_display (sim);
	      return true;
	    }
	}
      else
	asleep_streak = 0;
    }
  return false;
}


/* HP-41 LCD charset for codes whose ncd text="?" would be useless. */
static const char *charset_fallback (int code)
{
  static const char *tab [128] =
    {
      [0x00] = "@",  [0x01] = "A",  [0x02] = "B",  [0x03] = "C",
      [0x04] = "D",  [0x05] = "E",  [0x06] = "F",  [0x07] = "G",
      [0x08] = "H",  [0x09] = "I",  [0x0a] = "J",  [0x0b] = "K",
      [0x0c] = "L",  [0x0d] = "M",  [0x0e] = "N",  [0x0f] = "O",
      [0x10] = "P",  [0x11] = "Q",  [0x12] = "R",  [0x13] = "S",
      [0x14] = "T",  [0x15] = "U",  [0x16] = "V",  [0x17] = "W",
      [0x18] = "X",  [0x19] = "Y",  [0x1a] = "Z",  [0x1b] = "[",
      [0x1c] = "\\", [0x1d] = "]",  [0x1e] = "^",  [0x1f] = "_",
      [0x20] = " ",  [0x21] = "!",  [0x22] = "\"", [0x23] = "#",
      [0x24] = "$",  [0x25] = "%",  [0x26] = "&",  [0x27] = "'",
      [0x28] = "(",  [0x29] = ")",  [0x2a] = "*",  [0x2b] = "+",
      [0x2c] = ",",  [0x2d] = "-",  [0x2e] = ".",  [0x2f] = "/",
      [0x30] = "0",  [0x31] = "1",  [0x32] = "2",  [0x33] = "3",
      [0x34] = "4",  [0x35] = "5",  [0x36] = "6",  [0x37] = "7",
      [0x38] = "8",  [0x39] = "9",  [0x3a] = ":",  [0x3b] = ";",
      [0x3c] = "<",  [0x3d] = "=",  [0x3e] = ">",  [0x3f] = "?",
      [0x41] = "a",  [0x42] = "b",  [0x43] = "c",  [0x44] = "d",
      [0x45] = "e",  [0x61] = "a",  [0x62] = "b",  [0x63] = "c",
      [0x64] = "d",  [0x65] = "e",  [0x66] = "f",  [0x67] = "g",
      [0x68] = "h",  [0x69] = "i",  [0x6a] = "j",  [0x6b] = "k",
      [0x6c] = "l",  [0x6d] = "m",  [0x6e] = "n",  [0x6f] = "o",
      [0x70] = "p",  [0x71] = "q",  [0x72] = "r",  [0x73] = "s",
      [0x74] = "t",  [0x75] = "u",  [0x76] = "v",  [0x77] = "w",
      [0x78] = "x",  [0x79] = "y",  [0x7a] = "z",
    };
  if (code < 0 || code > 127 || ! tab [code])
    return "?";
  return tab [code];
}


static void lcd_to_string (sim_t *sim, char *buf, size_t buflen)
{
  const segment_bitmap_t *cg;
  size_t o = 0;
  int i;

  cg = calcdef_get_char_gen (sim_get_calcdef (sim), "coconut_lcd_0");
  buf [0] = '\0';
  if (! cg || lcd.digit_count <= 0)
    return;

  for (i = 0; i < lcd.digit_count && i < HEADLESS_LCD_DIGITS; i++)
    {
      segment_bitmap_t segs = lcd.segments [i];
      segment_bitmap_t base = segs & SEG_CHAR_MASK;
      int code = -1;
      int c;
      const char *glyph;
      size_t glen;

      for (c = 0; c < 128; c++)
	{
	  if ((cg [c] & SEG_CHAR_MASK) == base)
	    {
	      code = c;
	      break;
	    }
	}
      glyph = charset_fallback (code >= 0 ? code : 0x3f);
      glen = strlen (glyph);
      if (o + glen + 2 >= buflen)
	break;
      memcpy (buf + o, glyph, glen);
      o += glen;

      if ((segs & SEGMENTS_COMMA) == SEGMENTS_COMMA)
	buf [o++] = ',';
      else if ((segs & SEGMENTS_COLON) == SEGMENTS_COLON)
	buf [o++] = ':';
      else if (segs & SEGMENTS_PERIOD)
	buf [o++] = '.';
    }
  buf [o] = '\0';
}


static bool press_key (sim_t *sim, int user_keycode, int timeout_s)
{
  hw_keycode_t hw;
  chip_t *chip = NULL;
  chip_t *extra = NULL;
  int ret_line = 0;
  int extra_ret = 0;

  if (! calcdef_get_key (sim_get_calcdef (sim), user_keycode,
			 & hw, & chip, & ret_line, & extra, & extra_ret))
    {
      fprintf (stderr, "headless: no mapping for user keycode %d\n",
	       user_keycode);
      return false;
    }
  sim_key (sim, user_keycode, true);
  sim_run_instructions (sim, insts_for_us (sim, KEY_HOLD_US));
  drain_display ();
  sim_key (sim, user_keycode, false);
  return run_until_sleep (sim, timeout_s);
}


static bool press_step (sim_t *sim, key_step_t step, int timeout_s)
{
  if (step.gold && ! press_key (sim, 31, timeout_s))  /* SHIFT */
    return false;
  return press_key (sim, step.keycode, timeout_s);
}


static int next_free_port (sim_t *sim)
{
  int port;
  for (port = 1; port <= 4; port++)
    {
      if (! plugin_module_get_by_port (sim, port))
	return port;
    }
  return -1;
}


static bool install_mod (sim_t *sim, mod_arg_t *m)
{
  int port = m->port;
  plugin_module_t *mod;

  if (port == 0)
    {
      port = next_free_port (sim);
      if (port < 0)
	{
	  fprintf (stderr, "headless: no free port for '%s'\n", m->path);
	  return false;
	}
    }
  else if (port < 1 || port > 4)
    {
      fprintf (stderr, "headless: port %d out of range for '%s'\n",
	       port, m->path);
      return false;
    }
  else if (plugin_module_get_by_port (sim, port))
    {
      fprintf (stderr, "headless: port %d already occupied for '%s'\n",
	       port, m->path);
      return false;
    }

  mod = sim_install_module (sim, m->path, port, false);
  if (! mod)
    {
      fprintf (stderr, "headless: failed to load module '%s' on port %d\n",
	       m->path, port);
      return false;
    }
  return true;
}


/* Parse PATH or PATH:PORT. On Unix, the last ':' followed by digits is the
   port; otherwise the whole string is the path. */
static bool parse_mod_arg (const char *arg, mod_arg_t *out)
{
  const char *colon = strrchr (arg, ':');
  char *end;
  long port;

  out->port = 0;
  if (colon && colon > arg && colon [1])
    {
      port = strtol (colon + 1, & end, 10);
      if (*end == '\0' && end != colon + 1)
	{
	  out->port = (int) port;
	  out->path = newstrn ((char *) arg, (int) (colon - arg));
	  return true;
	}
    }
  out->path = newstr (arg);
  return true;
}


static int append_step (key_step_t *seq, int *n, int keycode, bool gold)
{
  if (*n >= MAX_KEY_SEQ)
    {
      fprintf (stderr, "headless: --keys sequence too long\n");
      return -1;
    }
  seq [*n].keycode = keycode;
  seq [*n].gold = gold;
  (*n)++;
  return 0;
}


static int append_alpha_string (key_step_t *seq, int *n, const char *s)
{
  const unsigned char *p = (const unsigned char *) s;
  if (append_step (seq, n, 4, false) < 0)  /* ALPHA */
    return -1;
  while (*p)
    {
      int kc = alpha_keycode (*p);
      if (kc < 0)
	{
	  fprintf (stderr, "headless: unsupported alpha character '%c'\n", *p);
	  return -1;
	}
      if (append_step (seq, n, kc, false) < 0)
	return -1;
      p++;
    }
  if (append_step (seq, n, 4, false) < 0)  /* ALPHA */
    return -1;
  return 0;
}


/* Expand --keys text into press steps. */
static int parse_keys (const char *text, key_step_t *seq, int *n)
{
  const char *p = text;
  *n = 0;
  while (*p)
    {
      while (*p && isspace ((unsigned char) *p))
	p++;
      if (! *p)
	break;
      if (*p == '"')
	{
	  const char *start;
	  char *str;
	  p++;
	  start = p;
	  while (*p && *p != '"')
	    p++;
	  if (*p != '"')
	    {
	      fprintf (stderr, "headless: unterminated string in --keys\n");
	      return -1;
	    }
	  str = newstrn ((char *) start, (int) (p - start));
	  p++;
	  if (append_alpha_string (seq, n, str) < 0)
	    {
	      free (str);
	      return -1;
	    }
	  free (str);
	  continue;
	}
      {
	const char *start = p;
	char tok [64];
	size_t len;
	const key_name_t *kn;
	while (*p && ! isspace ((unsigned char) *p) && *p != '"')
	  p++;
	len = (size_t) (p - start);
	if (len >= sizeof (tok))
	  {
	    fprintf (stderr, "headless: key token too long\n");
	    return -1;
	  }
	memcpy (tok, start, len);
	tok [len] = '\0';
	kn = lookup_key (tok);
	if (! kn)
	  {
	    fprintf (stderr, "headless: unknown key '%s'\n", tok);
	    return -1;
	  }
	if (append_step (seq, n, kn->user_keycode, kn->gold) < 0)
	  return -1;
      }
    }
  return 0;
}


bool headless_requested (int argc, char **argv)
{
  int i;
  for (i = 1; i < argc; i++)
    {
      if (strcmp (argv [i], "--mod") == 0 ||
	  strcmp (argv [i], "--keys") == 0 ||
	  strcmp (argv [i], "--show") == 0 ||
	  strcmp (argv [i], "--expect") == 0 ||
	  strcmp (argv [i], "--timeout") == 0)
	return true;
    }
  return false;
}


int headless_main (int argc, char **argv)
{
  char *model = NULL;
  mod_arg_t mods [MAX_MODS];
  int nmods = 0;
  char *keys_text = NULL;
  char *expect_text = NULL;
  bool show = false;
  int timeout_s = DEFAULT_TIMEOUT_S;
  key_step_t seq [MAX_KEY_SEQ];
  int nseq = 0;
  char *ncd_fn;
  sim_t *sim;
  calcdef_t *calcdef;
  int i;
  int status = 0;
  char lcd_buf [LCD_BUF];

  memset (mods, 0, sizeof (mods));

  for (i = 1; i < argc; i++)
    {
      if (strcmp (argv [i], "--mod") == 0)
	{
	  if (++i >= argc)
	    fatal (1, "--mod needs PATH or PATH:PORT\n");
	  if (nmods >= MAX_MODS)
	    fatal (1, "too many --mod arguments\n");
	  if (! parse_mod_arg (argv [i], & mods [nmods]))
	    fatal (1, "bad --mod '%s'\n", argv [i]);
	  nmods++;
	}
      else if (strcmp (argv [i], "--keys") == 0)
	{
	  if (++i >= argc)
	    fatal (1, "--keys needs a string\n");
	  keys_text = argv [i];
	}
      else if (strcmp (argv [i], "--show") == 0)
	show = true;
      else if (strcmp (argv [i], "--expect") == 0)
	{
	  if (++i >= argc)
	    fatal (1, "--expect needs a string\n");
	  expect_text = argv [i];
	  show = true;
	}
      else if (strcmp (argv [i], "--timeout") == 0)
	{
	  if (++i >= argc)
	    fatal (1, "--timeout needs seconds\n");
	  timeout_s = atoi (argv [i]);
	  if (timeout_s <= 0)
	    fatal (1, "--timeout must be positive\n");
	}
      else if (argv [i][0] == '-')
	fatal (1, "unrecognized headless option '%s'\n", argv [i]);
      else if (! model)
	model = argv [i];
      else
	fatal (1, "unexpected argument '%s'\n", argv [i]);
    }

  if (! model)
    fatal (1, "headless mode needs a model (41c, 41cv, or 41cx)\n");
  if (! keys_text && ! show && nmods == 0)
    fatal (1, "headless mode needs --mod, --keys, and/or --show\n");

  if (keys_text && parse_keys (keys_text, seq, & nseq) < 0)
    return 2;

  ncd_fn = find_file_with_suffix (model, ".ncd", default_path);
  if (! ncd_fn)
    fatal (2, "can't find %s.ncd\n", model);

  sim = sim_init (ncd_fn,
		  headless_display_update,
		  NULL);
  calcdef = sim_get_calcdef (sim);
  if (calcdef_get_platform (calcdef) != PLATFORM_COCONUT)
    fatal (2, "headless mode only supports the 41C family\n");

  for (i = 0; i < nmods; i++)
    {
      if (! install_mod (sim, & mods [i]))
	{
	  status = 2;
	  goto done;
	}
    }

  sim_reset (sim);

  if (! run_until_sleep (sim, timeout_s))
    {
      fprintf (stderr, "headless: timeout waiting for power-on sleep\n");
      status = 1;
      goto done;
    }

  /* Cold start with empty RAM shows MEMORY LOST until a key clears it. */
  lcd_to_string (sim, lcd_buf, sizeof (lcd_buf));
  if (strstr (lcd_buf, "MEMORY LOST") != NULL)
    {
      /* ENTER clears MEMORY LOST without digit entry. */
      if (! press_key (sim, 41, timeout_s))
	{
	  fprintf (stderr, "headless: timeout after clearing MEMORY LOST\n");
	  status = 1;
	  goto done;
	}
      lcd_to_string (sim, lcd_buf, sizeof (lcd_buf));
      if (strstr (lcd_buf, "MEMORY LOST") != NULL)
	{
	  fprintf (stderr, "headless: MEMORY LOST uncleared (lcd='%s')\n",
		   lcd_buf);
	  status = 1;
	  goto done;
	}
    }

  for (i = 0; i < nseq; i++)
    {
      if (! press_step (sim, seq [i], timeout_s))
	{
	  fprintf (stderr, "headless: timeout waiting for sleep after keys\n");
	  status = 1;
	  goto done;
	}
      if (getenv ("HEADLESS_TRACE"))
	{
	  lcd_to_string (sim, lcd_buf, sizeof (lcd_buf));
	  fprintf (stderr, "headless: after key %d%s lcd='%s' awake=%d\n",
		   seq [i].keycode, seq [i].gold ? " (gold)" : "",
		   lcd_buf, nut_awake (sim) ? 1 : 0);
	}
    }

  if ((nseq > 0 || show || expect_text) && nut_awake (sim))
    {
      if (! run_until_sleep (sim, timeout_s))
	{
	  fprintf (stderr, "headless: timeout waiting for sleep after keys\n");
	  status = 1;
	  goto done;
	}
    }

  pump_display (sim);
  lcd_to_string (sim, lcd_buf, sizeof (lcd_buf));

  if (show)
    printf ("%s\n", lcd_buf);

  if (expect_text)
    {
      /* Compare with whitespace normalized: trim ends. */
      char *got = g_strstrip (g_strdup (lcd_buf));
      char *want = g_strstrip (g_strdup (expect_text));
      if (strcmp (got, want) != 0)
	{
	  fprintf (stderr, "headless: expect failed: got %s want %s\n",
		   got, want);
	  status = 1;
	}
      g_free (got);
      g_free (want);
    }

 done:
  sim_quit (sim);
  for (i = 0; i < nmods; i++)
    free (mods [i].path);
  free (ncd_fn);
  return status;
}
