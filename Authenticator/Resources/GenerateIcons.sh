#!/bin/bash

# Generate App Icons
inkscape -z -e "Icon-29@2x.png" -w 58 "Icon.svg";
inkscape -z -e "Icon-40@2x.png" -w 80 "Icon.svg";
inkscape -z -e "Icon-60@2x.png" -w 120 "Icon.svg";

for file in Icon-*.png; do
  pngcrush -rem alla -ow -res 144 "$file" "_$file";
done

mv Icon-*.png "Images.xcassets/AppIcon.appiconset/"

# Generate iTunes Artwork
inkscape -z -e "iTunesArtwork" -w 512 "Icon.svg";
inkscape -z -e "iTunesArtwork@2x" -w 1024 "Icon.svg";

pngcrush -rem alla -ow -res 144 "iTunesArtwork@2x" "_iTunesArtwork@2x";
pngcrush -rem alla -ow "iTunesArtwork" "_iTunesArtwork";
