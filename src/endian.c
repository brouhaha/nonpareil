// Copyright 2022 Eric Smith <spacewar@gmail.com>

#include <stdbool.h>
#include <stdint.h>

#include "endian.h"

static const int one = 1;

bool host_is_big_endian(void)
{
  return *((const char *) & one) == 0;
}

uint16_t le_to_h_u16(uint16_t v)
{
  if (! host_is_big_endian())
    return v;
  return (((v << 8) & 0xff00) |
	  ((v >> 8) & 0x00ff));
}

uint32_t le_to_h_u32(uint32_t v)
{
  if (! host_is_big_endian())
    return v;
  return (((v << 24) & 0xff000000) |
	  ((v <<  8) & 0x00ff0000) |
	  ((v >>  8) & 0x0000ff00) |
	  ((v >> 24) & 0x000000ff));
}


