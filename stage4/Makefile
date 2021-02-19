YFLAGS = -d                       # create y.tab.h
CFLAGS = -std=c89 -Wall -Wextra   # assume ANSI C
LDFLAGS = -lm                     # search math library

OBJS = hoc.o code.o init.o math.o symbol.o

hoc4: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o hoc4 $(LDFLAGS)

hoc.o code.o init.o symbol.o: hoc.h
code.o init.o symbol.o: x.tab.h

x.tab.h: y.tab.h
	-cmp -s x.tab.h y.tab.h || cp y.tab.h x.tab.h

pr: hoc.y hoc.h code.c init.c math.c symbol.c
	@pr $?
	@touch pr

clean:
	rm -f $(OBJS) [xy].tab.[ch] pr

