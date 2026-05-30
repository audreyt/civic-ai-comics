#!/bin/bash

# Comic Web Format Converter Script
# Converts comic pages to vertical web format for easy reading
# Usage: ./convert_comics_to_web.sh <folder_name>
# Example: ./convert_comics_to_web.sh comics-en

# Check if folder argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <folder_name>"
    echo "Example: $0 comics-en"
    exit 1
fi

# Set the input folder from command line argument
INPUT_FOLDER="$1"

# Check if the input folder exists
if [ ! -d "$INPUT_FOLDER" ]; then
    echo "Error: Folder '$INPUT_FOLDER' does not exist!"
    exit 1
fi

# Create the web subfolder if it doesn't exist
WEB_FOLDER="$INPUT_FOLDER/web"
if [ ! -d "$WEB_FOLDER" ]; then
    echo "Creating web folder: $WEB_FOLDER"
    mkdir -p "$WEB_FOLDER"
else
    echo "Web folder already exists: $WEB_FOLDER"
fi

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed!"
    echo "Please install ImageMagick first:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    exit 1
fi

# Use 'magick' command if available (ImageMagick 7+), otherwise use 'convert' (ImageMagick 6)
if command -v magick &> /dev/null; then
    MAGICK_CMD="magick"
else
    MAGICK_CMD="convert"
fi

echo "Starting conversion process for $INPUT_FOLDER..."

# Step 1: Combine Overview.png and web_footer.png vertically
echo "Processing Overview.png..."
if [ -f "$INPUT_FOLDER/Overview.png" ] && [ -f "$INPUT_FOLDER/web_footer.png" ]; then
    # Combine Overview.png and web_footer.png vertically with no margin
    # -append stacks images vertically
    $MAGICK_CMD "$INPUT_FOLDER/Overview.png" "$INPUT_FOLDER/web_footer.png" -append "$WEB_FOLDER/Overview.png"
    echo "✓ Created: $WEB_FOLDER/Overview.png"
else
    echo "Warning: Overview.png or web_footer.png not found in $INPUT_FOLDER"
fi

# Step 2: Process chapters 1-6
for chapter in {1..6}; do
    echo "Processing Chapter $chapter..."
    
    # Define file paths for this chapter
    A_FILE="$INPUT_FOLDER/Ch${chapter}_A.png"
    B_FILE="$INPUT_FOLDER/Ch${chapter}_B.png"
    FOOTER_FILE="$INPUT_FOLDER/web_footer.png"
    OUTPUT_FILE="$WEB_FOLDER/Ch${chapter}.png"
    
    # Check if both chapter files exist
    if [ -f "$A_FILE" ] && [ -f "$B_FILE" ] && [ -f "$FOOTER_FILE" ]; then
        echo "  - Found Ch${chapter}_A.png and Ch${chapter}_B.png"
        
        # Crop the B page using the specified dimensions:
        # x=0, y=1100, width=5749, height=6900
        # This extracts a portion from the B page starting at coordinates (0,1100)
        # with dimensions 5749x6900 pixels
        echo "  - Cropping Ch${chapter}_B.png (x=0, y=1100, w=5749, h=6900)"
        TEMP_B_CROPPED="/tmp/ch${chapter}_b_cropped.png"
        $MAGICK_CMD "$B_FILE" -crop 5749x6900+0+1100 "$TEMP_B_CROPPED"
        
        # Combine the three images vertically:
        # 1. Ch[N]_A.png (unchanged)
        # 2. Ch[N]_B.png (cropped version)
        # 3. web_footer.png (unchanged)
        echo "  - Combining A page + cropped B page + footer"
        $MAGICK_CMD "$A_FILE" "$TEMP_B_CROPPED" "$FOOTER_FILE" -append "$OUTPUT_FILE"
        
        # Clean up temporary file
        rm "$TEMP_B_CROPPED"
        
        echo "✓ Created: $OUTPUT_FILE"
    else
        echo "Warning: Missing files for Chapter $chapter (skipping)"
        if [ ! -f "$A_FILE" ]; then echo "  - Missing: $A_FILE"; fi
        if [ ! -f "$B_FILE" ]; then echo "  - Missing: $B_FILE"; fi
        if [ ! -f "$FOOTER_FILE" ]; then echo "  - Missing: $FOOTER_FILE"; fi
    fi
done

echo ""
echo "🎉 Conversion complete!"
echo "Web-formatted files are now available in: $WEB_FOLDER"
echo ""
echo "Generated files:"
ls -la "$WEB_FOLDER"