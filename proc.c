#define WSIZE 14

typedef uint8_t digit;
typedef digit reg [WSIZE];

reg a, b, c, d, e, f, m;
digit p;

#define MAX_RAM 100
int max_ram = MAX_RAM;
int ram_addr;
reg ram [MAX_RAM];

#define SSIZE 12
uint8_t s [SSIZE];

uint8_t carry, prev_carry;

uint8_t pc;
uint8_t rom;
uint8_t group;

uint8_t del_rom;
uint8_t del_grp;

uint8_t ret_pc;

int display_enable;
int key_flag;
int key_buf;
int io_count;


int prev_pc;  /* used to store complete five-digit octal address of instruction */


#define MAX_GROUP 2
#define MAX_ROM 8
#define ROM_SIZE 256

typedef unsigned short romword;
romword ucode [MAX_GROUP] [MAX_ROM] [ROM_SIZE];
uint8_t bpt     [MAX_GROUP] [MAX_ROM] [ROM_SIZE];
char *source  [MAX_GROUP] [MAX_ROM] [ROM_SIZE];

int run = 1;
int step = 0;
int trace = 0;
void bad_op (int opcode)
{
  printf ("illegal opcode %02x at %05o\n", opcode, prev_pc);
}

digit do_add (digit x, digit y)
{
  int res;

  res = x + y + carry;
  if (res > 9)
    {
      res -= 10;
      carry = 1;
    }
  else
    carry = 0;
  return (res);
}

digit do_sub (digit x, digit y)
{
  int res;

  res = (x - y) - carry;
  if (res < 0)
    {
      res += 10;
      carry = 1;
    }
  else
    carry = 0;
  return (res);
}

void op_arith (int opcode)
{
  uint8_t op, field;
  int first, last;
  int temp;
  int i;
  reg t;

  op = opcode >> 5;
  field = (opcode >> 2) & 7;

  switch (field)
    {
    case 0:  /* p  */
      first =  p; last =  p;
      if (p >= WSIZE)
	{
	  printf ("Warning! p > WSIZE at %05o\n", prev_pc);
	  last = 0;  /* don't do anything */
	}
      break;
    case 1:  /* m  */  first =  3; last = 12; break;
    case 2:  /* x  */  first =  0; last =  2; break;
    case 3:  /* w  */  first =  0; last = 13; break;
    case 4:  /* wp */
      first =  0; last =  p; break;
      if (p > 13)
	{
	  printf ("Warning! p >= WSIZE at %05o\n", prev_pc);
	  last = 13;
	}
      break;
    case 5:  /* ms */  first =   3; last = 13; break;
    case 6:  /* xs */  first =   2; last =  2; break;
    case 7:  /* s  */  first =  13; last = 13; break;
    }

  switch (op)
    {
    case 0x00:  /* if b[f] = 0 */
      for (i = first; i <= last; i++)
	carry |= (b [i] != 0);
      break;
    case 0x01:  /* 0 -> b[f] */
      for (i = first; i <= last; i++)
	b [i] = 0;
      carry = 0;
      break;
    case 0x02:  /* if a >= c[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (a [i], c [i]);
      break;
    case 0x03:  /* if c[f] >= 1 */
      carry = 1;
      for (i = first; i <= last; i++)
	carry &= (c [i] == 0);
      break;
    case 0x04:  /* b -> c[f] */
      for (i = first; i <= last; i++)
	c [i] = b [i];
      carry = 0;
      break;
    case 0x05:  /* 0 - c -> c[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	c [i] = do_sub (0, c [i]);
      break;
    case 0x06:  /* 0 -> c[f] */
      for (i = first; i <= last; i++)
	c [i] = 0;
      carry = 0;
      break;
    case 0x07:  /* 0 - c - 1 -> c[f] */
      carry = 1;
      for (i = first; i <= last; i++)
	c [i] = do_sub (0, c [i]);
      break;
    case 0x08:  /* shift left a[f] */
      for (i = last; i >= first; i--)
	a [i] = (i == first) ? 0 : a [i-1];
      carry = 0;
      break;
    case 0x09:  /* a -> b[f] */
      for (i = first; i <= last; i++)
	b [i] = a [i];
      carry = 0;
      break;
    case 0x0a:  /* a - c -> c[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	c [i] = do_sub (a [i], c [i]);
      break;
    case 0x0b:  /* c - 1 -> c[f] */
      carry = 1;
      for (i = first; i <= last; i++)
	c [i] = do_sub (c [i], 0);
      break;
    case 0x0c:  /* c -> a[f] */
      for (i = first; i <= last; i++)
	a [i] = c [i];
      carry = 0;
      break;
    case 0x0d:  /* if c[f] = 0 */
      for (i = first; i <= last; i++)
	carry |= (c [i] != 0);
      break;
    case 0x0e:  /* a + c -> c[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	c [i] = do_add (a [i], c [i]);
      break;
    case 0x0f:  /* c + 1 -> c[f] */
      carry = 1;
      for (i = first; i <= last; i++)
	c [i] = do_add (c [i], 0);
      break;
    case 0x10:  /* if a >= b[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	t [i] = do_sub (a [i], b [i]);
      break;
    case 0x11:  /* b exchange c[f] */
      for (i = first; i <= last; i++)
	{ temp = b[i]; b [i] = c [i]; c [i] = temp; }
      carry = 0;
      break;
    case 0x12:  /* shift right c[f] */
      for (i = first; i <= last; i++)
	c [i] = (i == last) ? 0 : c [i+1];
      carry = 0;
      break;
    case 0x13:  /* if a[f] >= 1 */
      carry = 1;
      for (i = first; i <= last; i++)
	carry &= (a [i] == 0);
      break;
    case 0x14:  /* shift right b[f] */
      for (i = first; i <= last; i++)
	b [i] = (i == last) ? 0 : b [i+1];
      carry = 0;
      break;
    case 0x15:  /* c + c -> c[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	c [i] = do_add (c [i], c [i]);
      break;
    case 0x16:  /* shift right a[f] */
      for (i = first; i <= last; i++)
	a [i] = (i == last) ? 0 : a [i+1];
      carry = 0;
      break;
    case 0x17:  /* 0 -> a[f] */
      for (i = first; i <= last; i++)
	a [i] = 0;
      carry = 0;
      break;
    case 0x18:  /* a - b -> a[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	a [i] = do_sub (a [i], b [i]);
      break;
    case 0x19:  /* a exchange b[f] */
      for (i = first; i <= last; i++)
	{ temp = a[i]; a [i] = b [i]; b [i] = temp; }
      carry = 0;
      break;
    case 0x1a:  /* a - c -> a[f] */
      carry = 0;
      for (i = first; i <= last; i++)
        a [i] = do_sub (a [i], c [i]);
      break;
    case 0x1b:  /* a - 1 -> a[f] */
      carry = 1;
      for (i = first; i <= last; i++)
	a [i] = do_sub (a [i], 0);
      break;
    case 0x1c:  /* a + b -> a[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	a [i] = do_add (a [i], b [i]);
      break;
    case 0x1d:  /* a exchange c[f] */
      for (i = first; i <= last; i++)
	{ temp = a[i]; a [i] = c [i]; c [i] = temp; }
      carry = 0;
      break;
    case 0x1e:  /* a + c -> a[f] */
      carry = 0;
      for (i = first; i <= last; i++)
	a [i] = do_add (a [i], c [i]);
      break;
    case 0x1f:  /* a + 1 -> a[f] */
      carry = 1;
      for (i = first; i <= last; i++)
	a [i] = do_add (a [i], 0);
      break;
    }
}

void op_goto (int opcode)
{
  if (! prev_carry)
    {
      pc = opcode >> 2;
      rom = del_rom;
      group = del_grp;
    }
}

void op_jsb (int opcode)
{
  ret_pc = pc;
  pc = opcode >> 2;
  rom = del_rom;
  group = del_grp;
}

void op_return (int opcode)
{
  pc = ret_pc;
}

void op_nop (int opcode)
{
}

void op_dec_p (int opcode)
{
  p = (p - 1) & 0xf;
}

void op_inc_p (int opcode)
{
  p = (p + 1) & 0xf;
}

void op_clear_s (int opcode)
{
  int i;
  for (i = 0; i < SSIZE; i++)
    s [i] = 0;
}

void op_c_exch_m (int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = c [i]; c [i] = m[i]; m [i] = t;
    }
}

void op_m_to_c (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    c [i] = m [i];
}

void op_c_to_addr (int opcode)
{
#ifdef HP55
  ram_addr = c [12] * 10 + c[11];
#else
  ram_addr = c [12];
#endif
  if (ram_addr >= max_ram)
    printf ("c -> ram addr: address %d out of range\n", ram_addr);
}

void op_c_to_data (int opcode)
{
  int i;
  if (ram_addr >= max_ram)
    {
      printf ("c -> data: address %d out of range\n", ram_addr);
      return;
    }
  for (i = 0; i < WSIZE; i++)
    ram [ram_addr][i] = c [i];
}

void op_data_to_c (int opcode)
{
  int i;
  if (ram_addr >= max_ram)
    {
      printf ("data -> c: address %d out of range, loading 0\n", ram_addr);
      for (i = 0; i < WSIZE; i++)
	c [i] = 0;
      return;
    }
  for (i = 0; i < WSIZE; i++)
    c [i] = ram [ram_addr][i];
}

void op_c_to_stack (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      f [i] = e [i];
      e [i] = d [i];
      d [i] = c [i];
    }
}

void op_stack_to_a (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    {
      a [i] = d [i];
      d [i] = e [i];
      e [i] = f [i];
    }
}

void op_down_rotate (int opcode)
{
  int i, t;
  for (i = 0; i < WSIZE; i++)
    {
      t = c [i];
      c [i] = d [i];
      d [i] = e [i];
      e [i] = f [i];
      f [i] = t;
    }
}

void op_clear_reg (int opcode)
{
  int i;
  for (i = 0; i < WSIZE; i++)
    a [i] = b [i] = c [i] = d [i] = e [i] = f [i] = m [i] = 0;
}

void op_load_constant (int opcode)
{
  if (p >= WSIZE)
    {
#if 0 /* HP-45 depends on load constant with p > 13 not affecting C */
      printf ("load constant w/ p >= WSIZE at %05o\n", prev_pc)
      ;
#endif
    }
  else if ((opcode >> 6) > 9)
    printf ("load constant > 9\n");
  else
    c [p] = opcode >> 6;
  p = (p - 1) & 0xf;
}

void op_set_s (int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", prev_pc);
  else
    s [opcode >> 6] = 1;
}

void op_clr_s (int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", prev_pc);
  else
    s [opcode >> 6] = 0;
}

void op_test_s (int opcode)
{
  if ((opcode >> 6) >= SSIZE)
    printf ("stat >= SSIZE at %05o\n", prev_pc);
  else
    carry = s [opcode >> 6];
}

void op_set_p (int opcode)
{
  p = opcode >> 6;
}

void op_test_p (int opcode)
{
  carry = (p == (opcode >> 6));
}

void op_sel_rom (int opcode)
{
  rom = opcode >> 7;
  group = del_grp;

  del_rom = rom;
}

void op_del_sel_rom (int opcode)
{
  del_rom = opcode >> 7;
}

void op_del_sel_grp (int opcode)
{
  del_grp = (opcode >> 7) & 1;
}

void op_keys_to_rom_addr (int opcode)
{
  pc = key_buf;
}

void op_rom_addr_to_buf (int opcode)
{
/* I don't know what the heck this instruction is supposed to do! */
#ifdef DEBUG
  printf ("rom addr to buf!!!!!!!!!!!!\n");
#endif /* DEBUG */
}

void op_display_off (int opcode)
{
  display_enable = 0;
  io_count = 2;
  /*
   * Don't immediately turn off display because the very next instruction
   * might be a display_toggle to turn it on.  This happens in the HP-45
   * stopwatch.
   */
}

void op_display_toggle (int opcode)
{
  display_enable = ! display_enable;
  io_count = 0;  /* force immediate display update */
}

void (* op_fcn [1024])(int);

void init_ops (void)
{
  int i;
  for (i = 0; i < 1024; i += 4)
    {
      op_fcn [i + 0] = bad_op;
      op_fcn [i + 1] = op_jsb;
      op_fcn [i + 2] = op_arith;
      op_fcn [i + 3] = op_goto;
    }

  op_fcn [0x000] = op_nop;
  op_fcn [0x01c] = op_dec_p;
  op_fcn [0x028] = op_display_toggle;
  op_fcn [0x030] = op_return;
  op_fcn [0x034] = op_clear_s;
  op_fcn [0x03c] = op_inc_p;
  op_fcn [0x0d0] = op_keys_to_rom_addr;
  op_fcn [0x0a8] = op_c_exch_m;
  op_fcn [0x128] = op_c_to_stack;
  op_fcn [0x1a8] = op_stack_to_a;
  op_fcn [0x200] = op_rom_addr_to_buf;
  op_fcn [0x228] = op_display_off;
  op_fcn [0x270] = op_c_to_addr;
  op_fcn [0x2a8] = op_m_to_c;
  op_fcn [0x2f0] = op_c_to_data;
  op_fcn [0x2f8] = op_data_to_c;
  op_fcn [0x328] = op_down_rotate;
  op_fcn [0x3a8] = op_clear_reg;

  op_fcn [0x234] = op_del_sel_grp;
  op_fcn [0x2b4] = op_del_sel_grp;

  for (i = 0; i < 1024; i += 128)
    {
      op_fcn [i | 0x010] = op_sel_rom;
      op_fcn [i | 0x074] = op_del_sel_rom;
    }
  for (i = 0; i < 1024; i += 64)
    {
      op_fcn [i | 0x018] = op_load_constant;
      op_fcn [i | 0x004] = op_set_s;
      op_fcn [i | 0x024] = op_clr_s;
      op_fcn [i | 0x014] = op_test_s;
      op_fcn [i | 0x00c] = op_set_p;
      op_fcn [i | 0x02c] = op_test_p;
    }
}

void disassemble_instruction (int g, int r, int p, int opcode)
{
  int i;
  printf ("L%1o%1o%3o:  ", g, r, p);
  for (i = 0x200; i; i >>= 1)
    printf ((opcode & i) ? "1" : ".");
}

/*
 * set breakpoints at every location so we know if we hit
 * uninitialized ROM
 */
void init_breakpoints (void)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	bpt [g] [r] [p] = 1;
}


void init_source (void)
{
  int g, r, p;

  for (g = 0; g < MAX_GROUP; g++)
    for (r = 0; r < MAX_ROM; r++)
      for (p = 0; p < ROM_SIZE; p++)
	source [g] [r] [p] = NULL;
}


void read_object_file (char *fn, FILE *f)
{
  int i;
  char buf [80];
  int g, r, p, opcode;
  int count = 0;

  while (fgets (buf, sizeof (buf), f))
    {
      i = sscanf (buf, "%1o%1o%3o:%3x", & g, & r, & p, & opcode);
      if (i != 4)
	fprintf (stderr, "only converted %d items\n", i);
      else if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
	fprintf (stderr, "bad address\n");
      else
	{
	  ucode [g][r][p] = opcode;
	  bpt   [g][r][p] = 0;
	  count ++;
	}
    }
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
}


int parse_address (char *oct, int *g, int *r, int *p)
{
  return (sscanf (oct, "%1o%1o%3o", g, r, p) == 3);
}


int parse_opcode (char *bin, int *opcode)
{
  int i;

  *opcode = 0;
  for (i = 0; i < 10; i++)
    {
      (*opcode) <<= 1;
      if (*bin == '1')
	(*opcode) += 1;
      else if (*bin == '.')
	(*opcode) += 0;
      else
	return (0);
      *bin++;
    }
  return (1);
}


void read_listing_file (char *fn, FILE *f, int keep_src)
{
  int i;
  char buf [80];
  int g, r, p, opcode;
  int count = 0;

  while (fgets (buf, sizeof (buf), f))
    {
      if ((strlen (buf) >= 25) && (buf [7] == 'L') && (buf [13] == ':') &&
	  parse_address (& buf [8], & g, &r, &p) &&
	  parse_opcode (& buf [16], & opcode))
	{
	  if ((g >= MAX_GROUP) || (r >= MAX_ROM) || (p >= ROM_SIZE))
	    fprintf (stderr, "bad address\n");
	  else if (! bpt [g][r][p])
	    {
	      fprintf (stderr, "duplicate listing line for address %1o%1o%03o\n",
		       g, r, p);
	      fprintf (stderr, "orig: %s\n", source [g][r][p]);
	      fprintf (stderr, "dup:  %s\n", source [g][r][p]);
	    }
	  else
	    {
	      ucode  [g][r][p] = opcode;
	      bpt    [g][r][p] = 0;
	      if (keep_src)
		source [g][r][p] = newstr (& buf [0]);
	      count ++;
	    }
	}
    }
  fprintf (stderr, "read %d words from '%s'\n", count, fn);
}


void print_reg (reg r)
{
  int i;
  for (i = WSIZE - 1; i >= 0; i--)
    printf ("%x", r [i]);
}


void print_stat (void)
{
  int i;
  for (i = 0; i < SSIZE; i++)
    printf (s [i] ? "%x" : ".", i);
}


void handle_io (void)
{
  char buf [WSIZE + 2];
  char *bp;
  int i;

  bp = & buf [0];
  if (display_enable)
    {
      for (i = WSIZE - 1; i >= 0; i--)
	{
	  if (b [i] >= 8)
	    *bp++ = ' ';
	  else if ((i == 2) || (i == 13))
	    {
	      if (a [i] >= 8)
		*bp++ = '-';
	      else
		*bp++ = ' ';
	    }
	  else
	    *bp++ = '0' + a [i];
	  if (b [i] == 2)
	    *bp++ = '.';
	}
    }
  *bp = '\0';
  update_display (buf);
  i = check_keyboard ();
  if (i >= 0)
    {
      key_flag = 1;
      key_buf = i;
    }
  else
    key_flag = 0;
}


void debugger (void)
{
  int opcode;
  int cycle;

  cycle = 0;
  pc = 0;
  rom = 0;
  group = 0;
  del_rom = 0;
  del_grp = 0;

  op_clear_reg (0);
  op_clear_s (0);
  p = 0;

  io_count = 0;
  display_enable = 0;
  key_flag = 0;

  for (;;)
    {
      while (run || step)
	{
	  if (trace)
	    {
	      if (source [group][rom][pc])
		printf ("%s", source [group][rom][pc]);
	      else
		disassemble_instruction (group, rom, pc, opcode);
	      printf ("\n");
	    }
	  prev_pc = (group << 12) | (rom << 9) | pc;
	  opcode = ucode [group][rom][pc];
	  prev_carry = carry;
	  carry = 0;
	  if (key_flag)
	    s [0] = 1;
#if HP55
	  if (learn_mode)
	    s [3] = 1;
	  if (stopwatch_mode)
	    s [11] = 1;
#endif
	  pc++;
	  (* op_fcn [opcode]) (opcode);
	  cycle++;
	  if (trace)
	    {
	      printf ("  p=%x", p);
	      printf (" stat=");
	      print_stat ();
	      printf (" a=");
	      print_reg (a);
	      printf (" b=");
	      print_reg (b);
	      printf (" c=");
	      print_reg (c);
	      printf ("\n");
	    }
	  step = 0;
	  io_count--;
	  if (io_count <= 0)
	    {
	      handle_io ();
	      io_count = 35;
	    }
	}
      /* get a command here */
    }
}
