#!/bin/csh -f

# updates spice netlists for any schematics that have changed

set tech = mmi15

cd /proj/tech/$tech/stdcell/sue_fixed

sue -CMD gensp -CMD exit

exit
