/*
$Id$
Copyright 2006 Eric L. Smith <eric@brouhaha.com>

This is the API for installing and uninstalling mod1 files, and
enumerating the installed mod1 files.

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


typedef struct
{
  uint8_t bank;  // 0x0..0x3
  uint8_t page;  // 0x0..0xf
} page_loc_t;


typedef struct
{
  int page_count;        // 0..255 pages
  page_loc_t *page_loc;  // pointer to array of page_count elements
} mod_loc_t;


// Opaque handle representing an installed module.
typedef struct installed_mod1_t installed_mod1_t;


// Allocated a mod_loc structure with room for page_count pages.
mod_loc_t *alloc_mod_loc (int page_count);

// Free a mod_loc structure.
void free_mod_loc (mod_loc_t *mod_loc);


// Try to find a way to install the module into the specified port
// (1-4, or 0 for hard-addressed somewhere in pages 0-7).  Returns
// NULL if module needs unsupported hardware or if no fit can be
// found.  Othewise returns an allocated structure indicating where
// the mod1 pages fit into the memory map, or NULL if no fit was
// found.  Does not change the simulator state in any way.
// If sim_find_mod1_loc() fails, it may still be possible to install
// the module by carefully crafting an appropriate mod_loc_t structure.
mod_loc_t *sim_find_mod1_loc (sim_t *sim,
			      mod1_t *mod1,
			      int port);


// Install a module given a module location structure.
// The installed module takes ownership of the module location structure.
// The mod1 must remain open as long as the module is installed.
installed_mod1_t *sim_install_mod1 (sim_t *sim,
				    mod1_t *mod1,
				    mod_loc_t *loc);


// Uninstall a module.  Resources are freed, including the module location
// structure.  After the mdule is uninstalled, the caller may close the
// mod1.
bool sim_uninstall_mod1 (installed_mod1_t *im1);


// Enumeration of installed modules:
installed_mod1_t *sim_get_first_installed_mod1 (sim_t *sim);

installed_mod1_t *sim_get_next_installed_mod1 (installed_mod1_t *im1);



// Get the mod1 handle of an installed module.
mod1_t *sim_get_installed_mod1 (installed_mod1_t *im1);


// Get a pointer to the module location structure of an installed
// modoule.  The installed module still retains ownership of the
// module location structure.
mod_loc_t *sim_get_installed_mod1_loc (installed_mod1_t *im1);


