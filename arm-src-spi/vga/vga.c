#include <stdint.h>
#include <string.h>
#include "main.h"
#include "vga.h"

#ifndef DEBUG
#define DEBUG 0
#endif

//------------------------------------------------------------------------------
// SPI CS = 0
//------------------------------------------------------------------------------
void set_cs_l(void)
{
    spi1_cs(0);
}

//------------------------------------------------------------------------------
// SPI CS = 1
//------------------------------------------------------------------------------
void set_cs_h(void)
{
    spi1_cs(1);
}

//------------------------------------------------------------------------------
// SPI RX-TX, 1-byte
//------------------------------------------------------------------------------
uint8_t spi_byte(const uint8_t outdat)
{
    uint8_t b;
        
    b = spi1_txrx(outdat);

	return b;
}

//------------------------------------------------------------------------------
// read vga adres cursor
//------------------------------------------------------------------------------
uint16_t vga_get_cur_adr( void )
{
    uint8_t l = 0;
    uint8_t h = 0;

    set_cs_l();
	spi_byte(VGA_CMD_R_CUR_AH);
    spi_byte(0);
	h = spi_byte(0);
    set_cs_h();

    set_cs_h();
    set_cs_h();
    set_cs_h();
    
    set_cs_l();
	spi_byte(VGA_CMD_R_CUR_AL);
    spi_byte(0);
	l = spi_byte(0);
    set_cs_h();
    
    return (h << 8) | l;
}


//------------------------------------------------------------------------------
// read vga status - return 0xa1 is OK
//------------------------------------------------------------------------------
uint8_t vga_get_status( void )
{
    uint16_t t;

    set_cs_l();
    
	spi_byte(VGA_CMD_R_STATUS);
    spi_byte(0);
	t = spi_byte(0);
    
    set_cs_h();
    
    return t & 0xff;
}

//------------------------------------------------------------------------------
// Write char to pos Cursor
//------------------------------------------------------------------------------
void vga_print_char( const char c )
{
    uint16_t ca = 0; // cursor adr
    
    if (c == '\r'){
        ca = vga_get_cur_adr();
        ca &= (~(VGA_RESOLUTION_X-1));
        vga_set_cur_pos(ca);
        return;
    }
    
    if (c == '\n'){
        ca = vga_get_cur_adr();
        ca = ca & (~(VGA_RESOLUTION_X-1));
        ca = ca + VGA_RESOLUTION_X;
        vga_set_cur_pos(ca);
        return;
    }
        
    set_cs_l();
	spi_byte(VGA_CMD_W_DATA);
    spi_byte(c);
    set_cs_h();
}

//------------------------------------------------------------------------------
// Write char to pos Cursor
//------------------------------------------------------------------------------
void vga_p( const unsigned char c )
{
    vga_print_char( c );
}

//------------------------------------------------------------------------------
// Write Cursor position
//------------------------------------------------------------------------------
void vga_set_cur_pos( const uint16_t xy )
{
    set_cs_l();
    
	spi_byte(VGA_CMD_W_CUR_ADR);
    spi_byte((xy >> 8) & 0xff);
    spi_byte((xy >> 0) & 0xff);

    set_cs_h();
}

//------------------------------------------------------------------------------
// Cursor visible - enable/disable
//------------------------------------------------------------------------------
void vga_set_cursor_visible( const uint8_t v )
{
    set_cs_l();
    
	spi_byte(VGA_CMD_W_CONTROL);
    if (v)
        spi_byte(VGA_REG_CONTROL_BIT_CURSOR);
    else
        spi_byte(0);

    set_cs_h();
}

//------------------------------------------------------------------------------
// Write Cursor position
//------------------------------------------------------------------------------
void vga_set_xy( uint8_t x, uint8_t y )
{
    uint16_t adr = 0;
    
    if (x > VGA_RESOLUTION_X - 1) x = VGA_RESOLUTION_X - 1;
    if (y > VGA_RESOLUTION_Y - 1) y = VGA_RESOLUTION_Y - 1;
    
    adr = y * VGA_RESOLUTION_X + x;
    
    vga_set_cur_pos( adr );

}

//------------------------------------------------------------------------------
// Clear frame
//------------------------------------------------------------------------------
void vga_clr(void)
{
    int i;

    vga_set_xy( 0,0 );
    for (i=0; i<VGA_RESOLUTION_X*VGA_RESOLUTION_Y; i++){
        vga_print_char(' ');
    }
    vga_set_xy( 0, 0 );
}

//------------------------------------------------------------------------------
// Set color (char + background)
//------------------------------------------------------------------------------
void vga_set_color( const uint8_t color )
{
    set_cs_l();
    
	spi_byte(VGA_CMD_W_COLOR);
    spi_byte(color);

    set_cs_h();
}

