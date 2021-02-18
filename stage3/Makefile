YFLAGS = -d                       # create y.tab.h
CFLAGS = -std=c89 -Wall -Wextra   # assume ANSI C
LDFLAGS = -lm                     # search math library

OBJS = hoc.o init.o math.o symbol.o

hoc3: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o hoc3 $(LDFLAGS)

hoc.o: hoc.h
init.o symbol.o: hoc.h y.tab.h

pr:
	@pr hoc.y hoc.h init.c math.c symbol.c Makefile

clean:
	rm -f $(OBJS) y.tab.[ch]

