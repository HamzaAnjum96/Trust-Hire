#!/usr/bin/env node
// Look at the web build the way a person would, through Flutter's semantics
// tree rather than by clicking coordinates read off a screenshot.
//
// Flutter draws to a canvas, so there is no DOM text to find and a click by
// position silently lands on nothing when a layout shifts. Turning semantics
// on gives every control a node with its label, and this taps those. Labels
// are named by their ARB key ("@navProfile"), so one script works in English
// and Urdu.
//
// Serve the build under its base href first (see the README, "Looking at the
// running app"), then:
//
//   node tool/look_web.js                       # the standard set, every preset
//   node tool/look_web.js --only phone,desktop  # some presets
//   node tool/look_web.js --steps my.json       # your own steps
//   node tool/look_web.js --smoke               # CI: fail on any error
//
// Options:
//   --url <url>     default http://localhost:8099/Trust-Hire/
//   --out <dir>     default build/look
//   --only <a,b>    presets to run (default: all)
//   --steps <file>  a JSON array of steps, instead of the standard set
//   --smoke         phone only, no screenshots unless --out is given; exits 1
//                   on a page error, a console error, a failed request to the
//                   site itself, or a step whose control is not found
//
// Steps:
//   {"shot": "name"}          screenshot to <out>/<preset>-<name>.png
//   {"tap": "@key"}           tap the smallest node whose label contains the
//                             ARB string for key (or plain text, without @)
//   {"tapMatch": "regex"}     tap the smallest node whose label matches
//   {"optional": true}        on a tap step: carry on quietly if not found
//   {"key": "Escape"}         press a key
//   {"type": "text"}          type text
//   {"wait": 800}             wait, in milliseconds
//   {"scroll": 600}           mouse-wheel scroll at the centre
//   {"dump": true}            print every visible labelled node
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const PRESETS = {
  // The phone the app is designed for.
  phone: { width: 390, height: 844 },
  // Portrait tablet: the rail without its labels.
  tablet: { width: 768, height: 1024 },
  // Chrome on Android with "Desktop site" ticked lays out at 980px and shows
  // it at roughly 40%, so a phone user can land on the rail layout. The
  // height is a 390x844 phone's screen at that scale.
  'desktop-site': { width: 980, height: 2120 },
  desktop: { width: 1440, height: 900 },
  'phone-dark': { width: 390, height: 844, colorScheme: 'dark' },
  'phone-urdu': { width: 390, height: 844, locale: 'ur-PK' },
  'desktop-dark': { width: 1440, height: 900, colorScheme: 'dark' },
};

// The standard set: every destination, the list, and one job opened.
const STANDARD = [
  { shot: 'intro' },
  { tap: '@onboardSkip' },
  { shot: 'jobs' },
  { tap: '@showAsList', optional: true },
  { shot: 'list' },
  // A job row's label carries its fare.
  { tapMatch: 'Rs\\.|روپے' },
  { shot: 'job' },
  { key: 'Escape' },
  { tap: '@navActivity' },
  { shot: 'activity' },
  { tap: '@navDirectory' },
  { shot: 'directory' },
  { tap: '@navProfile' },
  { shot: 'profile' },
];

function parseArgs(argv) {
  const args = { url: 'http://localhost:8099/Trust-Hire/', out: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--smoke') args.smoke = true;
    else if (a === '--url') args.url = argv[++i];
    else if (a === '--out') args.out = argv[++i];
    else if (a === '--only') args.only = argv[++i].split(',');
    else if (a === '--steps') args.steps = argv[++i];
    else throw new Error(`unknown option ${a}`);
  }
  return args;
}

function strings(locale) {
  const lang = locale && locale.startsWith('ur') ? 'ur' : 'en';
  const dir = path.join(__dirname, '..', 'lib', 'l10n');
  const en = JSON.parse(fs.readFileSync(path.join(dir, 'app_en.arb'), 'utf8'));
  if (lang === 'en') return en;
  const ur = JSON.parse(fs.readFileSync(path.join(dir, 'app_ur.arb'), 'utf8'));
  return { ...en, ...ur };
}

async function look(browser, name, preset, steps, args, problems) {
  const context = await browser.newContext({
    viewport: { width: preset.width, height: preset.height },
    deviceScaleFactor: 1,
    colorScheme: preset.colorScheme || 'light',
    locale: preset.locale || 'en-GB',
  });
  const page = await context.newPage();
  const origin = new URL(args.url).origin;
  const problem = (kind, text) => {
    problems.push(`${name}: ${kind}: ${text}`);
    console.log(`  ${kind}: ${text}`);
  };
  page.on('pageerror', (e) => problem('page error', e.message));
  page.on('console', (m) => {
    if (m.type() === 'error') problem('console error', m.text());
  });
  // Only the site's own files: map tiles come from elsewhere and a sandbox
  // may block them, which is the network, not the app.
  page.on('requestfailed', (r) => {
    if (r.url().startsWith(origin)) problem('request failed', r.url());
  });
  page.on('response', (r) => {
    if (r.url().startsWith(origin) && r.status() >= 400) {
      problem(`HTTP ${r.status()}`, r.url());
    }
  });

  const text = strings(preset.locale);
  const resolve = (want) =>
    want.startsWith('@') ? text[want.slice(1)] || want : want;

  await page.goto(args.url, { waitUntil: 'load' });
  // The boot screen removes itself on Flutter's first frame.
  await page.waitForFunction(() => !document.getElementById('boot'), null, {
    timeout: 90000,
  });
  await page.waitForTimeout(1500);
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (placeholder) placeholder.click();
  });
  await page.waitForTimeout(800);

  const nodes = () =>
    page.evaluate(() => {
      const out = [];
      for (const el of document.querySelectorAll('flt-semantics')) {
        const r = el.getBoundingClientRect();
        if (r.width === 0 || r.height === 0) continue;
        // On screen only: a list keeps rows built below the fold, and a
        // click there lands on nothing.
        const cx = r.x + r.width / 2;
        const cy = r.y + r.height / 2;
        if (cx < 0 || cy < 0 || cx > innerWidth || cy > innerHeight) continue;
        const label = (el.getAttribute('aria-label') || el.innerText || '')
          .trim();
        if (!label) continue;
        out.push({
          label,
          role: el.getAttribute('role') || '',
          x: r.x + r.width / 2,
          y: r.y + r.height / 2,
          area: r.width * r.height,
        });
      }
      return out;
    });

  for (const step of steps) {
    if (step.tap || step.tapMatch) {
      const want = step.tap ? resolve(step.tap) : new RegExp(step.tapMatch);
      const found = (await nodes())
        .filter((n) =>
          typeof want === 'string' ? n.label.includes(want) : want.test(n.label),
        )
        .sort((a, b) => a.area - b.area);
      const node = found[step.nth || 0];
      if (!node) {
        const what = step.tap || step.tapMatch;
        if (step.optional) console.log(`  (no ${what}; carrying on)`);
        else problem('not found', what);
        continue;
      }
      await page.mouse.click(node.x, node.y);
      // Off the page again, or the control's tooltip is in every shot.
      await page.mouse.move(-1, -1);
      await page.waitForTimeout(step.after || 1200);
    }
    if (step.key) {
      await page.keyboard.press(step.key);
      await page.waitForTimeout(700);
    }
    if (step.type) {
      await page.keyboard.type(step.type);
      await page.waitForTimeout(400);
    }
    if (step.wait) await page.waitForTimeout(step.wait);
    if (step.scroll) {
      await page.mouse.move(preset.width / 2, preset.height / 2);
      await page.mouse.wheel(0, step.scroll);
      await page.waitForTimeout(700);
    }
    if (step.dump) {
      for (const n of await nodes()) {
        const label = n.label.replace(/\s+/g, ' ').slice(0, 90);
        console.log(`  ${Math.round(n.x)},${Math.round(n.y)} [${n.role}] ${label}`);
      }
    }
    if (step.shot && args.out) {
      await page.waitForTimeout(500);
      const file = path.join(args.out, `${name}-${step.shot}.png`);
      await page.screenshot({ path: file });
      console.log(`  ${file}`);
    }
  }
  await context.close();
}

(async () => {
  const args = parseArgs(process.argv.slice(2));
  if (!args.smoke && !args.out) args.out = path.join('build', 'look');
  if (args.out) fs.mkdirSync(args.out, { recursive: true });

  const names = args.smoke ? ['phone'] : args.only || Object.keys(PRESETS);
  const steps = args.steps
    ? JSON.parse(fs.readFileSync(args.steps, 'utf8'))
    : STANDARD;

  const browser = await chromium.launch();
  const problems = [];
  for (const name of names) {
    const preset = PRESETS[name];
    if (!preset) throw new Error(`unknown preset ${name}`);
    console.log(`${name} (${preset.width}x${preset.height})`);
    await look(browser, name, preset, steps, args, problems);
  }
  await browser.close();

  if (problems.length) {
    console.log(`\n${problems.length} problem(s):`);
    for (const p of problems) console.log(`  ${p}`);
    if (args.smoke) process.exit(1);
  } else {
    console.log('\nNo problems.');
  }
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
