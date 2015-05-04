LOGS = 01 02a 02b 03 04 05a 05b 06 08 09 10 11
.PHONY = 01 02a 02b 03 04 05a 05b 06 08 09 10 11 start.stamp.tmp

OPENMODELICAHOME:=

test: $(LOGS)
	@cat $(LOGS:=.log) | grep "^[= ][+=][ =]" | grep -v "tests failed" > result.txt
	@rm -f $(LOGS:=.log)
	@cat result.txt
	@echo == `grep -v -e ok -e warning -e ^== result.txt | wc -l` out of `grep -v ^== result.txt | wc -l` tests failed "[MetaModelica Course, time: $$((`date +%s`-`cat start.stamp.tmp`))]"
	@rm -f start.stamp.tmp
test-error: test
	@test `grep -v -e ok -e warning -e ^== result.txt | wc -l` -eq "0"
start.stamp.tmp:
	@date +%s > $@
01: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
02a: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
02b: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
03: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
04: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
05a: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
05b: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
06: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
08: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
09: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
10: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed
11: start.stamp.tmp
	@$(MAKE) -C $@_* test > $@.log || echo == $@ failed

