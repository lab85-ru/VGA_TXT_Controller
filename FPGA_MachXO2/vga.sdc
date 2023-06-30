#=======================================================================
# Задали клоки
create_clock -period 39.72 [get_ports i_clk]
create_clock -period 50 [get_ports i_spi_sck]

# Клоки между собой асинхронны
set_false_path -from [get_clocks {i_clk}] -to [get_clocks {i_spi_sck}]
set_clock_groups -exclusive -group {i_clk} -group {i_spi_sck}

