import * as stylex from "@stylexjs/stylex";
import { tokens } from "./tokens.stylex.js";

export const styles = stylex.create({
    // Global layout envelope
    wrapper: {
        display: "flex",
        flexDirection: "column",
        minHeight: "100vh",
        backgroundColor: tokens.bgPage,
    },
    shell: {
        flexGrow: 1,
        flexShrink: 0,
        flexBasis: "auto",
        width: "100%",
        backgroundColor: tokens.bgPage,
        color: tokens.textMain,
        boxSizing: "border-box",
        position: "relative",
        zIndex: 1,
    },
    content: {
        width: "100%",
        paddingTop: {
            default: "1.5rem",
            "@media (min-width: 768px)": "2.5rem",
        },
        paddingBottom: {
            default: "2rem",
            "@media (min-width: 768px)": "3.5rem",
        },
    },
    container: {
        width: "100%",
        maxWidth: tokens.containerMaxWidth,
        marginLeft: "auto",
        marginRight: "auto",
        paddingLeft: {
            default: "1rem",
            "@media (min-width: 768px)": "2rem",
        },
        paddingRight: {
            default: "1rem",
            "@media (min-width: 768px)": "2rem",
        },
        boxSizing: "border-box",
    },

    // Sticky Top Navigation & Header
    header: {
        position: "sticky",
        top: 0,
        zIndex: 1020,
        width: "100%",
        backgroundColor: tokens.headerBg,
        backdropFilter: "blur(12px)",
        WebkitBackdropFilter: "blur(12px)",
        borderBottomWidth: 1,
        borderBottomStyle: "solid",
        borderBottomColor: tokens.headerBorder,
        boxShadow: "0 2px 10px rgba(0, 0, 0, 0.04)",
        transitionProperty: "background-color, box-shadow",
        transitionDuration: "200ms",
        transitionTimingFunction: "ease",
    },
    headerContainer: {
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        minHeight: "70px",
        position: "relative",
    },
    headerBranding: {
        display: "flex",
        alignItems: "center",
        flexShrink: 0,
    },
    headerLogo: {
        display: "inline-flex",
        alignItems: "center",
        gap: "0.5rem",
        textDecoration: "none",
    },
    headerTitle: {
        fontSize: "1.25rem",
        fontWeight: 700,
        letterSpacing: "-0.02em",
        color: {
            default: tokens.headerTitle,
            ":hover": tokens.primary,
        },
        transitionProperty: "color",
        transitionDuration: "150ms",
        transitionTimingFunction: "ease",
    },
    headerToggle: {
        display: {
            default: "flex",
            "@media (min-width: 768px)": "none",
        },
        flexDirection: "column",
        justifyContent: "space-around",
        width: "38px",
        height: "38px",
        paddingTop: "8px",
        paddingBottom: "8px",
        paddingLeft: "8px",
        paddingRight: "8px",
        backgroundColor: "transparent",
        borderWidth: 1,
        borderStyle: "solid",
        borderColor: {
            default: tokens.borderSubtle,
            ":hover": tokens.borderHover,
        },
        borderRadius: tokens.radiusMd,
        cursor: "pointer",
        transitionProperty: "border-color, background-color",
        transitionDuration: "150ms",
        transitionTimingFunction: "ease",
    },
    headerToggleBar: {
        width: "100%",
        height: "2px",
        backgroundColor: tokens.textMain,
        borderRadius: "2px",
        transitionProperty: "transform, opacity",
        transitionDuration: "200ms",
        transitionTimingFunction: "ease",
    },

    // Navigation Menu
    nav: {
        position: {
            default: "absolute",
            "@media (min-width: 768px)": "static",
        },
        top: {
            default: "100%",
            "@media (min-width: 768px)": "auto",
        },
        left: {
            default: 0,
            "@media (min-width: 768px)": "auto",
        },
        right: {
            default: 0,
            "@media (min-width: 768px)": "auto",
        },
        zIndex: {
            default: 1000,
            "@media (min-width: 768px)": "auto",
        },
        backgroundColor: {
            default: tokens.bgSurface,
            "@media (min-width: 768px)": "transparent",
        },
        borderBottomWidth: {
            default: 1,
            "@media (min-width: 768px)": 0,
        },
        borderBottomStyle: {
            default: "solid",
            "@media (min-width: 768px)": "none",
        },
        borderBottomColor: {
            default: tokens.borderSubtle,
            "@media (min-width: 768px)": "transparent",
        },
        boxShadow: {
            default: "0 4px 6px -1px rgba(0, 0, 0, 0.07)",
            "@media (min-width: 768px)": "none",
        },
        paddingTop: {
            default: "0.75rem",
            "@media (min-width: 768px)": 0,
        },
        paddingBottom: {
            default: "0.75rem",
            "@media (min-width: 768px)": 0,
        },
        paddingLeft: {
            default: "1rem",
            "@media (min-width: 768px)": 0,
        },
        paddingRight: {
            default: "1rem",
            "@media (min-width: 768px)": 0,
        },
        display: {
            default: "none",
            "@media (min-width: 768px)": "flex",
        },
        alignItems: {
            default: "stretch",
            "@media (min-width: 768px)": "center",
        },
    },
    navList: {
        display: "flex",
        flexDirection: {
            default: "column",
            "@media (min-width: 768px)": "row",
        },
        gap: {
            default: "0.25rem",
            "@media (min-width: 768px)": "0.375rem",
        },
        listStyle: "none",
        margin: 0,
        padding: 0,
        alignItems: {
            default: "stretch",
            "@media (min-width: 768px)": "center",
        },
    },
    navItem: {
        margin: 0,
        padding: 0,
    },
    navLink: {
        display: "flex",
        alignItems: "center",
        paddingTop: "0.5rem",
        paddingBottom: "0.5rem",
        paddingLeft: "0.875rem",
        paddingRight: "0.875rem",
        fontSize: "0.9375rem",
        fontWeight: 500,
        color: {
            default: tokens.navLink,
            ":hover": tokens.navLinkHover,
        },
        backgroundColor: {
            default: "transparent",
            ":hover": tokens.bgHover,
        },
        textDecoration: "none",
        borderRadius: tokens.radiusMd,
        transitionProperty: "color, background-color",
        transitionDuration: "150ms",
        transitionTimingFunction: "ease",
    },
    navLinkActive: {
        color: tokens.navLinkActive,
        backgroundColor: tokens.primaryActiveBg,
        fontWeight: 600,
    },

    // Footer with distinct color & separated spacing
    footer: {
        width: "100%",
        marginTop: "auto",
        backgroundColor: tokens.footerBg,
        color: tokens.footerText,
        borderTopWidth: 1,
        borderTopStyle: "solid",
        borderTopColor: tokens.footerBorder,
        paddingTop: {
            default: "2.5rem",
            "@media (min-width: 768px)": "3.5rem",
        },
        paddingBottom: {
            default: "2.5rem",
            "@media (min-width: 768px)": "3.5rem",
        },
    },
    footerContainer: {
        display: "flex",
        flexDirection: {
            default: "column",
            "@media (min-width: 768px)": "row",
        },
        justifyContent: {
            default: "flex-start",
            "@media (min-width: 768px)": "space-between",
        },
        alignItems: {
            default: "flex-start",
            "@media (min-width: 768px)": "center",
        },
        gap: "1.25rem",
    },
    footerCopyright: {
        margin: 0,
        fontSize: "0.875rem",
        color: tokens.footerText,
        lineHeight: 1.5,
    },
    footerNav: {
        display: "flex",
    },
    footerNavList: {
        display: "flex",
        flexWrap: "wrap",
        gap: "1.25rem",
        listStyle: "none",
        margin: 0,
        padding: 0,
    },
    footerNavItem: {
        margin: 0,
        padding: 0,
    },
    footerNavLink: {
        fontSize: "0.875rem",
        color: {
            default: tokens.footerLink,
            ":hover": tokens.footerLinkHover,
        },
        textDecoration: {
            default: "none",
            ":hover": "underline",
        },
        transitionProperty: "color",
        transitionDuration: "150ms",
        transitionTimingFunction: "ease",
    },

    // Layout Pages & Components
    layoutDefault: {
        width: "100%",
    },
    layoutSubpage: {
        width: "100%",
    },
    subpageBody: {
        display: "flex",
        flexDirection: {
            default: "column",
            "@media (min-width: 768px)": "row",
        },
        gap: {
            default: "2rem",
            "@media (min-width: 768px)": "2.5rem",
        },
        paddingTop: "1.25rem",
    },
    subpageContent: {
        flexGrow: 1,
        flexShrink: 1,
        flexBasis: {
            default: "auto",
            "@media (min-width: 768px)": "68%",
        },
        minWidth: 0,
    },
    subpageSidebar: {
        flexGrow: 0,
        flexShrink: 0,
        flexBasis: {
            default: "auto",
            "@media (min-width: 768px)": "28%",
        },
        minWidth: 0,
    },
    breadcrumb: {
        paddingTop: "1rem",
        paddingBottom: "0.5rem",
    },
    breadcrumbList: {
        display: "flex",
        flexWrap: "wrap",
        alignItems: "center",
        gap: "0.5rem",
        listStyle: "none",
        margin: 0,
        padding: 0,
        fontSize: "0.875rem",
        color: tokens.textMuted,
    },
    breadcrumbItem: {
        display: "flex",
        alignItems: "center",
        gap: "0.5rem",
    },
    breadcrumbLink: {
        color: {
            default: tokens.textMuted,
            ":hover": tokens.primary,
        },
        textDecoration: "none",
        transitionProperty: "color",
        transitionDuration: "150ms",
        transitionTimingFunction: "ease",
    },
    breadcrumbCurrent: {
        color: tokens.textHeading,
        fontWeight: 600,
    },
    stage: {
        width: "100%",
        marginBottom: "2rem",
    },
    stageBanner: {
        width: "100%",
    },
});
