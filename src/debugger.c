/*
$Id$
Copyright 1996, 2001, 2003, 2004 Eric L. Smith <eric@brouhaha.com>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.  Note that I am not
granting permission to redistribute or modify Nonpareil under the
terms of any later version of the General Public License.

Nonpareil is distributed in the hope that it will be useful (or at
least amusing), but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (in the file "COPYING"); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA 02111, USA.
*/

#include <pty.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <glib.h>
#include <gtk/gtk.h>
#include <vte/vte.h>

#ifdef USE_READLINE
#include <readline/readline.h>
#include <readline/history.h>
#endif

#ifdef USE_TCL
#include <tcl.h>
#endif

#include "util.h"
#include "display.h"
#include "proc.h"
#include "debugger.h"


#define MAX_ARGS 100

#ifndef USE_READLINE
  #define MAX_LINE 200
#endif


struct dbg_t
{
  sim_t *sim;
  GThread *thread;
  int slave_pty;
  GtkWidget *window;
  FILE *in;
  FILE *out;
  FILE *err;
#ifdef USE_TCL
  Tcl_Interp *tcl_interp;
#endif
};


#ifdef USE_TCL
#define CMD_ARGS ClientData clientData, Tcl_Interp *interp, int argc, char *argv[]
#else
#define CMD_ARGS dbg_t *dbg, int argc, char *argv[]
#endif


static int xyzzy_cmd (CMD_ARGS)
{
#ifdef USE_TCL
  dbg_t *dbg = (dbg_t *) clientData;
#endif
  fprintf (dbg->err, "Nothing happens here.\n");
  return (0);
}


static int go_cmd (CMD_ARGS)
{
#ifdef USE_TCL
  dbg_t *dbg = (dbg_t *) clientData;
#endif
  if (sim_running (dbg->sim))
    {
      fprintf (dbg->err, "already running\n");
      return (2);
    }
  sim_start (dbg->sim);
  return (0);
}


static int halt_cmd (CMD_ARGS)
{
#ifdef USE_TCL
  dbg_t *dbg = (dbg_t *) clientData;
#endif
  if (! sim_running (dbg->sim))
    {
      fprintf (dbg->err, "already halted\n");
      return (2);
    }
  sim_stop (dbg->sim);
  return (0);
}


static int step_cmd (CMD_ARGS)
{
#ifdef USE_TCL
  dbg_t *dbg = (dbg_t *) clientData;
#endif
  if (sim_running (dbg->sim))
    {
      fprintf (dbg->err, "already running\n");
      return (2);
    }
  sim_step (dbg->sim);
  return (0);
}


static int quit_cmd (CMD_ARGS)
{ 
  if (argc != 1)
    return (-1);
  exit (0);
}


static int help_cmd (CMD_ARGS);

#ifdef USE_TCL
#define cmd_t Tcl_CmdProc *
#else
typedef int (*cmd_t)(CMD_ARGS);
#endif


typedef struct
{
  char *name;
  cmd_t handler;
  int min_chr;
  char *usage;
} cmd_entry;


cmd_entry cmd_table [] =
{
  { "go",    (cmd_t) go_cmd,         1, "Go           start execution\n" },
  { "halt",  (cmd_t) halt_cmd,       2, "HAlt         halt execution\n" },
  { "help",  (cmd_t) help_cmd,       1, "Help         list commands\n" },
  { "quit",  (cmd_t) quit_cmd,       4, "QUIT         quit simulator\n" },
  { "step",  (cmd_t) step_cmd,       1, "Step         single-step\n" },
  { "xyzzy", (cmd_t) xyzzy_cmd,     1, "Xyzzy\n" },
  { NULL, NULL, 0, NULL }
};


static char *debugger_prompt = "> ";


static int find_cmd (char *s)
{
  int i;
  int len = strlen (s);

  for (i = 0; cmd_table [i].name; i++)
    {
      if ((len >= cmd_table [i].min_chr) &&
          (strncasecmp (s, cmd_table [i].name, len) == 0))
        return (i);
    }

  return (-1);
}


static int help_cmd (CMD_ARGS)
{
#ifdef USE_TCL
  dbg_t *dbg = (dbg_t *) clientData;
#endif
  int i;

  if (argc == 1)
    {
      for (i = 0; cmd_table [i].name; i++)
        fprintf (dbg->err, cmd_table [i].usage);
      fprintf (dbg->err, "\n"
	       "Commands may be abbreviated to the portion listed in caps.\n");
      return (0);
    }

  if (argc != 2)
    return (-1);

  i = find_cmd (argv [1]);
  if (i < 0)
    {
      fprintf (dbg->err, "unrecognized command\n");
      return (1);
    }
  
  fprintf (dbg->err, cmd_table [i].usage);
  return (0);
}


#ifndef USE_TCL
static void execute_command (CMD_ARGS)
{
  int i;
  
  i = find_cmd (argv [0]);

  if (i < 0)
    {
      fprintf (dbg->err, "unrecognized command\n");
      return;
    }
  
  if ((* cmd_table [i].handler)(dbg, argc, argv) < 0)
    fprintf (dbg->err, "Usage: %s", cmd_table [i].usage);
}
#endif


#ifndef USE_READLINE
/*
 * print prompt, get a line of input, return a copy
 * caller must free
 */
char *readline (dbg_t *dbg, char *prompt)
{
  char inbuf [MAX_LINE];

  if (prompt)
    {
      fprintf (dbg->out, prompt);
      fflush (dbg->out);
    }
  fgets (inbuf, MAX_LINE, dbg->in);
  return (strdup (& inbuf [0]));
}
#endif /* USE_READLINE */



static void debugger_command (dbg_t *dbg, char *cmd)
{
#ifdef USE_TCL
  int result;
  const char *result_string;
#else
  char *s;
  int argc;
  char *argv [MAX_ARGS];
#endif

#ifdef USE_READLINE
  if (*cmd)
    add_history (cmd);
#endif

#ifdef USE_TCL
  result = Tcl_Eval (dbg->tcl_interp, cmd);
  result_string = Tcl_GetStringResult (dbg->tcl_interp);
  if (result != TCL_OK)
    fprintf (stderr, "TCL error ");
  if (result_string && strlen (result_string))
    fprintf (stderr, "%s\n", result_string);
#else
  argc = 0;
  for (s = cmd; (argc < MAX_ARGS) && ((s = strtok (s, " \t\n")) != NULL); s = NULL)
    argv [argc++] = s;
  
  if (argc)
    execute_command (dbg, argc, argv);
#endif
}


#ifdef USE_TCL
#if 0
void run_tcl_rc_files (dbg_t *dbg)
{
  int i;
  int result;
  char *result_string;
  char buf [200];

  for (i = 0; init_files [i]; i++)
    {
      sprintf (buf, "if [ file isfile \"%s\" ] { source \"%s\" }",
	       init_files [i], init_files [i]);
      result = Tcl_Eval (dbg->tcl_interp, buf);
      result_string = Tcl_GetStringResult (dbg->tcl_interp);
      if (result != TCL_OK)
	fprintf (stderr, "TCL error ");
      if (result_string && strlen (result_string))
	fprintf (stderr, "%s\n", result_string);
    }
}
#endif


void init_tcl (dbg_t *dbg)
{
  cmd_entry *ce;

  dbg->tcl_interp = Tcl_CreateInterp ();
  for (ce = & cmd_table [0]; ce->name != NULL; ce++)
    Tcl_CreateCommand (dbg->tcl_interp,
		       ce->name,
		       ce->handler,
		       dbg, 
		       NULL);
}
#endif


gpointer debugger_thread_func (gpointer data)
{
  dbg_t *dbg;
  char *line = NULL;

  dbg = (dbg_t *) data;

  dbg->in = fdopen (dbg->slave_pty, "r");
  dbg->out = fdopen (dbg->slave_pty, "w");
  dbg->err =  fdopen (dbg->slave_pty, "w");

  fprintf (dbg->out, "Hello, world!\n");

#ifdef USE_READLINE
  rl_instream = dbg->in;
  rl_outstream = dbg->out;
#endif

#ifdef USE_TCL
  init_tcl (dbg);
#if 0
  run_tcl_rc_files (dbg);
#endif
#endif

  for (;;)
    {
#ifdef USE_READLINE
      line = readline (debugger_prompt);
#else
      line = readline (dbg, debugger_prompt);
#endif
      if (line)
	{
	  debugger_command (dbg, line);
	  free (line);
	}
    }

  return (NULL);
}


dbg_t *init_debugger (sim_t *sim)
{
  dbg_t *dbg;
  int master_pty;
  GtkWidget *vte;
  
  dbg = alloc (sizeof (dbg_t));

  dbg->sim = sim;

  if (openpty (& master_pty, & dbg->slave_pty, NULL, NULL, NULL) < 0)
    fatal (2, "can't get PTY\n");

  dbg->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  vte = vte_terminal_new ();

  vte_terminal_add_pty (VTE_TERMINAL (vte), master_pty);

  /* vte_terminal_set_size() must come *after* vte_terminal_add_pty() */
  vte_terminal_set_size (VTE_TERMINAL (vte), 80, 24);

  gtk_container_add (GTK_CONTAINER (dbg->window), vte);

  dbg->thread = g_thread_create (debugger_thread_func, dbg, TRUE, NULL);

  return (dbg);
}

void show_debugger (dbg_t *dbg, gboolean visible)
{
  if (visible)
    gtk_widget_show_all (dbg->window);
  else
    gtk_widget_hide (dbg->window);
}
