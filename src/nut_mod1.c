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


#include "mod1_file.h"
#include "nut_mod1.h"


// Opaque handle representing an installed module.
struct installed_mod1_t
{
  struct installed_mod1_t *next;  // the next installed module
  mod1_t *mod1;                   // the mod1 file handle
  mod_loc_t *loc;                 // where the module is mapped into memory
}


// Allocated a mod_loc structure with room for page_count pages.
mod_loc_t *alloc_mod_loc (int pages)
{
  mod_loc_t *mod_loc;

  mod_loc = calloc (1, sizeof (mod_loc_t));
  if (! mod_loc)
    return NULL;

  mod_loc->page_loc = calloc (pages, sizeof (page_loc_t));
  if (! mod_loc->page_loc)
    {
      free (mod_loc);
      return NULL;
    }

  mod_loc->page_count = page_count;
  return mod_loc;
}


// Free a mod_loc structure.
void free_mod_loc (mod_loc_t *mod_loc)
{
  free (mod_loc->page_loc);
  free (mod_loc);
}


static bool supported_hardware (sim_t *sim UNUSED,
				uint8_t hardware)
{
  bool status = false;

  switch (hardware)
    {
    case MOD1_HARDWARE_NONE:
    case MOD1_HARDWARE_TIMER:
    case MOD1_HARDWARE_PRINTER:
      status = true;
      break;
    default:
      status = false;
      break;

    }
  return status;
}


static bool sim_install_mod1_hardware (sim_t *sim, uint8_t hardware)
{
  bool status = false;

  switch (hardware)
    {
    case MOD1_HARDWARE_NONE:
      status = true;
      break;

    case MOD1_HARDWARE_TIMER:
      (void) sim_add_chip (sim, CHIP_PHINEAS, NULL, NULL);
      status = true;
      break;

    case MOD1_HARDWARE_PRINTER:
      sim->install_hardware_callback (sim->install_hardware_callback_ref, CHIP_HELIOS);
      status = true;
      break;

    default:
      if ((header.Hardware <= MOD1_HARDWARE_MAX) &&
	  mod1_hardware_name [header.Hardware])
	fprintf (stderr, "Unsupported hardware: %s\n",
		 mod1_hardware_name [header.Hardware]);
      else
	fprintf (stderr, "Unsupported hardware type %d\n",
		 header.Hardware);
#if 0
      status = true;  // for debugging, allow unsupported hardware
#endif
    }
  return status;
}


struct page_assignment_t
{
  bool assigned_phys_pages [16][4];
  int bank_group [MOD1_MAX_BANK_GROUP + 1];  // index from 1 .. MOD1_MAX_BANK_GROUP,
                                             // entry 0 not used
};

typdef bool page_number_validate_fn_t (int page_number,
				       int bank_number,
				       page_assignment_t *pa);


static bool check_even (int page_number,
			int bank_number UNUSED,
			page_assignment_t *pa UNUSED)
{
  return (page_number & 1) == 0;
}

static bool check_odd (int page_number,
		       int bank_number UNUSED,
		       page_assignment_t *pa UNUSED)
{
  return (page_number & 1) == 1;
}


// If requested page is non-negative, return that page number if it
// is suitable and available; otherwise return -1.
// If requested page is negative, try to find a suitable page.
bool find_suitable_page (int requested_page,  // 0x0..0xf, or -1
			 int requested_bank,  // 0..3
			 page_assignment_t *pa,
			 int first,
			 int last,
			 page_number_validate_fn_t *validate_fn,
			 int *assigned_page,
			 int *assigned_bank)
{
  int page;

  if (requested_page > 0xf)
    return false;

  if ((requested_bank < 0) || (requested_bank > 3))
    return false;

  if (requested_page >= 0)
    {
      if (requested_bank < 0)
	requested_bank = 0;
      if ((requested_page >= first) &&
	  (requested_page <= last) &&
	  (! pa->assigned_phys_pages [requested_page][requested_bank]) &&
	  validate_fn (requested_page, requested_bank))
	{
	  *assigned_page = requested_page;
	  *assigned_bank = requested_bank;
	}
      else
	return false;
    }

  for (page = first; page <= last; page++)
    {
      if ((! pa->asigned_phys_pages [page][requested_bank]) &&
	  validate_fn (page, requested_bank))
	{
	  *assigned_page = page;
	  *assigned_bank = requested_bank;
	  return true;
	}
    }

  return false;
}


// Attempt to find suitable page and bank number assignments for all
// the ROM pages of a MOD1.  Note:  does not actually change simulation
// state in any way.
bool sim_mod1_assign_mem_pages (sim_t *sim,
				mod1_t *m1,
				page_assignment_t *pa,
				uint8_t min_page,
				uint8_t max_page,
				int *requested_mem_pages,
				int *requested_mem_banks,
				int *assigned_mem_pages,
				int *assigned_mem_banks)
{
  mod1_module_info_t *mi;
  int i;
  bool status = false;

  mi = mod1_get_module_info (m1);
  if (! mi)
    goto error;

  for (i = 0; i < mi->num_pages; i++)
    {
      mod1_page_info_t *mp;
      int requested_page = -1;
      int requested_bank = -1;
      int selected_page = -1;
      int selected_bank = -1;

      if (requested_mem_pages && requested_mem_banks)
	{
	  requested_page = requested_mem_pages [i];
	  requested_bank = requested_mem_banks [i];
	}

      mp = mod1_get_page_info (m1, i);
      if (! mp)
	goto error;

      if (mp->page <= 0x0f)
	{
	  selected_page = mp->page;
	  selected_bank = mp->bank - 1;  // our bank numbers are 0..3
	  if ((requested_page >= 0) && (requested_page != selected_page))
	    goto error;
	  if ((requested_bank >= 0) && (requested_bank != selected_bank))
	    goto error;
	}
      else
	{
	  page_number_validate_fn_t *validate_fn = NULL;
	  switch (mp->page)
	    {
	    case MOD1_POSITION_ANY:
	      break;

	    case MOD1_POSITION_EVEN:
	      validate_fn = check_even;
	      break;

	    case MOD1_POSITION_ODD:
	      validate_fn = check_odd;
	      break;

	    case MOD1_POSITION_LOWER:
	      validate_fn = check_lower;
	      break;

	    case MOD1_POSITION_UPPER:
	      validate_fn = check_upper;
	      break;

	    default:
	      // not a supported MOD1_POSITION_xxx
	      goto error;
	    }

	  find_suitable_page (requested_page,
			      requested_bank,
			      pa,
			      min_page,
			      max_page,
			      validate_fn,
			      & selected_page,
			      & selected_bank);
	}

      if ((selected_page < 0x0) ||
	  (selected_page > 0xf) ||
	  (selected_bank < 0) ||
	  (selected_bank > 3))
	goto error;
      if (pa->assigned_phys_pages [selected_page][selected_bank])
	goto error;
      assigned_mem_pages [i] = selected_page;
      assigned_mem_banks [i] = selected_bank;
      pa->assigned_phys_pages [selected_page][selected_bank] = true;
    }

 error:
  return status;
}


struct installed_mod1_t
{
};


// Install the module into the specified port (1-4, or 0 for hard-addressed
// somewhere in pages 0-7).  If preflight is true, only determine whether it
// will be possible to do the installation, but don't actually install it
// or change the simulator state in any way.
bool sim_mod1_install_simple (sim_t *sim,
			      bool preflight,
			      mod1_t *mod1,
			      int port
			      installed_mod1_t **im1)
{
  bool status = false;
  int i;
  uint8_t min_page;
  uint8_t max_page;

  page_assignment_t pa;
  int8_t assigned_mem_pages [255];
  int8_t assigned_mem_banks [255];

  switch (port)
    {
    case 0:  min_page = 0x0;  max_page = 0x7;  break;
    case 1:  min_page = 0x8;  max_page = 0x9;  break;
    case 2:  min_page = 0xa;  max_page = 0xb;  break;
    case 3:  min_page = 0xc;  max_page = 0xd;  break;
    case 4:  min_page = 0xe;  max_page = 0xf;  break;
    default:  goto done;  // bad port number
    }

  for (i = 0; i < 255; i++)
    {
      assigned_mem_pages [i] = -1;
      assigned_mem_banks [i] = -1;
    }

  memset (pa, 0, sizeof (pa));
  for (i = 0; i < 16; i++)
    for (i = 0; i < 4; i++)
      pa->assigned_phys_pages [i][j] = sim_page_exists (sim, j, i);

  mi = mod1_get_module_info (mod1);
  if (! mi)
    goto done;

  // Phase 1: does the module need any unsupported hardware?
  if (mi->hardware)
    {
      status = supported_hardware (sim, mi->hardware);
      if (! status)
	goto done;
    }

  // Phase 2: figure out where each ROM page will be loaded
  status = sim_mod1_assign_mem_pages (sim,
				      mod1,
				      & pa,
				      min_page,
				      max_page,
				      requested_mem_pages,
				      requested_mem_banks,
				      assigned_mem_pages,
				      assigned_mem_banks);
  if (! status)
    goto done;

  if (preflight)
    goto done;

  // Phase 3: install hardware
  // Ideally we'd like to ensure that no errors can occur in this
  // function AFTER the hardware has been installed, so that we don't
  // have to worry about deinstalling it.
  if (mi->hardware)
    {
      status = sim_install_mod1_hardware (sim, mi->hardware);
      if (! status)
	goto done;  // should never happen!
    }

  // Phase 4: install ROM pages
  for (i = 0; i < mi->num_pages; i++)
    {
      uint16_t addr;
      mod1_page_info_t *pi;

      pi = mod1_get_page_info (mod1, i);
      if (pi->bank_group)
	{
	  if (! pa->bank_group [pi->bank_group])
	    bank_group [pi->bank_group] = sim_create_bank_group (sim);
	  sim_set_bank_group (sim, 
			      bank_group [pi->bank_group],
			      assigned_mem_pages [i] << 12);
	}

      for (addr = 0x000; addr <= 0xfff; addr++)
	{
	  if ((mod1_get_rom_word (mod1, i, addr, & data) != MOD1_STATUS_OK) ||
	      (! sim_write_rom (sim,
				assigned_mem_banks [i],
				assigned_mem_pages [i] << 12 + addr,
				& data)))
	    {
	      fprintf (stderr, "Can't load ROM word at bank %d address %o\n", bank, addr);
	      goto done;
	    }
	}
    }

  status = true;

 done:
  return status;
}


// Install a module, using specific memory pages as specified by the arrays
// requested_mem_pages and requested_mem_banks.  If preflight is true, only
// determine whether it will be possible to do the installation, but don't
// actually install it or change the simulator state in any way.
bool sim_mod1_install_expert (sim_t *sim,
			      bool preflight,
			      mod1_t *mod1,
			      int *requested_mem_pages,
			      int *requested_mem_banks,
			      installed_mod1_t **im1)
{
}
			      

bool sim_mod1_uninstall (sim_t *sim,
			 installed_mod1_t *im1)
{
}
