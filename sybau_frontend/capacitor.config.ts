import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.didimdynamics.sybau',
  appName: 'SYBAU',
  webDir: 'dist',
  server: {
    // Allow mixed content (http) during development
    // Remove or set to false for production with HTTPS backend
    cleartext: true,
  },
  plugins: {
    StatusBar: {
      backgroundColor: '#0f0c29',
      style: 'LIGHT',
      overlaysWebView: false,
    },
    SplashScreen: {
      launchAutoHide: true,
      launchShowDuration: 2000,
      backgroundColor: '#0f0c29',
      showSpinner: false,
    },
  },
  android: {
    // Allow HTTP traffic for development
    allowMixedContent: true,
  },
};

export default config;
