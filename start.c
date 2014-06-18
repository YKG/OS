#define GDT_SIZE		128

typedef	unsigned char	u8;
typedef	unsigned short	u16;
typedef	unsigned int	u32;

typedef struct s_descriptor		/* 共 8 个字节 */
{
	u16	limit_low;		/* Limit */
	u16	base_low;		/* Base */
	u8	base_mid;		/* Base */
	u8	attr1;			/* P(1) DPL(2) DT(1) TYPE(4) */
	u8	limit_high_attr2;	/* G(1) D(1) 0(1) AVL(1) LimitHigh(4) */
	u8	base_high;		/* Base */
}DESCRIPTOR;


u8			gdt_ptr[6];
DESCRIPTOR	gdt[GDT_SIZE];


void * MemCopy(void *dest, void *src, int size);
void DispString();

void cstart()
{	
	u16 * gdt_limit = (u16 *)(&gdt_ptr[0]);
	u32 * gdt_base  = (u32 *)(&gdt_ptr[2]);
	
	MemCopy((void *)gdt, 
			(void *)(*(u32 *)(&(gdt_ptr[2]))),
			(*(u16 *)gdt_ptr) + 1);

	*gdt_limit = GDT_SIZE*(sizeof(DESCRIPTOR)) - 1;
	*gdt_base  = (u32)gdt;
	

	DispString("\n\n\nHello, world!");
	DispString("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
				"======== cstart =========");
}




