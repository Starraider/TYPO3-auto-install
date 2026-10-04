import "../CSS/main.css";
import "./Stylex/Site.stylex.js";
import "./main.js";

// TYPO3 renders the HTML, so Vite cannot inject StyleX's development CSS.
if (import.meta.env.DEV) {
    const linkId = "__stylex_dev_css__";
    let link = document.getElementById(linkId);
    if (!link) {
        link = document.createElement("link");
        link.id = linkId;
        link.rel = "stylesheet";
        document.head.appendChild(link);
    }
    const cssUrl = `${new URL(import.meta.url).origin}/virtual:stylex.css`;
    link.href = cssUrl;
    const refresh = () => { link.href = `${cssUrl}?t=${Date.now()}`; };
    import.meta.hot?.on("stylex:css-update", refresh);
    import.meta.hot?.on("vite:afterUpdate", refresh);
}
