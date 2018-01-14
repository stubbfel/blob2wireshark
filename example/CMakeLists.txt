cmake_minimum_required(VERSION 2.4.2)

project (b2ws_example_project)

file(GLOB_RECURSE b2ws_example_project_src_files "*.h" "*.c")
add_executable(b2ws_example_blob_writer ${b2ws_example_project_src_files} )
