#ifndef	_OS_TYPE_H_
#define	_OS_TYPE_H_

typedef	unsigned char	u8;
typedef	unsigned short	u16;
typedef	unsigned int	u32;

typedef	struct p_descriptor
{
	u16	desc_limit_low;
	u16	desc_base_low;
	u8	desc_base_mid;
	u8	desc_attr_low;
	u8	desc_limit_attr_high; /* limit low 4bit   attr high 4bit*/
	u8	desc_base_high;
} DESCRIPTOR;


typedef	struct p_gate
{
	u16	gate_offset_low;
	u16	gate_selector;
	u8	gate_attr_low;
	u8	gate_attr_high;
	u16	gate_offset_high;
} GATE;

#endif
