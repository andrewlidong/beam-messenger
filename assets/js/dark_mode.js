class DarkModeManager {
  constructor() {
    this.KEY = 'theme';
    this.DARK_CLASS = 'dark';
    this.init();
  }

  init() {
    const savedTheme = localStorage.getItem(this.KEY);

    if (savedTheme) {
      // If a theme is saved, apply it
      this.applyTheme(savedTheme === this.DARK_CLASS);
    } else if (this.isSystemDark()) {
      // If no theme is saved and system is dark, apply dark mode
      this.applyTheme(true);
    } else {
      // Default to light mode
      this.applyTheme(false);
    }
  }

  toggle() {
    const isCurrentlyDark = document.documentElement.classList.contains(this.DARK_CLASS);
    if (isCurrentlyDark) {
      this.disable();
    } else {
      this.enable();
    }
  }

  enable() {
    this.applyTheme(true);
    localStorage.setItem(this.KEY, this.DARK_CLASS);
  }

  disable() {
    this.applyTheme(false);
    localStorage.setItem(this.KEY, 'light');
  }

  applyTheme(isDark) {
    if (isDark) {
      document.documentElement.classList.add(this.DARK_CLASS);
    } else {
      document.documentElement.classList.remove(this.DARK_CLASS);
    }
  }

  isSystemDark() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
}

// Export a singleton instance of the DarkModeManager
const darkModeManager = new DarkModeManager();

export default darkModeManager;
