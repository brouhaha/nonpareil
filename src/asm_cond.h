#ifndef ASM_COND_H
#define ASM_COND_H

void cond_init(void);

bool get_cond_state(void);

int get_cond_nest_level(void);

void pseudo_if(int val);
void pseudo_ifdef(char *s);
void pseudo_ifndef(char *s);
void pseudo_else(void);
void pseudo_elseif(int val);
void pseudo_endif(void);

#endif // ASM_COND_H
