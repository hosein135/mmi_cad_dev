# count2.sim to be nonisomorphic to testpcnt.sim.
# count2.dict should be identical to count2.dict.sav.

# tetris.sim should be isomorphic to tetris_wl.sim
# tetris.dict should be identical to tetris.dict.sav

all: count2 tetris

count2:
	gemini count2.sim testpcnt.sim -D count2.dict
	@echo Comparing dictionary files
	@rm -f 1 2
	@sort count2.dict > 1
	@sort count2.dict.sav > 2
	@diff 1 2
	@rm 1 2

tetris:
	gemini tetris.sim tetris_wl.sim -D tetris.dict
	@echo Comparing dictionary files
	@rm -f 1 2
	@sort tetris.dict > 1
	@sort tetris.dict.sav > 2
	@diff 1 2
	@rm 1 2
