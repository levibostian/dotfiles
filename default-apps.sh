#!/bin/bash

# Check if utiluti is installed
if ! command -v utiluti &> /dev/null; then
    echo "Error: utiluti is not installed. Please install it from https://github.com/scriptingosx/utiluti"
    exit 1
fi

echo "Setting default applications for developer file types..."
echo "Note: Some file types are commented out because they don't have standard UTIs."
echo "      For those, you'll need to manually set defaults in System Preferences > General > Default web browser/email app"
echo "      or by right-clicking a file and choosing 'Open With' > 'Choose Other...' > 'Always Open With'"
echo ""

# Text and Markup Files - VS Code
utiluti type set public.plain-text com.microsoft.VSCode         # .txt
utiluti type set net.daringfireball.markdown com.microsoft.VSCode # .md (using working UTI)
utiluti type set public.rtf com.microsoft.VSCode               # .rtf
utiluti type set com.apple.traditional-mac-plain-text com.microsoft.VSCode

# Programming Languages - VS Code
utiluti type set com.netscape.javascript-source com.microsoft.VSCode # .js
# utiluti ext set ts com.microsoft.VSCode                        # .ts (no standard UTI - manual setup needed)
utiluti type set public.json com.microsoft.VSCode              # .json
utiluti type set public.css com.microsoft.VSCode               # .css
# utiluti ext set scss com.microsoft.VSCode                      # .scss (no standard UTI - manual setup needed)
# utiluti ext set less com.microsoft.VSCode                      # .less (no standard UTI - manual setup needed)
utiluti type set public.xml com.microsoft.VSCode               # .xml
utiluti type set public.yaml com.microsoft.VSCode              # .yaml
utiluti type set public.yaml com.microsoft.VSCode              # .yml
utiluti type set public.shell-script com.microsoft.VSCode      # .sh
utiluti type set public.python-script com.microsoft.VSCode     # .py
utiluti type set public.php-script com.microsoft.VSCode        # .php
utiluti type set public.ruby-script com.microsoft.VSCode       # .rb
utiluti type set public.perl-script com.microsoft.VSCode       # .pl
utiluti type set public.c-source com.microsoft.VSCode          # .c
utiluti type set public.c-plus-plus-source com.microsoft.VSCode # .cpp, .cc
utiluti type set public.c-header com.microsoft.VSCode          # .h
utiluti type set com.sun.java-source com.microsoft.VSCode      # .java
# utiluti ext set go com.microsoft.VSCode                        # .go (no standard UTI - manual setup needed)
# utiluti ext set rs com.microsoft.VSCode                        # .rs (no standard UTI - manual setup needed)

# Kotlin - Android Studio
# utiluti ext set kt com.google.android.studio                   # .kt (no standard UTI - manual setup needed)
if [ -d "/Applications/Xcode.app" ]; then
    utiluti type set public.swift-source com.apple.dt.Xcode        # .swift
    utiluti type set public.objective-c-source com.apple.dt.Xcode  # .m
    utiluti type set public.objective-c-plus-plus-source com.apple.dt.Xcode # .mm
fi

# Web Development - VS Code
# utiluti type set public.html com.microsoft.VSCode              # .html - VS Code for editing (error -54: file in use)
utiluti type set public.xhtml com.microsoft.VSCode             # .xhtml
utiluti type set public.svg-image com.microsoft.VSCode         # .svg

# Configuration Files - VS Code
utiluti type set public.comma-separated-values-text com.microsoft.VSCode # .csv
utiluti type set com.apple.property-list com.microsoft.VSCode  # .plist
# utiluti ext set toml com.microsoft.VSCode                      # .toml (no standard UTI - manual setup needed)

# Docker and DevOps - VS Code
# utiluti ext set dockerfile com.microsoft.VSCode                # Dockerfile (no standard UTI - manual setup needed)
# utiluti ext set docker-compose.yml com.microsoft.VSCode        # docker-compose.yml (no standard UTI - manual setup needed)

# Documentation - VS Code
utiluti type set net.daringfireball.markdown com.microsoft.VSCode # .md, .markdown
# utiluti ext set rst com.microsoft.VSCode                       # .rst (no standard UTI - manual setup needed)
# utiluti ext set adoc com.microsoft.VSCode                      # .adoc (no standard UTI - manual setup needed)

# Build Files - VS Code
# utiluti ext set makefile com.microsoft.VSCode                  # Makefile (no standard UTI - manual setup needed)
# utiluti ext set gradle com.microsoft.VSCode                    # .gradle (no standard UTI - manual setup needed)
# utiluti ext set pom.xml com.microsoft.VSCode                   # pom.xml (no standard UTI - manual setup needed)

# Images - Preview
utiluti type set public.jpeg com.apple.Preview                 # .jpg, .jpeg
utiluti type set public.png com.apple.Preview                  # .png
utiluti type set com.compuserve.gif com.apple.Preview          # .gif
utiluti type set public.tiff com.apple.Preview                 # .tiff, .tif
utiluti type set public.svg-image com.apple.Preview            # .svg
utiluti type set org.webmproject.webp com.apple.Preview        # .webp
utiluti type set public.heic com.apple.Preview                 # .heic
utiluti type set public.avif com.apple.Preview                 # .avif

# PDFs - Preview
utiluti type set com.adobe.pdf com.apple.Preview               # .pdf

# Archives - Archive Utility
utiluti type set public.zip-archive com.apple.archiveutility   # .zip
utiluti type set public.tar-archive com.apple.archiveutility   # .tar
utiluti type set org.gnu.gnu-zip-archive com.apple.archiveutility # .gz

# Database Files - VS Code (for viewing SQL)
# utiluti ext set sql com.microsoft.VSCode                       # .sql (no standard UTI - manual setup needed)
utiluti type set public.database com.microsoft.VSCode          # .db

# Log Files - Console
utiluti type set public.log com.apple.Console                  # .log

echo "Default applications have been set successfully!"
echo "Note: Some file types may require the target application to be installed."