#   tclsh pdk/tests/mcp_selftest.tcl
set here [file dirname [info script]]
source [file join $here .. mcp.tcl]
mcp_selftest
