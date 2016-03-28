#!/bin/bash

hash inkscape 2>/dev/null || { echo >&2 "Icon generation requires inkscape. Using existing icons instead."; exit 0; }
hash pngcrush 2>/dev/null || { echo >&2 "Icon generation requires pngcrush. Using existing icons instead."; exit 0; }

# Generate App Icons
inkscape -z -e "Icon-29.png" -w 29 "Icon.svg";
inkscape -z -e "Icon-40.png" -w 40 "Icon.svg";
inkscape -z -e "Icon-58.png" -w 58 "Icon.svg";
inkscape -z -e "Icon-76.png" -w 76 "Icon.svg";
inkscape -z -e "Icon-80.png" -w 80 "Icon.svg";
inkscape -z -e "Icon-87.png" -w 87 "Icon.svg";
inkscape -z -e "Icon-120.png" -w 120 "Icon.svg";
inkscape -z -e "Icon-152.png" -w 152 "Icon.svg";
inkscape -z -e "Icon-167.png" -w 167 "Icon.svg";
inkscape -z -e "Icon-180.png" -w 180 "Icon.svg";

for file in Icon-*.png; do
  pngcrush -rem alla -ow -res 144 "$file" "_$file";
done

mv Icon-*.png "Images.xcassets/AppIcon.appiconset/"

# Generate iTunes Artwork
inkscape -z -e "iTunesArtwork" -w 512 "Icon.svg";
inkscape -z -e "iTunesArtwork@2x" -w 1024 "Icon.svg";

pngcrush -rem alla -ow -res 144 "iTunesArtwork@2x" "_iTunesArtwork@2x";
pngcrush -rem alla -ow "iTunesArtwork" "_iTunesArtwork";
