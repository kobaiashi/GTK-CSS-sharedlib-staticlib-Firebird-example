#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gio/gio.h>
#include <stdlib.h>
#include <gdk/gdkkeysyms.h>
#include "fbq.h"
#include "./StLibs/static1.h"
#include "./StLibs/static2.h"
#include "./ShLibs/genutilsh.h"

GtkStyleProvider *s_provider;


gboolean on_window1_delete_event (GtkWidget *,
               GdkEvent  *,
               gpointer  );

void on_button1_clicked (GtkButton *, gpointer);
