import type { FinickyConfig } from "/Applications/Finicky.app/Contents/Resources/finicky.d.ts";

const ZEN = "Zen";
const CHROME = "Google Chrome";
const BRAVE = "Brave Browser";

const workChrome = [
  "meet.google.com/*",
  "calendar.google.com/*",
  "mail.google.com/*",
  "drive.google.com/*",
  "docs.google.com/*",
  "sheets.google.com/*",
  "slides.google.com/*",
  "accounts.google.com/*",
  "admin.google.com/*"
];

const mediaBrave = [
  "youtube.com/*",
  "*.youtube.com/*",
  "youtu.be/*",
  "twitch.tv/*",
  "*.twitch.tv/*",
  "open.spotify.com/*",
  "soundcloud.com/*"
];

const ambiguous = [
  "github.com/*",
  "*.github.com/*",
  "notion.so/*",
  "*.notion.so/*",
  "linear.app/*",
  "*.linear.app/*",
  "figma.com/*",
  "*.figma.com/*",
  "slack.com/*",
  "*.slack.com/*"
];

const browserWithModifierOverride = () => {
  const modifiers = finicky.getModifierKeys();

  if (modifiers.option) return CHROME;
  if (modifiers.shift) return BRAVE;

  return ZEN;
};

export default {
  defaultBrowser: ZEN,
  options: {
    hideIcon: false,
    keepRunning: true
  },
  handlers: [
    {
      match: workChrome,
      browser: CHROME
    },
    {
      match: mediaBrave,
      browser: BRAVE
    },
    {
      // Finicky has no built-in prompt; use Option for Chrome or Shift for Brave.
      match: ambiguous,
      browser: browserWithModifierOverride
    }
  ]
} satisfies FinickyConfig;
