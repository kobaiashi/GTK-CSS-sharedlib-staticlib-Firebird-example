#include "genutilsh.h"

void sharedlib_fun1 (void)
{
  g_print("shared lib fun1\n");
}

gint sharedlib_fun2 (gint i)
{
  g_print("shared lib fun2 in:%d\n",i);
  gint o=i*2;
  g_print("out:%d\n",o);
  return o;
}

void sharedlib_load_img(const char *filename, GtkImage *im)
{
  GError *error=NULL;
  GdkPixbuf *pix=NULL;
  pix=gdk_pixbuf_new_from_file_at_size (filename,
                                  60,
                                  60,
                                  &error);
  if(error)
  {
    g_warning("%s",error->message);
    g_error_free(error);
  }
  else
  {
    gtk_image_set_from_pixbuf (im,pix);
    g_object_unref(pix);
  }
}
