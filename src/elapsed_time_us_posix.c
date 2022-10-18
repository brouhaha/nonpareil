/*
Copyright 2022 Eric Smith <spacewar@gmail.com>

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

#include <errno.h>
#include <time.h>

#include "util.h"
#include "elapsed_time_us.h"


#define NSEC_PER_USEC 1000
#define NSEC_PER_SEC 1000000000

#define USEC_PER_SEC 1000000


bool time_initialized = false;
struct timespec start_time;


uint64_t get_elapsed_time_us(void)
{
  struct timespec now;
  if (! time_initialized)
  {
    fatal(3, "get_elapsed_time_us(): not initialized\n");
  }
  if (clock_gettime(CLOCK_MONOTONIC, & now) != 0)
  {
    fatal(3, "get_elapsed_time_us(): clock_gettime() failed, errno %d\n", errno);
  }

  int32_t ns_diff = now.tv_nsec - start_time.tv_nsec;
  int64_t sec_diff = now.tv_sec - start_time.tv_sec;
  if (ns_diff < 0)
  {
    ns_diff += NSEC_PER_SEC;
    sec_diff--;
  }
  if (sec_diff < 0)
  {
    fatal(3, "get_elapsed_time_us(): CLOCK_MONOTONIC decreased\n");
  }

  return sec_diff * USEC_PER_SEC + ns_diff / NSEC_PER_USEC;
}

bool elapsed_time_us_init()
{
  if (time_initialized)
  {
    warning("interval_init() called more than once\n");
    return true;
  }

#if 0
  struct timespec clock_res;

  if (clock_getres(CLOCK_MONOTONIC, & clock_res) != 0)
  {
    fatal(3, "interval_init(): clock_getres() failed, errno %d\n", errno);
  }
  printf("CLOCK_MONOTONIC resolution %d.%09d s\n", clock_res.tv_sec, clock_res.tv_nsec);
#endif

  if (clock_gettime(CLOCK_MONOTONIC, & start_time) != 0)
  {
    fatal(3, "interval_init(): clock_gettime() failed, errno %d\n", errno);
  }

  time_initialized = true;
  return true;
}
