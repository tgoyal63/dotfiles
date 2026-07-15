import type { FinickyConfig } from "/Applications/Finicky.app/Contents/Resources/finicky.d.ts";

const ZEN = "Zen";
const CHROME = "Google Chrome";
const BRAVE = "Brave Browser";

type BrowserModifier = "control" | "option" | "shift";

const modifierPressed = (modifier: BrowserModifier) => () =>
  finicky.getModifierKeys()[modifier];

const trackingParameters = new Set([
  "dclid",
  "fbclid",
  "gclid",
  "mc_cid",
  "mc_eid",
  "msclkid"
]);

const stripTrackingParameters = (url: URL) => {
  const cleanUrl = new URL(url);

  for (const key of [...cleanUrl.searchParams.keys()]) {
    if (key.startsWith("utm_") || trackingParameters.has(key)) {
      cleanUrl.searchParams.delete(key);
    }
  }

  return cleanUrl;
};

const workChrome = finicky.matchHostnames([
  "meet.google.com",
  "calendar.google.com",
  "mail.google.com",
  "drive.google.com",
  "docs.google.com",
  "sheets.google.com",
  "slides.google.com",
  "forms.google.com",
  "accounts.google.com",
  "admin.google.com",
  "chat.google.com",
  "gemini.google.com",
  "console.cloud.google.com"
]);

const mediaBrave = finicky.matchHostnames([
  /^(.+\.)?youtube\.com$/,
  "youtu.be",
  /^(.+\.)?twitch\.tv$/,
  "open.spotify.com",
  /^(.+\.)?soundcloud\.com$/,
  /^(.+\.)?vimeo\.com$/
]);

export default {
  defaultBrowser: ZEN,
  options: {
    checkForUpdates: true,
    hideIcon: false,
    keepRunning: true,
    logRequests: false
  },
  rewrite: [
    {
      match: (url) => url.protocol === "http:" || url.protocol === "https:",
      url: stripTrackingParameters
    }
  ],
  handlers: [
    // Modifier overrides apply to every URL. Priority: Control, Option, Shift.
    {
      match: modifierPressed("control"),
      browser: ZEN
    },
    {
      match: modifierPressed("option"),
      browser: CHROME
    },
    {
      match: modifierPressed("shift"),
      browser: BRAVE
    },
    {
      match: workChrome,
      browser: CHROME
    },
    {
      match: mediaBrave,
      browser: BRAVE
    }
  ]
} satisfies FinickyConfig;
