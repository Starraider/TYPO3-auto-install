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
    textMain: "#1e293b",
    textMuted: "#64748b",
    textSubtle: "#94a3b8",
    textHeading: "#0f172a",

    // Borders & Dividers
    borderSubtle: "#e2e8f0",
    borderHover: "#cbd5e1",

    // Sticky Top Navigation
    headerBg: "rgba(255, 255, 255, 0.88)",
    headerBorder: "#e2e8f0",
    headerTitle: "#0f172a",
    navLink: "#334155",
    navLinkHover: "#2563eb",
    navLinkActive: "#2563eb",

    // Footer
    footerBg: "#0f172a",
    footerText: "#94a3b8",
    footerBorder: "#1e293b",
    footerLink: "#cbd5e1",
    footerLinkHover: "#ffffff",

    // Layout, Typography & Metrics
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
    containerMaxWidth: "1200px",
    radiusSm: "4px",
    radiusMd: "8px",
    radiusLg: "12px",
});
