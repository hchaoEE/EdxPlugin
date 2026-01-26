set_cfg plan.stripe.bottom_layer M1
set_cfg plan.stripe.top_layer M2

route_special_net -nets {VDD VSS} -connect follow_pin -follow_pin_target first_after_row_end -enable_jogging 1 -enable_multi_layer 1 -follow_pin_layer M1

set var(std_cell_overlay_rail_width) 0.072
set var(std_cell_overlay_rail_layer) M2
set var(insert_std_cell_rail_vias) 1
set var(std_cell_rail_via_step) 0.5
set var(row_height) 1.08

set_cfg plan.stripe.bottom_layer M1
set_cfg plan.stripe.top_layer M2
set_cfg plan.via_gen.ignore_enclosure true

create_power_stripe -direction horizontal -space_of_groups [expr $var(row_height) * 2] -spacing [expr $var(row_height) - $var(std_cell_overlay_rail_width)] -width $var(std_cell_overlay_rail_width) -nets [list VDD VSS] -layer M2 -start_offset -[expr $var(std_cell_overlay_rail_width) * 0.5] -start_edge bottom


#edit_pg_via -bottom_layer M1 -create_via 1 -top_layer M2 -disable_parallel_connect 0 -ignore_pin follow_pin

#set_cfg plan.via_gen.priority_via_rule { M6_M5widePWR1p152 M5_M4widePWR0p864 M4_M3widePWR0p864 }


set m3pwrwidth [expr 0.072 * (5 + (4 * 2))]
set m3pwrset2settracks  320
set m3pwrset2setdist    [expr $m3pwrset2settracks * 0.144]
set m3pwrspacing [expr 0.072 * 189]
set m3pwrxoffset [expr (0.072 * 26) + 0.036]

set_cfg plan.stripe.bottom_layer M2
set_cfg plan.stripe.top_layer M3
create_power_stripe -direction vertical -space_of_groups $m3pwrset2setdist -spacing $m3pwrspacing -nets [list VDD VSS] -layer M3 -start_offset $m3pwrxoffset -width $m3pwrwidth -start_edge left


set m4pwrwidth [expr 0.096 * (5 + (4 * 1))]
set m4pwrset2settracks  320
set m4pwrset2setdist    [expr $m4pwrset2settracks * 0.192]
set m4pwrspacing [expr 0.096 * 189]
set m4pwrxoffset [expr (0.096 * 26) - 0.036]

set_cfg plan.stripe.bottom_layer M3
set_cfg plan.stripe.top_layer M4
create_power_stripe -direction horizontal -space_of_groups $m4pwrset2setdist -spacing $m4pwrspacing -nets [list VDD VSS] -layer M4 -start_offset $m4pwrxoffset -width $m4pwrwidth -start_edge bottom


set m5pwrwidth [expr 0.096 * (5 + (4 * 1))]
set m5pwrset2settracks  320
set m5pwrset2setdist    [expr $m5pwrset2settracks * 0.192]
set m5pwrspacing [expr 0.096 * 189]
set m5pwrxoffset [expr (0.096 * 70) + 0.024 ]

set_cfg plan.stripe.bottom_layer M4
set_cfg plan.stripe.top_layer M5
create_power_stripe -direction vertical -space_of_groups $m5pwrset2setdist -spacing $m5pwrspacing -nets [list VDD VSS] -layer M5 -start_offset $m5pwrxoffset -width $m5pwrwidth -start_edge left

set m6pwrwidth [expr 0.128 * (5 + (4 * 1))]
set m6pwrset2settracks  320
set m6pwrset2setdist    [expr $m6pwrset2settracks * 0.256]
set m6pwrspacing [expr 0.128 * 189]
set m6pwrxoffset [expr (0.128 * 50) + 0.008 ]

set_cfg plan.stripe.bottom_layer M5
set_cfg plan.stripe.top_layer M6
create_power_stripe -direction horizontal -space_of_groups $m6pwrset2setdist -spacing $m6pwrspacing -nets [list VDD VSS] -layer M6 -start_offset $m6pwrxoffset -width $m6pwrwidth -start_edge bottom -extend_to design_boundary

set m7pwrwidth [expr 0.128 * (5 + (4 * 1))]
set m7pwrset2settracks  320
set m7pwrset2setdist    [expr $m7pwrset2settracks * 0.256]
set m7pwrspacing [expr 0.128 * 189]
set m7pwrxoffset [expr (0.128 * 70) + 0.008 ]

set_cfg plan.stripe.bottom_layer M6
set_cfg plan.stripe.top_layer M7
create_power_stripe -direction vertical -space_of_groups $m7pwrset2setdist -spacing $m7pwrspacing -nets [list VDD VSS] -layer M7 -start_offset $m7pwrxoffset -width $m7pwrwidth -start_edge left -extend_to design_boundary

set pwrset2setdist "10"
set pwrspacing "2"
set pwrxoffset "1"
set pwrwidth "3"
set layer "M8"
set_cfg plan.stripe.bottom_layer M7
set_cfg plan.stripe.top_layer M8
create_power_stripe -direction horizontal -space_of_groups $pwrset2setdist -spacing $pwrspacing -nets [list VDD VSS] -layer $layer -start_offset $pwrxoffset -width $pwrwidth -start_edge bottom -extend_to design_boundary

set pwrset2setdist "10"
set pwrspacing "2"
set pwrxoffset "1"
set pwrwidth "3"
set layer "M9"
set_cfg plan.stripe.bottom_layer M8
set_cfg plan.stripe.top_layer M9
create_power_stripe -direction vertical -space_of_groups $pwrset2setdist -spacing $pwrspacing -nets [list VDD VSS] -layer $layer -start_offset $pwrxoffset -width $pwrwidth -start_edge left -extend_to design_boundary


