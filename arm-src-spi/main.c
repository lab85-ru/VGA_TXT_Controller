//==============================================================================
// ПО Тест VGA адаптера
//==============================================================================

#include <stdint.h>
#include <string.h>
#include "main.h"
#include "hardware.h"
#include "vga.h"


#ifndef DEBUG
#define DEBUG 0
#endif

const char str_test[] = {"Test"};
const char txt_test_string[] = {"... TEST SPI interface to VGA COLOR ..."};

const uint8_t color_char_table[] = {
    0,
    VGA_CHAR_COLOR_RED, 
    VGA_CHAR_COLOR_GREEN,
    VGA_CHAR_COLOR_BLUE, 
    VGA_CHAR_COLOR_RED  | VGA_CHAR_COLOR_GREEN,
    VGA_CHAR_COLOR_RED  | VGA_CHAR_COLOR_BLUE, 
    VGA_CHAR_COLOR_BLUE | VGA_CHAR_COLOR_GREEN,
    VGA_CHAR_COLOR_RED  | VGA_CHAR_COLOR_BLUE | VGA_CHAR_COLOR_GREEN
};

const uint8_t color_background_table[] = {
    0,
    VGA_BACKGROUND_COLOR_RED, 
    VGA_BACKGROUND_COLOR_GREEN,
    VGA_BACKGROUND_COLOR_BLUE, 
    VGA_BACKGROUND_COLOR_RED  | VGA_BACKGROUND_COLOR_GREEN,
    VGA_BACKGROUND_COLOR_RED  | VGA_BACKGROUND_COLOR_BLUE, 
    VGA_BACKGROUND_COLOR_BLUE | VGA_BACKGROUND_COLOR_GREEN,
    VGA_BACKGROUND_COLOR_RED  | VGA_BACKGROUND_COLOR_BLUE | VGA_BACKGROUND_COLOR_GREEN
};
                                    

//******************************************************************************
// MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN MAIN
//******************************************************************************
int main(void)
{
    uint32_t i;
    uint8_t res;
    

vga__get:    
    res = vga_get_status();
    printf_d("VGA status = 0x%02X\n", res );

    if (res != 0xa1) {
        printf_d("WARNING: Video adapter not present !\n");
        delay_ms(1000);
        goto vga__get;
    } else { 
        printf_d("VGA present - OK.\n");
    }
    
    vga_set_cursor_visible(0); // OFF
    vga_set_color(VGA_CHAR_COLOR_RED | VGA_CHAR_COLOR_GREEN | VGA_CHAR_COLOR_BLUE);
    vga_clr();

    vga_set_xy(34, 0);
    vga_set_color(VGA_BACKGROUND_COLOR_RED | 
                  VGA_BACKGROUND_COLOR_BLUE | 
                  VGA_BACKGROUND_COLOR_GREEN | 
                  VGA_CHAR_COLOR_RED);
    fprintf(vga_p, "V");
    vga_set_color(VGA_BACKGROUND_COLOR_RED | 
                  VGA_BACKGROUND_COLOR_BLUE | 
                  VGA_BACKGROUND_COLOR_GREEN | 
                  VGA_CHAR_COLOR_GREEN);
    fprintf(vga_p, "G");
    vga_set_color(VGA_BACKGROUND_COLOR_RED | 
                  VGA_BACKGROUND_COLOR_BLUE | 
                  VGA_BACKGROUND_COLOR_GREEN | 
                  VGA_CHAR_COLOR_BLUE);
    fprintf(vga_p, "A");
    vga_set_color(VGA_CHAR_COLOR_RED |
                  VGA_CHAR_COLOR_GREEN |
                  VGA_CHAR_COLOR_BLUE);
    fprintf(vga_p, " FPGA - TXT Color controller.");
    
    vga_set_xy(34, 1);
    fprintf(vga_p, "V2.0 2023 info@lab85.ru Sviridov Georgy.");
    
    
    vga_set_xy(0, 24);
    vga_set_color(VGA_CHAR_COLOR_RED |
                  VGA_CHAR_COLOR_GREEN |
                  VGA_CHAR_COLOR_BLUE );
    fprintf(vga_p, "Test: STM32F030 Discovery -> SPI -> FPGA VGA.");
    
    uint8_t blink = 0;
    
    for (uint8_t b=0; b<2; b++) {
        for (uint8_t j=0; j<sizeof(color_background_table); j++) {
            if (b) 
                blink = VGA_CHAR_BLINK;
            else 
                blink = 0;
        
            for (uint8_t i=0; i<sizeof(color_char_table); i++) {
                vga_set_xy(j * strlen(str_test), i + b * sizeof(color_background_table));
                printf_d("x = %d, y = %d\n", j * strlen(str_test) + b * (sizeof(color_background_table) + strlen(str_test)), i);
                vga_set_color( blink | color_background_table[j] | color_char_table[i] );
                fprintf(vga_p, "%s", str_test);
            }
        }
    }
    
    vga_set_xy(72, 24);
    vga_set_color( VGA_CHAR_COLOR_RED | VGA_CHAR_COLOR_GREEN | VGA_CHAR_COLOR_BLUE );
    fprintf(vga_p, "Работа:");
    
    uint8_t color_index = 0;
    uint8_t color_index_prev = 0;
    while(1) {

        for (uint8_t i=0; i<strlen(txt_test_string); i++) {
            vga_set_xy(10 + i, 18);
            vga_set_color( color_char_table[color_index] );
            fprintf(vga_p, "%c", txt_test_string[i]);

            vga_set_xy(10 + i, 18 + 1);
            vga_set_color( (color_background_table[color_index] << 4) | 0);
            fprintf(vga_p, "%c", txt_test_string[i]);

            color_index_prev = color_index;
            
            color_index++;
            if (color_index == sizeof(color_char_table)) color_index = 0;
            
            
            vga_set_xy(79, 24);
            vga_set_color( VGA_CHAR_COLOR_RED | VGA_CHAR_COLOR_GREEN | VGA_CHAR_COLOR_BLUE );
            switch (color_index) {
            case 0: 
                fprintf(vga_p, "|");
                break;
            case 1: 
                fprintf(vga_p, "/"); 
                break;
            case 2: 
                fprintf(vga_p, "-"); 
                break;
            case 3: 
                fprintf(vga_p, "\\"); 
                        break;
            case 4:
                fprintf(vga_p, "|"); 
                break;
            case 5: 
                fprintf(vga_p, "/");
                break;
            case 6: 
                fprintf(vga_p, "-");
                break;
            case 7: 
                fprintf(vga_p, "\\");
                break;
            default: break;
            }
            
            delay_ms(10);
        } 
        
      
    }// while ------------------------------------------------------------------

    
    while(1);
}
