# warnings
WARN=-Wall
# compiler
CC=gcc -std=gnu99 -pedantic $(WARN)
#-std=c89

# debug
# DEBUG=-g
# optimisation -O3
OPT=-O0
#-rdynamic -export-dynamic
PTHREAD=-pthread

# change application name here (executable output name)
TARGET=out_app
PKGCONFIG = $(shell which pkg-config)
CFLAGS = $(shell $(PKGCONFIG) --cflags gtk+-3.0) $(shell fb_config --cflags) $(PTHREAD) -pipe
#CFLAGS = $(shell $(PKGCONFIG) --cflags gtk+-3.0) $(PTHREAD) -pipe
LIBS = $(shell $(PKGCONFIG) --libs gtk+-3.0) $(shell fb_config --libs) -L./StLibs -lgenutil -L./ShLibs -lgenutilsh
GLIB_COMPILE_RESOURCES = $(shell $(PKGCONFIG) --variable=glib_compile_resources gio-2.0)

SHLIBS_DIR=./StLibs
STLIBS_DIR=./ShLibs
DISTRO=`lsb_release -i`
RELEASE=`lsb_release -r`

SRC = main.c callbacks.c fbq.c
BUILT_SRC = resources.c

OBJS = $(BUILT_SRC:.c=.o) $(SRC:.c=.o)

$(TARGET): $(OBJS)
		cd ShLibs && make
		cd StLibs && make
		$(CC) -rdynamic $(DEBUG) $(OPT) -o $(@F) $(OBJS) $(LIBS)

resources.c: out_app.gresource.xml window_main.glade a.css reset.css
	$(GLIB_COMPILE_RESOURCES) out_app.gresource.xml --target=$@ --sourcedir=. --generate-source

%.o: %.c
	$(CC) $(DEBUG) $(OPT) -c -o $(@F) $(CFLAGS) $<

clean:
	rm -f $(TARGET)
	rm -f $(BUILT_SRC)
	rm -f $(OBJS)
	cd $(SHLIBS_DIR) && make clean
	cd $(STLIBS_DIR) && make clean
