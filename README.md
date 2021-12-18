# Chess 3D

Chess 3D visualizer.

## Build instructions

### Dependencies

- gtk4
- vala
- meson
- ninja

On **Ubuntu** 21.10 and later, you can do:
```
sudo apt install libgtk-4-dev valac meson
```

On **Arch Linux**, you can do:
```
sudo pacman -S gtk4 vala meson
```

On **Fedora 34** and later, you can do:
```
sudo dnf install gtk4-devel vala meson
```

```Bash
$ meson build
$ ninja -C build
$ build/chess3d
```
