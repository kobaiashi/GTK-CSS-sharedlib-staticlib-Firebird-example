# compiler
CC=gcc -std=gnu99 -pedantic

# debug
DEBUG=-g -Wall
# optimisation -O3 > massima ottimizzazione
#OPT=-O0 -export-dynamic
OPT=-O0
# warnings
WARN=-Wall
PTHREAD=-pthread

# change shared lib name here
TARGET=libgenutilsh.so
PKGCONFIG = $(shell which pkg-config)
CFLAGS = $(shell $(PKGCONFIG) --cflags gtk+-3.0) $(PTHREAD) -pipe $(shell fb_config --cflags)
LIBS = $(shell $(PKGCONFIG) --libs gtk+-3.0) $(shell fb_config --libs) -L. -lbar
#SRC = genutilsh.c
#OBJS = $(SRC:.c=.o)

$(TARGET): genutilsh.o
	$(CC) -shared -o $@ $<

#libbar.so: bar.o
#	$(CC) -shared -o $@ $<

#bar.o: bar.c bar.h
#	$(CC) -c -Wall -fpic -o $@  $(CFLAGS) $<

genutilsh.o: genutilsh.c genutilsh.h
	$(CC) -c -Wall -fpic -o $@  $(CFLAGS) $<

#%.o: %.c
#	$(CC) $(OPT) -c -o $(@F) $(CFLAGS) $<

clean:
	rm -f $(TARGET)
