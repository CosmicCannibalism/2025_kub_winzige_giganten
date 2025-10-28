# 🎨 Customization Guide - Make It Your Own!

**Easy guide to customize the exhibition for your content**

No coding experience needed for basic customization. For advanced changes, some HTML/CSS knowledge helps.

---

## 🎬 Easy: Change Videos

### Step 1: Prepare Your Videos

**Video Requirements:**
- **Format**: MP4 (H.264 codec)
- **Resolution**: 1080p or 720p recommended
- **Size**: Keep under 200MB per video for smooth loading
- **Orientation**: Any (portrait/landscape/square)

**Converting Videos:**
1. Use [HandBrake](https://handbrake.fr/) (free tool)
2. Preset: "Fast 1080p30" or "Fast 720p30"
3. Format: MP4
4. Click "Start Encode"

### Step 2: Access the Pi Files

**Option A: Via Computer (Easier)**
1. Remove SD card from Pi
2. Insert into computer with SD card reader
3. Open the SD card
4. Navigate to: `/home/cosmic/site/videos/`

**Option B: Via SSH (If Pi is running)**
```bash
ssh cosmic@cosmicpi.local
# Password: (your Pi password)
cd /home/cosmic/site/videos/
```

### Step 3: Replace Videos

1. **Backup old videos** (just in case!)
   - Copy `main.mp4` and `teaser.mp4` somewhere safe

2. **Upload your new videos**
   - Rename your videos to:
     - `main.mp4` (main exhibition video)
     - `teaser.mp4` (preview/teaser video)
   
3. **Copy to Pi**
   - Replace the old files with your new files
   - Keep the same filenames!

4. **Test it**
   - Reconnect SD card to Pi and power on
   - Connect iPad and check videos play

---

## 📝 Easy: Change Text and Titles

### What You Can Change
- Exhibition title
- Button text
- Instructions
- Welcome messages

### How to Edit

1. **Find the HTML file** you want to edit:
   - `index.html` - iPad 1 (main page)
   - `index01.html` - iPad 2
   - `index02.html` - iPad 3

2. **Open in text editor**
   - Mac: TextEdit (set to "Plain Text" mode)
   - Windows: Notepad
   - Better: VS Code (free, easier)

3. **Find and change text**

Look for sections like this:
```html
<h1>Winzige Giganten</h1>
```

Change "Winzige Giganten" to your exhibition name:
```html
<h1>My Amazing Exhibition</h1>
```

4. **Save the file**

5. **Test on iPad**

### Common Text Changes

**Change Page Title:**
```html
<title>Winzige Giganten</title>
→ Change to:
<title>Your Exhibition Name</title>
```

**Change Welcome Text:**
```html
<p>Welcome to our exhibition...</p>
→ Change to:
<p>Your custom welcome message...</p>
```

**Change Button Text:**
```html
<button>Play Video</button>
→ Change to:
<button>Watch Now</button>
```

---

## 🎨 Easy: Change Colors

### Simple Color Changes

Open `style.css` and look for color codes (they start with `#` or are named colors):

**Change Background Color:**
```css
body {
    background-color: #000000;  /* Black */
}
```

Change to:
```css
body {
    background-color: #FFFFFF;  /* White */
}
```

**Common Colors:**
- `#000000` - Black
- `#FFFFFF` - White
- `#FF0000` - Red
- `#00FF00` - Green
- `#0000FF` - Blue
- `#FFD700` - Gold

**Pro tip**: Use [Google Color Picker](https://g.co/kgs/colorpicker) to find color codes!

---

## 🖼️ Medium: Change Icons

The PWA icon appears on the iPad homescreen after installation.

### Step 1: Create Your Icon

**Requirements:**
- Square image (same width and height)
- PNG format
- Three sizes needed:
  - 192x192 pixels
  - 512x512 pixels  
  - 1024x1024 pixels

**Tools:**
- [Canva](https://canva.com) - Easy online designer
- Photoshop/GIMP - Advanced editing
- [Icon Generator](https://www.pwabuilder.com/imageGenerator) - Automatic resizing

### Step 2: Replace Icons

1. Go to the `icons/` folder
2. Replace these files:
   - `icon-192.png` (192x192)
   - `icon-512.png` (512x512)
   - `icon-1024.png` (1024x1024)
3. Keep the exact same filenames!

### Step 3: Update manifest.json

If you want to change the app name that appears on homescreen:

```json
{
  "name": "Winzige Giganten",
  "short_name": "Giganten"
}
```

Change to:
```json
{
  "name": "Your Exhibition Name",
  "short_name": "Your App"
}
```

---

## 📡 Medium: Change WiFi Name and Password

### Edit the Configuration

**Via SSH:**
```bash
ssh cosmic@cosmicpi.local
sudo nano /etc/hostapd/hostapd.conf
```

**Find and change:**
```
ssid=winzige_giganten
wpa_passphrase=winzigegiganten
```

**To your preferred:**
```
ssid=your_exhibition_name
wpa_passphrase=your_password
```

**Save and reboot:**
```bash
sudo reboot
```

### Important Notes
- **SSID** (WiFi name): No spaces, keep it simple
- **Password**: Minimum 8 characters
- **Test thoroughly** after changing!

---

## 🎯 Advanced: Multiple Video Pages

Want different video content on different iPads?

### For iPad 1 (index.html)
```html
<video src="videos/main.mp4"></video>
```

### For iPad 2 (index01.html)
```html
<video src="videos/artwork1.mp4"></video>
```

### For iPad 3 (index02.html)
```html
<video src="videos/artwork2.mp4"></video>
```

Just upload your additional videos to the `videos/` folder and reference them!

---

## 🔧 Advanced: Add More Pages

Want more than 3 iPad pages?

1. **Copy an existing HTML file**
   ```bash
   cp index.html index03.html
   ```

2. **Update the manifest reference**
   ```bash
   cp manifest.json manifest03.json
   ```

3. **Edit index03.html**
   - Change manifest link to `manifest03.json`
   - Change video sources
   - Customize content

4. **Access on iPad**
   - Navigate to: `192.168.4.1/index03.html`

5. **Update device limit** (if needed)
   - See [Technical Reference](../technical/TECHNICAL_REFERENCE.md)

---

## 📱 Advanced: Custom Styling

### Change Fonts

Add to `style.css`:
```css
body {
    font-family: 'Arial', sans-serif;
}

h1 {
    font-family: 'Georgia', serif;
}
```

### Change Layout

Modify spacing, sizing in `style.css`:
```css
.video-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}
```

### Add Animations

```css
.fade-in {
    animation: fadeIn 1s;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}
```

---

## ⚠️ Things to Avoid

**Don't:**
- Change file structure (keep files in same folders)
- Rename core files (`script.js`, `sw.js`, `style.css`)
- Delete the `manifest.json` files
- Use videos larger than 500MB (slow loading)
- Change system files unless you know what you're doing

**Do:**
- Make backups before changing anything!
- Test on one iPad before deploying to exhibition
- Keep original files safe
- Document your changes

---

## 🧪 Testing Your Changes

### Checklist
- [ ] Save all edited files
- [ ] Copy files back to SD card (if editing offline)
- [ ] Power on Pi
- [ ] Connect iPad to WiFi
- [ ] Load page in Safari
- [ ] Check all text appears correctly
- [ ] Check videos load and play
- [ ] Test offline mode (turn off WiFi)
- [ ] Install PWA to homescreen
- [ ] Open from homescreen icon
- [ ] Verify icon and name are correct

---

## 💾 Backup Your Customizations

### Create SD Card Backup

**After you've customized everything:**

1. Remove SD card from Pi
2. Insert into computer
3. Use Raspberry Pi Imager:
   - Choose "Use custom"
   - Read from SD card
   - Save as `.img` file
4. Keep this backup safe!

**Now you can:**
- Restore if something breaks
- Clone to multiple Pis
- Share your custom version

---

## 📚 Need More Help?

### Resources
- **HTML Basics**: [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/HTML)
- **CSS Basics**: [CSS-Tricks](https://css-tricks.com/)
- **Video Conversion**: [HandBrake Guide](https://handbrake.fr/docs/)

### Community
- Open an issue on GitHub
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**🎨 Happy Customizing!**

*Remember: Start simple, test often, keep backups!*