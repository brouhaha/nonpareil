/*
Copyright 2026 Warren Young <https://tangentsoft.com/rpn>

Nonpareil is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.
*/

#ifndef HEADLESS_H
#define HEADLESS_H

#include <stdbool.h>

/* True when argv contains a headless flag (--mod, --keys, --show, --expect). */
bool headless_requested (int argc, char **argv);

/* Run headless. model is the first non-option argument (e.g. "41cx").
   Returns a process exit status. */
int headless_main (int argc, char **argv);

#endif /* HEADLESS_H */
