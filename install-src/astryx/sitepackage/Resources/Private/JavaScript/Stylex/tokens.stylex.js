import * as stylex from "@stylexjs/stylex";

export const tokens = stylex.defineVars({
    // Brand & Theme Colors
    primary: "#2563eb",
    primaryHover: "#1d4ed8",
    primaryActiveBg: "#eff6ff",

    // Backgrounds & Surfaces
    bgPage: "#f8fafc",
    bgSurface: "#ffffff",
    bgHover: "#f1f5f9",

    // Text & Content Colors
    textMain: "#15110c",
    textMuted: "#4e606f",
    textSubtle: "#4e606f",
    textHeading: "#15110c",

    // Borders & Dividers
    borderSubtle: "#e2e8f0",
    borderHover: "#cbd5e1",

    // Sticky Top Navigation
    headerBg: "rgba(255, 255, 255, 0.88)",
    headerBorder: "#e2e8f0",
    headerTitle: "#15110c",
    navLink: "#4e606f",
    navLinkHover: "#15110c",
    navLinkActive: "#15110c",

    // Footer
    footerBg: "#0f172a",
    footerText: "#94a3b8",
    footerBorder: "#1e293b",
    footerLink: "#cbd5e1",
    footerLinkHover: "#ffffff",

    // Layout, Typography & Metrics
    fontFamily: "Figtree, \"Figtree Variable\", system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif",
    containerMaxWidth: "1200px",
    radiusSm: "4px",
    radiusMd: "8px",
    radiusLg: "12px",
});
