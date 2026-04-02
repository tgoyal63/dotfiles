export default {
  defaultBrowser: "Zen",
  options: {
    hideIcon: false
  },
  handlers: [
    {
      match: /meet\.google\.com/,
      browser: "Google Chrome"
    },
    {
      match: /youtube\.com|youtu\.be/,
      browser: "Brave"
    }
  ]
};