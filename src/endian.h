#ifndef ENDIAN_H
#define ENDIAN_H

// Copyright 2022 Eric Smith <spacewar@gmail.com>

bool host_is_big_endian(void);

uint16_t le_to_h_u16(uint16_t v);
uint32_t le_to_h_u32(uint32_t v);

#endif // ENDIAN_H
