#!/bin/bash -ex

RESOURCES="${SOURCE_ROOT}/Authenticator/Resources"
ICONSET="${RESOURCES}/Images.xcassets/AppIcon.appiconset"

ICON_SVG="${RESOURCES}/Icon.svg"
APP_STORE_ICON="${SOURCE_ROOT}/fastlane/metadata/app_icon.png"

hash inkscape 2>/dev/null || { echo >&2 "Icon generation requires inkscape. Using existing icons instead."; exit 0; }
hash pngcrush 2>/dev/null || { echo >&2 "Icon generation requires pngcrush. Using existing icons instead."; exit 0; }

# Generate App Icons
inkscape -z -e "${ICONSET}/Icon-20.png" -w 20 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-29.png" -w 29 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-40.png" -w 40 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-58.png" -w 58 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-60.png" -w 60 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-76.png" -w 76 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-80.png" -w 80 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-87.png" -w 87 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-120.png" -w 120 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-152.png" -w 152 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-167.png" -w 167 $ICON_SVG;
inkscape -z -e "${ICONSET}/Icon-180.png" -w 180 $ICON_SVG;

for ICON in $ICONSET/Icon-*.png; do
  pngcrush -rem alla -ow -res 144 $ICON;
done

# Generate iTunes Artwork
inkscape -z -e $APP_STORE_ICON -w 1024 $ICON_SVG;
pngcrush -rem alla -ow -res 144 $APP_STORE_ICON;
