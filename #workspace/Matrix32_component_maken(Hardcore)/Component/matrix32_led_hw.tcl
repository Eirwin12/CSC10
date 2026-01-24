# ==============================================================================
# TCL Script voor Platform Designer Component Definitie
# Matrix32_LED - 32x32 RGB LED Matrix Controller
# Voor DE1-SoC (Altera Cyclone V)
# ==============================================================================

package require -exact qsys 16.0

# ==============================================================================
# Module Properties
# ==============================================================================
set_module_property NAME matrix32_led
set_module_property DISPLAY_NAME "32x32 RGB LED Matrix Controller"
set_module_property VERSION 1.0
set_module_property GROUP "CSC10 Custom Components"
set_module_property DESCRIPTION "Controller for 32x32 RGB LED Matrix with HUB75 interface and multiplexing support"
set_module_property AUTHOR "Mitch - CSC10 Project"
set_module_property COMPOSITION_CALLBACK compose
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true

# ==============================================================================
# File Sets - VHDL Source Files
# ==============================================================================

# Quartus Synthesis Fileset
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL Matrix32_LED_avalon
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file Matrix32_LED_avalon.vhd VHDL PATH hdl/Matrix32_LED_avalon.vhd TOP_LEVEL_FILE
add_fileset_file Matrix32_LED.vhd VHDL PATH hdl/Matrix32_LED.vhd

# Simulation Fileset (ModelSim)
add_fileset SIM_VHDL SIM_VHDL "" ""
set_fileset_property SIM_VHDL TOP_LEVEL Matrix32_LED_avalon
set_fileset_property SIM_VHDL ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VHDL ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file Matrix32_LED_avalon.vhd VHDL PATH hdl/Matrix32_LED_avalon.vhd
add_fileset_file Matrix32_LED.vhd VHDL PATH hdl/Matrix32_LED.vhd

# ==============================================================================
# Parameters (future expansion - PWM, color depth, etc.)
# ==============================================================================
# add_parameter ENABLE_PWM INTEGER 0
# set_parameter_property ENABLE_PWM DISPLAY_NAME "Enable PWM Brightness Control"
# set_parameter_property ENABLE_PWM AFFECTS_GENERATION false
# set_parameter_property ENABLE_PWM HDL_PARAMETER true

# ==============================================================================
# Avalon Clock Interface
# ==============================================================================
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock csi_clk clk Input 1

# ==============================================================================
# Avalon Reset Interface (synchronous, active-low)
# ==============================================================================
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset rsi_reset_n reset_n Input 1

# ==============================================================================
# Avalon Memory-Mapped Slave Interface
# 
# Address Map:
#   0x00 (offset 0): CONTROL   - [0]: Enable, [1]: Mode
#   0x04 (offset 1): PATTERN   - [2:0]: Test pattern select
#   0x08 (offset 2): FB_ADDR   - [11:0]: Framebuffer address
#   0x0C (offset 3): FB_DATA   - [7:0]: Framebuffer data
#   0x10 (offset 4): STATUS    - [Read-only] Component status
# ==============================================================================
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits WORDS
set_interface_property avalon_slave associatedClock clock
set_interface_property avalon_slave associatedReset reset
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits WORDS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave maximumPendingWriteTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

# Avalon slave ports
add_interface_port avalon_slave avs_s0_address address Input 3
add_interface_port avalon_slave avs_s0_write write Input 1
add_interface_port avalon_slave avs_s0_writedata writedata Input 32
add_interface_port avalon_slave avs_s0_read read Input 1
add_interface_port avalon_slave avs_s0_readdata readdata Output 32
add_interface_port avalon_slave avs_s0_chipselect chipselect Input 1

# Software assignments for BSP
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0

# ==============================================================================
# Conduit Interface - External LED Matrix Signals (HUB75 Protocol)
# 
# These signals are exported to top-level and connected to GPIO pins
# HUB75 Interface:
#   - R1, G1, B1: RGB data for upper half (rows 1-16)
#   - R2, G2, B2: RGB data for lower half (rows 17-32)
#   - A, B, C, D: 4-bit row address (16 multiplexed rows)
#   - CLK: Shift clock for LED driver chips
#   - LAT: Latch signal (transfer data to output)
#   - OE: Output Enable (active-low)
# ==============================================================================
add_interface led_matrix conduit end
set_interface_property led_matrix associatedClock clock
set_interface_property led_matrix associatedReset reset
set_interface_property led_matrix ENABLED true
set_interface_property led_matrix EXPORT_OF ""
set_interface_property led_matrix PORT_NAME_MAP ""
set_interface_property led_matrix CMSIS_SVD_VARIABLES ""
set_interface_property led_matrix SVD_ADDRESS_GROUP ""

# RGB Data Signals - Upper Half
add_interface_port led_matrix coe_matrix_R1 R1 Output 1
add_interface_port led_matrix coe_matrix_G1 G1 Output 1
add_interface_port led_matrix coe_matrix_B1 B1 Output 1

# RGB Data Signals - Lower Half
add_interface_port led_matrix coe_matrix_R2 R2 Output 1
add_interface_port led_matrix coe_matrix_G2 G2 Output 1
add_interface_port led_matrix coe_matrix_B2 B2 Output 1

# Row Address Signals (4-bit = 16 rows)
add_interface_port led_matrix coe_matrix_A A Output 1
add_interface_port led_matrix coe_matrix_B B Output 1
add_interface_port led_matrix coe_matrix_C C Output 1
add_interface_port led_matrix coe_matrix_D D Output 1

# Control Signals
add_interface_port led_matrix coe_matrix_CLK CLK Output 1
add_interface_port led_matrix coe_matrix_LAT LAT Output 1
add_interface_port led_matrix coe_matrix_OE OE Output 1

# ==============================================================================
# Composition Callback (empty for basic component)
# Can be used for advanced features like:
# - Adding sub-components
# - Connecting internal buses
# - Dynamic generation based on parameters
# ==============================================================================
proc compose { } {
    # No sub-components needed for this design
}

# ==============================================================================
# End of TCL Script
# ==============================================================================
