#!/usr/bin/env python3
"""Lowpaper Control Center — a small GTK3 frontend for lowpaper."""
import os, shutil, subprocess, sys
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk

APP_NAME = "Lowpaper Control Center"

def run_lowpaper(*args, check=False):
    binary = shutil.which("lowpaper") or os.path.expanduser("~/.local/bin/lowpaper")
    if not os.path.isfile(binary) and not shutil.which("lowpaper"):
        raise RuntimeError("lowpaper was not found. Install it before opening this app.")
    result = subprocess.run([binary, *map(str, args)], text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=30, check=False)
    output, error = (result.stdout or "").strip(), (result.stderr or "").strip()
    if check and result.returncode:
        raise RuntimeError(error or output or f"lowpaper exited with code {result.returncode}")
    return result.returncode, output, error

class LowpaperWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title=APP_NAME)
        self.set_default_size(760, 650)
        self.set_border_width(20)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.selected = []
        self._install_css()
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.add(root)
        header = Gtk.Box(spacing=12)
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        title = Gtk.Label()
        title.set_markup('<span size="xx-large" weight="bold">Lowpaper</span> <span foreground="#8ab4ff" size="large">Control Center</span>')
        title.set_xalign(0)
        subtitle = Gtk.Label(label="Manage your live wallpapers on XFCE")
        subtitle.set_xalign(0)
        subtitle.get_style_context().add_class("muted")
        title_box.pack_start(title, False, False, 0)
        title_box.pack_start(subtitle, False, False, 0)
        header.pack_start(title_box, True, True, 0)
        self.status_badge = Gtk.Label(label="Checking…")
        self.status_badge.get_style_context().add_class("status")
        header.pack_end(self.status_badge, False, False, 0)
        root.pack_start(header, False, False, 0)

        current_card = self.card()
        current_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        current_heading = Gtk.Label(label="CURRENT WALLPAPER")
        current_heading.set_xalign(0)
        current_heading.get_style_context().add_class("section-label")
        self.current_label = Gtk.Label(label="Checking wallpaper status…")
        self.current_label.set_xalign(0)
        self.current_label.set_line_wrap(True)
        self.current_label.set_selectable(True)
        current_box.pack_start(current_heading, False, False, 0)
        current_box.pack_start(self.current_label, False, False, 0)
        current_card.add(current_box)
        root.pack_start(current_card, False, False, 0)

        controls_card = self.card()
        controls = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        heading = Gtk.Label(label="PLAYBACK")
        heading.set_xalign(0)
        heading.get_style_context().add_class("section-label")
        controls.pack_start(heading, False, False, 0)
        row = Gtk.Box(spacing=8)
        for label, icon, callback in (
            ("Pause", "media-playback-pause-symbolic", self.pause),
            ("Resume", "media-playback-start-symbolic", self.resume),
            ("Next", "media-skip-forward-symbolic", self.next_wallpaper),
            ("Stop", "media-playback-stop-symbolic", self.stop)):
            row.pack_start(self.action_button(label, icon, callback), True, True, 0)
        controls.pack_start(row, False, False, 0)
        controls_card.add(controls)
        root.pack_start(controls_card, False, False, 0)

        library_card = self.card()
        library = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        library_heading = Gtk.Label(label="WALLPAPER LIBRARY")
        library_heading.set_xalign(0)
        library_heading.get_style_context().add_class("section-label")
        library.pack_start(library_heading, False, False, 0)
        self.file_list = Gtk.ListBox()
        self.file_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.file_list.set_placeholder(Gtk.Label(label="No wallpapers selected. Add videos or a folder."))
        scroller = Gtk.ScrolledWindow()
        scroller.set_min_content_height(105)
        scroller.set_max_content_height(155)
        scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroller.add(self.file_list)
        library.pack_start(scroller, True, True, 0)
        actions = Gtk.Box(spacing=8)
        actions.pack_start(self.action_button("Add videos", "list-add-symbolic", self.add_files), True, True, 0)
        actions.pack_start(self.action_button("Add folder", "folder-symbolic", self.add_folder), True, True, 0)
        actions.pack_start(self.action_button("Remove selected", "list-remove-symbolic", self.remove_selected), True, True, 0)
        library.pack_start(actions, False, False, 0)
        library_card.add(library)
        root.pack_start(library_card, True, True, 0)

        settings_card = self.card()
        settings = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        settings_heading = Gtk.Label(label="PLAYBACK SETTINGS")
        settings_heading.set_xalign(0)
        settings_heading.get_style_context().add_class("section-label")
        settings.pack_start(settings_heading, False, False, 0)
        fit_row = Gtk.Box(spacing=12)
        fit_label = Gtk.Label(label="Scaling")
        fit_label.set_xalign(0)
        fit_row.pack_start(fit_label, True, True, 0)
        self.fit_combo = Gtk.ComboBoxText()
        for value, label in (("fill", "Fill screen"), ("fit", "Fit inside"), ("stretch", "Stretch")):
            self.fit_combo.append(value, label)
        self.fit_combo.set_active_id("fill")
        self.fit_combo.connect("changed", self.change_fit)
        fit_row.pack_end(self.fit_combo, False, False, 0)
        settings.pack_start(fit_row, False, False, 0)
        switches = Gtk.Box(spacing=20)
        self.shuffle_switch = self.add_switch(switches, "Shuffle playlist", False)
        self.audio_switch = self.add_switch(switches, "Enable wallpaper audio", False)
        settings.pack_start(switches, False, False, 0)
        self.startup_switch = Gtk.Switch()
        self.startup_switch.connect("notify::active", self.change_startup)
        startup_row = Gtk.Box(spacing=12)
        startup_label = Gtk.Label(label="Start wallpaper automatically at login")
        startup_label.set_xalign(0)
        startup_row.pack_start(startup_label, True, True, 0)
        startup_row.pack_end(self.startup_switch, False, False, 0)
        settings.pack_start(startup_row, False, False, 0)
        settings_card.add(settings)
        root.pack_start(settings_card, False, False, 0)

        footer = Gtk.Box(spacing=8)
        self.message = Gtk.Label(label="Ready")
        self.message.set_xalign(0)
        self.message.set_line_wrap(True)
        self.message.get_style_context().add_class("muted")
        footer.pack_start(self.message, True, True, 0)
        footer.pack_end(self.action_button("Reapply desktop layer", "view-refresh-symbolic", self.reapply), False, False, 0)
        footer.pack_end(self.action_button("Start selected", "media-playback-start-symbolic", self.start_selected, True), False, False, 0)
        root.pack_start(footer, False, False, 0)

        self.refresh()
        self._loading_startup = True
        _, startup, _ = run_lowpaper("startup")
        self.startup_switch.set_active(startup.strip() == "on")
        self._loading_startup = False
        GLib.timeout_add_seconds(5, self.refresh)

    def _install_css(self):
        css = b"""
        window { background: #101722; color: #e8eef8; }
        .card { background: #192536; border: 1px solid #29394e; border-radius: 12px; padding: 14px; }
        .muted { color: #9aabc1; }
        .section-label { color: #8ab4ff; font-size: 10pt; font-weight: bold; }
        .status { background: #203c36; color: #9ee6c1; border-radius: 12px; padding: 7px 12px; }
        button { background: #26374c; color: #e8eef8; border: 1px solid #344963; border-radius: 8px; padding: 9px 12px; }
        button:hover { background: #344c69; }
        button.primary { background: #3568ad; border-color: #5288d0; color: white; font-weight: bold; }
        button.primary:hover { background: #437bc3; }
        list row { padding: 7px; }
        list row:selected { background: #294a70; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def card(self):
        box = Gtk.Box()
        box.get_style_context().add_class("card")
        return box

    def action_button(self, label, icon_name, callback, primary=False):
        button = Gtk.Button()
        inner = Gtk.Box(spacing=7)
        inner.pack_start(Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.BUTTON), False, False, 0)
        inner.pack_start(Gtk.Label(label=label), False, False, 0)
        button.add(inner)
        if primary:
            button.get_style_context().add_class("primary")
        button.connect("clicked", lambda *_: callback())
        return button

    def add_switch(self, parent, label, active):
        box = Gtk.Box(spacing=7)
        box.pack_start(Gtk.Label(label=label), False, False, 0)
        switch = Gtk.Switch()
        switch.set_active(active)
        box.pack_start(switch, False, False, 0)
        parent.pack_start(box, True, True, 0)
        return switch

    def notify(self, message, error=False):
        self.message.set_text(message)
        if error:
            self.message.get_style_context().add_class("error")

    def dialog(self, title, message, kind=Gtk.MessageType.INFO):
        dialog = Gtk.MessageDialog(transient_for=self, flags=Gtk.DialogFlags.MODAL,
                                   message_type=kind, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def invoke(self, *args, success="Done"):
        try:
            _, output, _ = run_lowpaper(*args, check=True)
            self.notify(output or success)
            self.refresh()
        except Exception as exc:
            self.notify(str(exc), True)
            self.dialog("Lowpaper", str(exc), Gtk.MessageType.ERROR)

    def refresh(self):
        try:
            _, output, _ = run_lowpaper("status")
            if output and output != "not running":
                self.current_label.set_text(output)
                self.status_badge.set_text("●  PLAYING" if "playing" in output else "●  PAUSED")
            else:
                self.current_label.set_text("No wallpaper is currently running.")
                self.status_badge.set_text("●  STOPPED")
        except Exception as exc:
            self.current_label.set_text(str(exc))
            self.status_badge.set_text("●  UNAVAILABLE")
        return True

    def add_path(self, path):
        if path not in self.selected:
            self.selected.append(path)
            row = Gtk.ListBoxRow()
            label = Gtk.Label(label=path, xalign=0)
            label.set_ellipsize(3)
            row.add(label)
            row.path_value = path
            self.file_list.add(row)
            self.file_list.show_all()

    def chooser(self, folder=False):
        action = Gtk.FileChooserAction.SELECT_FOLDER if folder else Gtk.FileChooserAction.OPEN
        dialog = Gtk.FileChooserDialog(title="Choose wallpaper folder" if folder else "Choose wallpaper videos",
                                       parent=self, action=action)
        dialog.add_buttons("Cancel", Gtk.ResponseType.CANCEL, "Add", Gtk.ResponseType.ACCEPT)
        if not folder:
            dialog.set_select_multiple(True)
            filt = Gtk.FileFilter()
            filt.set_name("Video and image wallpapers")
            for pattern in ("*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi", "*.m4v", "*.gif",
                            "*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"):
                filt.add_pattern(pattern)
            dialog.add_filter(filt)
        if dialog.run() == Gtk.ResponseType.ACCEPT:
            for path in dialog.get_filenames():
                self.add_path(path)
        dialog.destroy()

    def add_files(self): self.chooser(False)
    def add_folder(self): self.chooser(True)

    def remove_selected(self):
        row = self.file_list.get_selected_row()
        if row:
            self.selected.remove(row.path_value)
            self.file_list.remove(row)

    def start_selected(self):
        if not self.selected:
            self.dialog("No wallpapers selected", "Add one or more video files, or choose a folder.")
            return
        args = ["-f", self.fit_combo.get_active_id() or "fill"]
        if self.shuffle_switch.get_active(): args.append("-s")
        if self.audio_switch.get_active(): args.append("-a")
        args.append("--")
        args.extend(self.selected)
        self.invoke(*args, success="Wallpaper started.")

    def pause(self): self.invoke("pause", success="Wallpaper paused.")
    def resume(self): self.invoke("resume", success="Wallpaper resumed.")
    def next_wallpaper(self): self.invoke("next", success="Moved to next wallpaper.")
    def stop(self): self.invoke("stop", success="Wallpaper stopped.")
    def reapply(self): self.invoke("restore", success="Wallpaper integration reapplied.")

    def change_fit(self, combo):
        if combo.get_active_id():
            try: run_lowpaper("fit", combo.get_active_id())
            except Exception as exc: self.notify(str(exc), True)

    def change_startup(self, switch, _pspec):
        if getattr(self, "_loading_startup", True): return
        self.invoke("startup", "on" if switch.get_active() else "off",
                    success="Login startup preference updated.")

def main():
    window = LowpaperWindow()
    window.connect("destroy", Gtk.main_quit)
    window.show_all()
    Gtk.main()

if __name__ == "__main__":
    try: main()
    except Exception as exc:
        print(f"{APP_NAME}: {exc}", file=sys.stderr)
        raise
