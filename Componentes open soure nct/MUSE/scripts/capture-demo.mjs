#!/usr/bin/env node
/**
 * MUSE Demo Animation Capture
 * Captures the HTML terminal animation frame-by-frame using puppeteer-core,
 * then converts to animated GIF/WebP/MP4 via ffmpeg.
 *
 * Prerequisites: npm install puppeteer-core, Google Chrome installed, ffmpeg
 * Usage: node scripts/capture-demo.mjs [--fps 5] [--duration 17]
 */

import puppeteer from 'puppeteer-core';
import { mkdirSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROJECT_ROOT = join(__dirname, '..');

const FRAMES_DIR = '/tmp/muse-demo-frames';
const WIDTH = 960;
const HEIGHT = 580;
const FPS = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--fps') || '5');
const DURATION_S = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--duration') || '17');
const DURATION_MS = DURATION_S * 1000;
const FRAME_INTERVAL = 1000 / FPS;

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const DEMO_HTML = join(PROJECT_ROOT, 'assets', 'demo-source.html');

const OUTPUT = {
    gif: join(PROJECT_ROOT, 'assets', 'demo.gif'),
    webp: join(PROJECT_ROOT, 'assets', 'demo.webp'),
    mp4: join(PROJECT_ROOT, 'assets', 'demo.mp4'),
};

async function main() {
    console.log(`🎬 MUSE Demo Capture — ${FPS}fps × ${DURATION_S}s = ${Math.ceil(DURATION_MS / FRAME_INTERVAL)} frames`);

    // Clean frames dir
    try { execSync(`rm -rf ${FRAMES_DIR}`); } catch { }
    mkdirSync(FRAMES_DIR, { recursive: true });

    // Launch browser
    console.log('🌐 Launching Chrome...');
    const browser = await puppeteer.launch({
        headless: 'new',
        executablePath: CHROME_PATH,
        args: [`--window-size=${WIDTH},${HEIGHT}`, '--no-sandbox'],
    });

    const page = await browser.newPage();
    await page.setViewport({ width: WIDTH, height: HEIGHT, deviceScaleFactor: 2 });

    // Serve demo HTML — use file:// protocol directly
    const demoUrl = existsSync(DEMO_HTML)
        ? `file://${DEMO_HTML}`
        : 'http://localhost:8765/muse-demo.html';

    console.log(`📄 Loading: ${demoUrl}`);
    await page.goto(demoUrl, { waitUntil: 'networkidle0' });
    await new Promise(r => setTimeout(r, 600)); // let animation start

    const totalFrames = Math.ceil(DURATION_MS / FRAME_INTERVAL);
    console.log(`📸 Capturing ${totalFrames} frames...`);

    for (let i = 0; i < totalFrames; i++) {
        const padded = String(i).padStart(4, '0');
        await page.screenshot({
            path: `${FRAMES_DIR}/frame_${padded}.png`,
            clip: { x: 0, y: 0, width: WIDTH, height: HEIGHT },
        });
        if (i % 10 === 0) process.stdout.write(`\r  frame ${i + 1}/${totalFrames}`);
        await new Promise(r => setTimeout(r, FRAME_INTERVAL));
    }
    console.log(`\n✅ Captured ${totalFrames} frames`);

    await browser.close();

    // Generate outputs via ffmpeg
    const palette = `${FRAMES_DIR}/palette.png`;

    console.log('🎨 Creating GIF...');
    execSync(`ffmpeg -y -framerate ${FPS} -i ${FRAMES_DIR}/frame_%04d.png -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" "${OUTPUT.gif}"`, { stdio: 'pipe' });

    console.log('🌐 Creating animated WebP...');
    execSync(`img2webp -d ${Math.round(FRAME_INTERVAL)} -lossy -q 70 ${FRAMES_DIR}/frame_*.png -o "${OUTPUT.webp}"`, { stdio: 'pipe' });

    console.log('🎥 Creating MP4...');
    execSync(`ffmpeg -y -framerate ${FPS} -i ${FRAMES_DIR}/frame_%04d.png -vf "fps=15,scale=${WIDTH}:-1" -c:v libx264 -pix_fmt yuv420p -crf 23 "${OUTPUT.mp4}"`, { stdio: 'pipe' });

    // Report sizes
    console.log('\n📦 Output files:');
    for (const [fmt, path] of Object.entries(OUTPUT)) {
        try {
            const size = execSync(`ls -lh "${path}"`).toString().match(/\s([\d.]+[KMG])\s/)?.[1] || '?';
            console.log(`  ${fmt.toUpperCase().padEnd(4)} → ${path} (${size})`);
        } catch { }
    }

    // Cleanup frames
    execSync(`rm -rf ${FRAMES_DIR}`);
    console.log('\n✨ Done! Demo assets updated.');
}

main().catch(e => { console.error('❌ Error:', e.message); process.exit(1); });
