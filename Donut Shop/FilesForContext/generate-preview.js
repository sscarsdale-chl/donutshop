#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Simple script to generate a preview HTML file for banner ads

// Define the root directory
const rootDir = process.cwd();
console.log(`Root directory: ${rootDir}`);

// Get all directories in the root
try {
  const dirs = fs.readdirSync(rootDir).filter(item => {
    const fullPath = path.join(rootDir, item);
    return fs.statSync(fullPath).isDirectory() && 
           !item.startsWith('.') && 
           item !== 'node_modules';
  });
  
  console.log(`Found directories: ${dirs.join(', ')}`);
  
  // Find banner directories (format: 000x000)
  const bannerDirs = dirs.filter(dir => /^\d+x\d+$/.test(dir));
  console.log(`Found banner directories: ${bannerDirs.join(', ')}`);
  
  if (bannerDirs.length === 0) {
    console.log('No banner directories found. Exiting.');
    process.exit(1);
  }
  
  // Collect banner data
  const banners = [];
  
  for (const dir of bannerDirs) {
    const htmlDir = path.join(rootDir, dir, 'html');
    
    if (fs.existsSync(htmlDir) && fs.statSync(htmlDir).isDirectory()) {
      const htmlFiles = fs.readdirSync(htmlDir)
        .filter(file => path.extname(file).toLowerCase() === '.html');
      
      console.log(`${dir}: Found ${htmlFiles.length} HTML files`);
      
      for (const htmlFile of htmlFiles) {
        const [width, height] = dir.split('x').map(Number);
        banners.push({
          size: dir,
          width,
          height,
          path: `${dir}/html/${htmlFile}`,
          filename: htmlFile
        });
      }
    }
  }
  
  console.log(`Total banners collected: ${banners.length}`);
  
  if (banners.length === 0) {
    console.log('No HTML files found in banner directories. Exiting.');
    process.exit(1);
  }
  
  // Generate preview HTML
  // Group banners by orientation
  const verticalBanners = banners.filter(b => b.height > b.width);
  const horizontalBanners = banners.filter(b => b.height <= b.width);
  
  console.log(`Vertical banners: ${verticalBanners.length}`);
  console.log(`Horizontal banners: ${horizontalBanners.length}`);
  
  // Create HTML content
  let html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>HTML Preview</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; padding: 0; background-color: white; }
    h1 { color: #333; text-align: center; margin-bottom: 30px; }
    .banner-section { margin-bottom: 40px; background-color: #f5f5f5; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    iframe { border: 1px solid #ccc; background-color: white; display: inline-block; vertical-align: top; margin: 0 10px; }
    .row { display: flex; justify-content: center; align-items: flex-start; flex-wrap: wrap; }
    .col { padding: 10px; text-align: center; }
    .horizontal-units { padding-bottom: 50px; }
  </style>
</head>
<body>
  <h1>Bang Bust HTML Preview</h1>
  
  <div class="banner-section">
    <div class="row"><div class="col">`;

  // Add vertical banners
  verticalBanners.forEach(banner => {
    html += `
      <div>
        <h3>${banner.size}</h3>
        <iframe src="${banner.path}" width="${banner.width}" height="${banner.height}" title="${banner.size} Banner"></iframe>
      </div>`;
  });
  
  // Add horizontal banners in a column
  if (horizontalBanners.length > 0) {
    html += `
      </div>
      <div class="col">`;
      
    horizontalBanners.forEach(banner => {
      html += `
        <div class="horizontal-units">
          <h3>${banner.size}</h3>
          <iframe src="${banner.path}" width="${banner.width}" height="${banner.height}" title="${banner.size} Banner"></iframe>
        </div>`;
    });
    
    html += `
      </div>`;
  }
  
  html += `
    </div>
  </div>
</body>
</html>`;

  // Write the HTML file
  const outputFile = path.join(rootDir, 'preview-generated.html');
  console.log(`Writing HTML to file: ${outputFile}`);
  
  fs.writeFileSync(outputFile, html);
  console.log('Preview HTML file created successfully: preview-generated.html');
  
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}
