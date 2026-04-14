# Church Logo Configuration

The application is configured to use `LDS_LOGO.png` as the official church logo for both Word documents and PDF generation.

## Logo Usage:
- **File Location**: `src/main/resources/static/images/LDS_LOGO.png`
- **Supported Formats**: PNG (recommended), JPG
- **Recommended Size**: 120x120 pixels or larger
- **Usage**: Automatically included in generated documents and web preview

## Features:
- **Word Documents**: Logo embedded at 120x120 EMU size
- **PDF Documents**: Logo displayed at 80x80 points with center alignment  
- **Web Preview**: Logo displayed with automatic fallback to text if image fails to load
- **Fallback**: If logo file is missing, displays "THE CHURCH OF JESUS CHRIST OF LATTER-DAY SAINTS" text

## Current Configuration:
✅ LDS_LOGO.png - Active logo file
- Word document generation: ✅ Enabled
- PDF document generation: ✅ Enabled  
- Web preview: ✅ Enabled with fallback