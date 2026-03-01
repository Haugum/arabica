# Arabica

☕ Arabica is a tiny macOS menu bar app that keeps your Mac awake until you turn it off.

## What It Does

- 🫘 Lives quietly in your menu bar with a clear coffee bean status icon.
- ✅ Lets you keep your Mac awake indefinitely with a single click.
- 💡 Optionally keeps the display awake too, and updates the menu state immediately when you change it.
- 🍃 Stays lightweight, simple, and out of the way while you work, present, stream, or download.

## Install

Requires Xcode or the Xcode Command Line Tools.

```bash
git clone https://github.com/Haugum/arabica.git && \
cd arabica && \
./scripts/build-app-bundle.sh && \
mv .build/Arabica.app /Applications/Arabica.app && \
open /Applications/Arabica.app
```

Sorry about the extra friction here. Arabica is not distributed with a paid Apple Developer ID signature and notarization, so the safest simple path is to clone the source, build the app locally on your Mac, and place the resulting `Arabica.app` in `/Applications` yourself.

After launch, look for the coffee bean in your menu bar.
