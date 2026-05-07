#!/bin/bash
# Removes MDViewer from the Accessibility permission list.
# Run this once after changing signing settings, then re-grant permission when prompted.

BUNDLE_ID="com.danielgabbay.MDViewer"

echo "Resetting Accessibility permission for $BUNDLE_ID..."
tccutil reset Accessibility "$BUNDLE_ID"
echo "Done. Launch MDViewer and grant Accessibility permission once."
