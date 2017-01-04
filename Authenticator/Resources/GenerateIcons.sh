#!/bin/bash

PREFIX="${SRCROOT}/Authenticator/Resources"
ICON="${PREFIX}/Icon.svg"

hash inkscape 2>/dev/null || { echo >&2 "Icon generation requires inkscape. Using existing icons instead."; exit 0; }
hash pngcrush 2>/dev/null || { echo >&2 "Icon generation requires pngcrush. Using existing icons instead."; exit 0; }

# Generate App Icons
inkscape -z -e "${PREFIX}/Icon-20.png" -w 20 $ICON;
inkscape -z -e "${PREFIX}/Icon-29.png" -w 29 $ICON;
inkscape -z -e "${PREFIX}/Icon-40.png" -w 40 $ICON;
inkscape -z -e "${PREFIX}/Icon-58.png" -w 58 $ICON;
inkscape -z -e "${PREFIX}/Icon-60.png" -w 60 $ICON;
inkscape -z -e "${PREFIX}/Icon-76.png" -w 76 $ICON;
inkscape -z -e "${PREFIX}/Icon-80.png" -w 80 $ICON;
inkscape -z -e "${PREFIX}/Icon-87.png" -w 87 $ICON;
inkscape -z -e "${PREFIX}/Icon-120.png" -w 120 $ICON;
inkscape -z -e "${PREFIX}/Icon-152.png" -w 152 $ICON;
inkscape -z -e "${PREFIX}/Icon-167.png" -w 167 $ICON;
inkscape -z -e "${PREFIX}/Icon-180.png" -w 180 $ICON;

for file in Icon-*.png; do
  pngcrush -rem alla -ow -res 144 "$file" "_$file";
done

mv Icon-*.png "Images.xcassets/AppIcon.appiconset/"

# Generate iTunes Artwork
inkscape -z -e "${PREFIX}/iTunesArtwork" -w 512 $ICON;
inkscape -z -e "${PREFIX}/iTunesArtwork@2x" -w 1024 $ICON;

pngcrush -rem alla -ow -res 144 "iTunesArtwork@2x" "_iTunesArtwork@2x";
pngcrush -rem alla -ow "iTunesArtwork" "_iTunesArtwork";
