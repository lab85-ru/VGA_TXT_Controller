#ifndef VGA_H_
#define VGA_H_
#include <stdint.h>

#define VGA_REG_STATUS_BIT_READY    (1 << 0)
#define VGA_REG_CONTROL_BIT_CURSOR  (1 << 0)


//  7 6 5 4 3 2 1 0
//  M B G R - B G R
//  | | | | | | | |
//  | | | | | | | +-- CHAR COLOR RED
//  | | | | | | +---- CHAR COLOR GREEN
//  | | | | | +------ CHAR COLOR BLUE
//  | | | | +-------- clear
//  | | | +---------- background RED
//  | | +------------ background GREEN
//  | +-------------- background BLUE
//  +---------------- CHAR BLINK
#define VGA_CHAR_COLOR_RED   (1 << 0)
#define VGA_CHAR_COLOR_GREEN (1 << 1)
#define VGA_CHAR_COLOR_BLUE  (1 << 2)

#define VGA_BACKGROUND_COLOR_RED   (1 << 4)
#define VGA_BACKGROUND_COLOR_GREEN (1 << 5)
#define VGA_BACKGROUND_COLOR_BLUE  (1 << 6)

#define VGA_CHAR_BLINK       (1 << 7)

//--------------------------------------------------------------------
#define VGA_CMD_R_STATUS    (0x00) // read status
#define VGA_CMD_R_CONTROL   (0x04) // read control
#define VGA_CMD_R_CUR_AL    (0x02) // read cursor low adr 
#define VGA_CMD_R_CUR_AH    (0x03) // read cursor high adr 

#define VGA_CMD_W_STATUS    (0x80) // write to status
#define VGA_CMD_W_CONTROL   (0x84) // write to control
#define VGA_CMD_W_DATA      (0x81) // write data to position cursor
#define VGA_CMD_W_CUR_ADR   (0x82) // write adress cursor
#define VGA_CMD_W_COLOR     (0x85) // write to COLOR

// VGA Controller resolution
//#define VGA_RESOLUTION_X    (64)
//#define VGA_RESOLUTION_Y    (30)
#define VGA_RESOLUTION_X    (80)
#define VGA_RESOLUTION_Y    (25)

void set_cs_l( void );
void set_cs_h( void );

uint8_t vga_get_status( void );
void vga_print_char( const char c );
void vga_p( const unsigned char c );
void vga_set_cursor_visible( const uint8_t v );
void vga_set_cur_pos( const uint16_t xy );
void vga_set_xy( uint8_t x, uint8_t y );
void vga_clr(void);
uint16_t vga_get_cur_adr( void );
void vga_set_color( const uint8_t color );

#endif
