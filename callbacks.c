#include "callbacks.h"

gboolean on_window1_delete_event (GtkWidget *widget,
               GdkEvent  *event,
               gpointer   user_data)
{
  puts("gtk_main_quit");
  gtk_main_quit();
  return FALSE;
}

void
on_textbuffer1_changed (GtkTextBuffer  *buffer,
                   gpointer   user_data)
{
  /* puts("on_textbuffer1_changed"); */

  GtkCssProvider *provider=GTK_CSS_PROVIDER(s_provider);
  GtkTextIter start, end;
  char *css_schema;

  gtk_text_buffer_get_start_iter (buffer, &start);
  gtk_text_buffer_get_end_iter (buffer, &end);
  gtk_text_buffer_remove_all_tags (buffer, &start, &end);

  css_schema = gtk_text_buffer_get_text (buffer, &start, &end, FALSE);
  gtk_css_provider_load_from_data (provider, css_schema, -1, NULL);
  g_free (css_schema);

  gtk_style_context_reset_widgets (gdk_screen_get_default ());

}

void test_css_hardcoded(gpointer user_data)
{
  static gint s=0;
  GtkBuilder *container=(GtkBuilder*)user_data;

  gchar *css_string=g_strdup("treeview{background-color: rgba(0,255,255,1.0); font-size:16pt} \
treeview:selected{background-color: rgba(255,255,0,1.0); \
color: rgba(0,0,255,1.0);}");
  GError *css_error=NULL;
  GtkCssProvider *provider=gtk_css_provider_new();
  gtk_css_provider_load_from_data(provider, css_string, -1, &css_error);
  if (s)
  {
    s=0;
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
					 GTK_STYLE_PROVIDER(provider),
					 GTK_STYLE_PROVIDER_PRIORITY_USER /*GTK_STYLE_PROVIDER_PRIORITY_APPLICATION*/);
    gtk_label_set_text(GTK_LABEL(gtk_builder_get_object(container,"labael_css_priority")),"GTK_STYLE_PROVIDER_PRIORITY_USER");
  }
  else
 {
    s=1;
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
					 GTK_STYLE_PROVIDER(provider),
					 GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
   gtk_label_set_text(GTK_LABEL(gtk_builder_get_object(container,"labael_css_priority")),"GTK_STYLE_PROVIDER_PRIORITY_APPLICATION");
 }

  if(css_error!=NULL)
      {
        g_print("CSS loader error %s\n", css_error->message);
        g_error_free(css_error);
      }
  else
   {
g_print("tema applicato!");
}
  g_object_unref(provider);
  g_free(css_string);
}

void on_button_staticlib_test_clicked (GtkButton *button,
                                      gpointer   user_data)
{
  g_print("on_button_staticlib_test_clicked\n");
  int r,p;
  r=staticlib_fun1(6,2);
  g_print("r:%d\n",r);
  p=staticlib_fun2(6,2);
  g_print("p:%d\n",p);
}

void on_button_sharedlib_test_clicked (GtkButton *button,
                                      gpointer   user_data)
{
  g_print("on_button_sharedlib_test_clicked\n");
  sharedlib_fun1();
  gint t;
  t=sharedlib_fun2 (6);
  g_print("t:%d\n",t);

  GtkBuilder *container=(GtkBuilder*)user_data;
  sharedlib_load_img("./res/f.svg", GTK_IMAGE(gtk_builder_get_object(container,"image")));
}

void on_button2_clicked (GtkButton *button,
                      gpointer   user_data)
{
  puts("on_button2_clicked");
  GtkBuilder *container=(GtkBuilder*)user_data;
  sharedlib_load_img("./res/GTK_logo.png", GTK_IMAGE(gtk_builder_get_object(container,"image")));
  test_css_hardcoded(user_data);
}

void on_button1_clicked (GtkButton *button,
                      gpointer   user_data)
{
  puts("on_button1_clicked");

  if (s_provider)
    {
      puts("s_provider OK");
    }
  else
    {
      puts("s_provider KO!");
    }
  GtkTextBuffer *text;
/*   PangoFontDescription *font_desc;  */
  GtkBuilder *container=(GtkBuilder*)user_data;
  GtkTextView *textview1=GTK_TEXT_VIEW(gtk_builder_get_object(container,"textview1"));
/*
  font_desc = pango_font_description_from_string ("Bitstream Charter 40");
  gtk_widget_override_font (GTK_WIDGET(textview1), font_desc);
*/

  text = gtk_text_view_get_buffer (textview1);

  /* GFile *file=NULL; */
  GtkStyleProvider *provider=NULL;
  GBytes *bytes=NULL;
  GError *error=NULL;
  provider = s_provider;
  gint ret=system("pwd");
  g_print("ret:%d\n",ret);

/*
  gsize length;
  char *contents=NULL;
  file=g_file_new_for_path ("a.css");
  gboolean ret=g_file_load_contents (file,
                      NULL,
                      &contents,
                      &length,
                      NULL,
                      &error);
  if (error)
  {
    g_warning("%s",error->message);
  }
  else
  {
#if 0
    gtk_text_buffer_set_text (text, contents, length);
#endif
    g_free(contents);
  }
*/

  GdkDisplay* display = gdk_display_get_default();
  GdkScreen* screen = gdk_display_get_default_screen(display);
  gtk_style_context_add_provider_for_screen(screen,
                                                  GTK_STYLE_PROVIDER(provider),
                                                  GTK_STYLE_PROVIDER_PRIORITY_USER);
#if 0 // Valido
  ret= gtk_css_provider_load_from_file (GTK_CSS_PROVIDER(provider),file,&error);
  g_print("ret:%d\n",ret);
  if (error)
  {
    g_warning("%s",error->message);
    error=NULL;
  }
#endif

  ret=gtk_css_provider_load_from_path (GTK_CSS_PROVIDER(provider),"a.css", &error);
  g_print("ret:%d\n",ret);
  if (error)
  {
    g_warning("%s",error->message);
    error=NULL;
  }

#if 1
  bytes = g_resources_lookup_data ("/org/gtk/out_app/a.css", 0, &error);
  if (error)
  {
    g_warning("%s",error->message);
    error=NULL;
  }
  else
    {
      g_print("caricato correttamente il tema dal recources\n");
    }
  if (bytes)
  {
    puts("caricato");
    gtk_text_buffer_set_text (text, g_bytes_get_data (bytes, NULL), g_bytes_get_size (bytes));
    g_bytes_unref (bytes);
  }
  else
  {
    puts("non caricato");
  }
#endif

   /* g_object_unref(file); */
}


void on_button_db_test_clicked (GtkButton *button,
                              gpointer   user_data)
{
  g_print("on_button_db_test_clicked\n");
  gint ret=-1;
  gint c;
  GtkTreeIter iter;
  GArray *res=NULL;
  GtkBuilder *container=(GtkBuilder*)user_data;
  GtkTreeModel *model=NULL;
  GtkTreeView *treeview1=GTK_TREE_VIEW(gtk_builder_get_object(container,"treeview1"));
  elemento *e=NULL;

  res=g_array_new(FALSE,FALSE,sizeof(elemento));
  ret=conenctdb("employee",res);
  g_print("ret:%d len:%u\n",ret,res->len);

  model=gtk_tree_view_get_model(treeview1);

  for (c=0;c<res->len;c++)
  {
    e=&g_array_index(res,elemento,c);
    gtk_list_store_append(GTK_LIST_STORE(model),&iter);
    gtk_list_store_set(GTK_LIST_STORE(model),&iter,0,(gint64)c,1,e->last_name,2,e->first_name,3,e->extension,-1);
    g_print("%s %s %s\n",e->last_name,e->first_name,e->extension);
  }
}
