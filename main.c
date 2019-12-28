#include "callbacks.h"

gboolean key_pressed(GtkWidget *window,
                    GdkEventKey* event,
                    GtkTextBuffer *buffer)
{
  GtkTextIter start_sel, end_sel;
  GtkTextIter start_find, end_find;
  GtkTextIter start_match, end_match;
  gboolean selected;
  gchar *text;

  if ((event->type == GDK_KEY_PRESS) &&
     (event->state & GDK_CONTROL_MASK)) {

    switch (event->keyval) {

      case GDK_KEY_m :
        puts("sono qui");
        selected = gtk_text_buffer_get_selection_bounds(buffer,
            &start_sel, &end_sel);
      if (selected) {
        gtk_text_buffer_get_start_iter(buffer, &start_find);
        gtk_text_buffer_get_end_iter(buffer, &end_find);

        gtk_text_buffer_remove_tag_by_name(buffer, "gray_bg",
            &start_find, &end_find);
        text = (gchar *) gtk_text_buffer_get_text(buffer, &start_sel,
            &end_sel, FALSE);

        while (gtk_text_iter_forward_search(&start_find, text,
                GTK_TEXT_SEARCH_TEXT_ONLY |
                GTK_TEXT_SEARCH_VISIBLE_ONLY,
                &start_match, &end_match, NULL)) {

          gtk_text_buffer_apply_tag_by_name(buffer, "gray_bg",
              &start_match, &end_match);
          gint offset = gtk_text_iter_get_offset(&end_match);
          gtk_text_buffer_get_iter_at_offset(buffer,
              &start_find, offset);
        }

        g_free(text);
      }

      break;

      case GDK_KEY_r:
        gtk_text_buffer_get_start_iter(buffer, &start_find);
        gtk_text_buffer_get_end_iter(buffer, &end_find);

        gtk_text_buffer_remove_tag_by_name(buffer, "gray_bg",
            &start_find, &end_find);
      break;
    }
  }

  return FALSE;
}


int main(int argc, gchar *argv[])
{
  GtkBuilder *builder;
  GtkWindow *window1=NULL;
  GtkTextView *textview1=NULL;
  GtkTextBuffer *buffer;

  puts("************************");
  gtk_init(&argc, &argv);

  builder=gtk_builder_new_from_resource("/org/gtk/out_app/window_main.glade");

  window1=GTK_WINDOW(gtk_builder_get_object(builder,"window1"));
  textview1=GTK_TEXT_VIEW(gtk_builder_get_object(builder,"textview1"));

  gtk_window_set_position(GTK_WINDOW(window1), GTK_WIN_POS_CENTER);
  gtk_window_set_default_size(GTK_WINDOW(window1), 350, 300);
  gtk_window_set_title(GTK_WINDOW(window1), "Search Ctrl-m & highlight Reset Ctrl-r");


  buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(textview1));
  gtk_text_buffer_create_tag(buffer, "gray_bg",
      "background", "lightgray", NULL);

  g_signal_connect(G_OBJECT(window1), "destroy",
        G_CALLBACK(gtk_main_quit), NULL);

  g_signal_connect(G_OBJECT(window1), "key-press-event",
        G_CALLBACK(key_pressed), buffer);

  s_provider = GTK_STYLE_PROVIDER (gtk_css_provider_new ());

  gtk_widget_show_all(GTK_WIDGET(window1));
  puts("siamo qui");
  gtk_builder_connect_signals (builder, builder);

  gtk_main();

  return 0;
}
