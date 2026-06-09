#include "my_application.h"

#include <glib.h>
#include <stdlib.h>

static void ConfigureBundledLibraryPath()
{
  gchar *exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path == nullptr)
  {
    return;
  }

  gchar *exe_dir = g_path_get_dirname(exe_path);
  g_free(exe_path);
  if (exe_dir == nullptr)
  {
    return;
  }

  gchar *lib_dir = g_build_filename(exe_dir, "lib", nullptr);
  g_free(exe_dir);
  if (lib_dir == nullptr)
  {
    return;
  }

  const gchar *current = g_getenv("LD_LIBRARY_PATH");
  gchar *combined = nullptr;
  if (current != nullptr && *current != '\0')
  {
    combined = g_strconcat(lib_dir, ":", current, nullptr);
  }
  else
  {
    combined = g_strdup(lib_dir);
  }

  if (combined != nullptr)
  {
    g_setenv("LD_LIBRARY_PATH", combined, TRUE);
    g_free(combined);
  }

  g_free(lib_dir);
}

int main(int argc, char **argv)
{
  // Désactiver l'accélération matérielle et forcer le rendu logiciel
  // Ceci contourne les problèmes EGL sur Hyprland/Wayland
  setenv("FLUTTER_ENGINE_SOFTWARE_RENDERING", "1", 0);
  setenv("FLUTTER_ENGINE_DISABLE_VULKAN", "1", 0);
  setenv("LIBGL_ALWAYS_SOFTWARE", "1", 0);
  setenv("MESA_LOADER_DRIVER_OVERRIDE", "llvmpipe", 0);
  setenv("EGL_PLATFORM", "surfaceless", 0);
  setenv("GDK_BACKEND", "x11", 0);
  setenv("CLUTTER_BACKEND", "x11", 0);
  setenv("SDL_VIDEO_DRIVER", "x11", 0);
  setenv("SDL_VIDEO_X11_FORCE_EGL", "0", 0);

  ConfigureBundledLibraryPath();
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
