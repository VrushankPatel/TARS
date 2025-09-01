#!/bin/bash

echo "🚀 Building TARS UI..."

# Build the UI
cd TARS-UI
npm run build

# Copy to ui directory
cd ..
cp -r TARS-UI/dist/* ui/

echo "✅ UI built and deployed successfully!"
echo "🌐 Access the UI at: http://localhost:8000/ui/"
echo "📚 API Documentation at: http://localhost:8000/docs"
