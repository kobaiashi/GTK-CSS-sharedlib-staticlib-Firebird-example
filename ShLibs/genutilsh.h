#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <stdlib.h>

void sharedlib_fun1 (void);
gint sharedlib_fun2 (gint);

void sharedlib_load_img (const char *, GtkImage *);
