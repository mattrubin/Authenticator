#!/bin/bash

hash inkscape 2>/dev/null || { echo >&2 "Icon generation requires inkscape. Using existing icons instead."; exit 0; }
hash pngcrush 2>/dev/null || { echo >&2 "Icon generation requires pngcrush. Using existing icons instead."; exit 0; }

# Generate App Icons
for sz in 20 29 40 58 60 76 80 87 120 152 167 180; do
  inkscape -z -e "Icon-${sz}.png" -w $sz "Icon.svg";
done

for file in Icon-*.png; do
  pngcrush -rem alla -ow -res 144 "$file" "_$file";
done

mv Icon-*.png "Images.xcassets/AppIcon.appiconset/"

# Generate Watch App Icons
for sz in 48 55 58 87 80 172 196; do
  inkscape -z -e "Icon-${sz}.png" -w $sz "Icon.svg";
done

for file in Icon-*.png; do
pngcrush -rem alla -ow -res 144 "$file" "_$file";
done

mv Icon-*.png "../../AuthenticatorWatch/Assets.xcassets/AppIcon.appiconset/"


# Generate iTunes Artwork
inkscape -z -e "iTunesArtwork" -w 512 "Icon.svg";
inkscape -z -e "iTunesArtwork@2x" -w 1024 "Icon.svg";

pngcrush -rem alla -ow -res 144 "iTunesArtwork@2x" "_iTunesArtwork@2x";
pngcrush -rem alla -ow "iTunesArtwork" "_iTunesArtwork";
