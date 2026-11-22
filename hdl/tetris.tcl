set part_name "xc7z020clg400-2"
set origin_dir "."
set _xil_proj_name_ "tetris" 
set proj_dir "./tetris"

# Setup the project

file rename ./${_xil_proj_name_}/tetris.srcs ./tetris.srcs
create_project ${_xil_proj_name_} ${proj_dir} -part $part_name
file rename -force ./tetris.srcs ./${_xil_proj_name_}/tetris.srcs

set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value "$part_name" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "35" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "35" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "35" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "35" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "35" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "35" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "35" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "76" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

# Setup the sources fileset

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# TODO: Recursively add all the files.
add_files -fileset sources_1 [glob ${origin_dir}/src/*]

set obj [get_filesets sources_1]
set_property -name "top" -value "main" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

set ip_source_files [glob $proj_dir/tetris.srcs/sources_1/ip/*/*.xci]

add_files -fileset $obj $ip_source_files

foreach ip_source_file $ip_source_files {
  set file_obj [get_files -of_objects [get_filesets sources_1] [list "$ip_source_file"]]
  set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
  set_property -name "registered_with_manager" -value "1" -objects $file_obj
  if { ![get_property "is_locked" $file_obj] } {
    set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
  }
}

# Setup constraints fileset

if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

set constraints_files [glob $origin_dir/constraints/*.xdc]

set obj [get_filesets constrs_1]
add_files -norecurse -fileset $obj $constraints_files

foreach constraints_file $constraints_files {
  set file_obj [get_files -of_objects [get_filesets constrs_1] [list "$constraints_file"]]
  set_property -name "file_type" -value "XDC" -objects $file_obj
}

set obj [get_filesets constrs_1]
set_property -name "target_part" -value $part_name -objects $obj

if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

set obj [get_filesets sim_1]
set_property -name "hbs.configure_design_for_hier_access" -value "1" -objects $obj
set_property -name "top" -value "render_task_queue_and_vertex_buffer_testbench" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

# Setup the synthesis run

if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part $part_name -flow {Vivado Synthesis 2020} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2020" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj

set obj [get_runs synth_1]
set_property -name "part" -value $part_name -objects $obj
set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $obj

current_run -synthesis [get_runs synth_1]

# Setup the implementation run

if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part $part_name -flow {Vivado Implementation 2020} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2020" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Implementation Default Reports} $obj
set_property set_report_strategy_name 0 $obj

set obj [get_runs impl_1]
set_property -name "part" -value $part_name -objects $obj
set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

current_run -implementation [get_runs impl_1]
