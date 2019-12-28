# compiler
CC=gcc -std=gnu99 -pedantic
# debug
#DEBUG=-g -Wall

SRC = static1.c static2.c

TARGET=libgenutil.a
PKGCONFIG = $(shell which pkg-config)
CFLAGS = $(shell $(PKGCONFIG) --cflags gtk+-3.0) $(shell fb_config --cflags)
LIBS = $(shell $(PKGCONFIG) --libs gtk+-3.0) $(shell fb_config --libs)

OBJS = $(SRC:.c=.o)


$(TARGET):static1.o static2.o
	ar -rc $(TARGET) $(OBJS)

%.o: %.c %.h
	$(CC) $(OPT) -c -o $(@F) $(CFLAGS) $<
#	$(CC) -c $(SRC) $(LIBS) $(CFLAGS)

clean:
	rm -f $(TARGET)
	rm -f $(OBJS)
