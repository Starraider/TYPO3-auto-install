import fs from "node:fs";
import path from "node:path";
import { parse } from "@babel/parser";

// Read the compiled objects after StyleX transforms them. Fluid uses the
// basename and variant, for example Site.shell, to resolve atomic classes.
export default function stylexManifestPlugin({ outputPath }) {
    const styles = {};
    const sources = new Map();
    let timer;
    let server;

    function write() {
        fs.mkdirSync(path.dirname(outputPath), { recursive: true });
        fs.writeFileSync(outputPath, `${JSON.stringify({ styles }, null, 2)}\n`);
        server?.ws.send({ type: "full-reload" });
    }

    function remove(prefix) {
        for (const key of Object.keys(styles)) {
            if (key.startsWith(`${prefix}.`)) delete styles[key];
        }
    }

    return {
        name: "stylex-manifest",
        enforce: "post",
        configureServer(viteServer) { server = viteServer; },
        buildStart() {
            for (const key of Object.keys(styles)) delete styles[key];
            sources.clear();
        },
        transform(code, id) {
            const filename = id.split("?")[0];
            if (!/\.stylex\.(js|jsx|ts|tsx)$/.test(filename)) return null;
            const prefix = path.basename(filename).replace(/\.stylex\.(js|jsx|ts|tsx)$/, "");
            const canonical = fs.realpathSync(filename);
            if (sources.has(prefix) && sources.get(prefix) !== canonical) {
                this.error(`StyleX sources must have unique basenames: ${prefix}`);
            }
            sources.set(prefix, canonical);
            const previous = JSON.stringify(styles);
            remove(prefix);
            const ast = parse(code, { sourceType: "module", plugins: ["jsx", "typescript"] });
            for (const node of ast.program.body) {
                const declaration = node.type === "ExportNamedDeclaration" ? node.declaration : node;
                if (declaration?.type !== "VariableDeclaration") continue;
                for (const variable of declaration.declarations) {
                    if (variable.init?.type !== "ObjectExpression") continue;
                    for (const variant of variable.init.properties) {
                        if (variant.type !== "ObjectProperty" || variant.value.type !== "ObjectExpression") continue;
                        const properties = {};
                        let compiled = false;
                        for (const property of variant.value.properties) {
                            if (property.type !== "ObjectProperty") continue;
                            const name = property.key.name ?? property.key.value;
                            if (name === "$$css") compiled = true;
                            else if (property.value.type === "StringLiteral") properties[name] = property.value.value;
                        }
                        if (!compiled) continue;
                        const name = variant.key.name ?? variant.key.value;
                        styles[`${prefix}.${name}`] = {
                            className: Object.values(properties).join(" "),
                            properties,
                        };
                    }
                }
            }
            if (JSON.stringify(styles) !== previous) {
                clearTimeout(timer);
                timer = setTimeout(write, 100);
            }
            return null;
        },
        handleHotUpdate({ file }) {
            if (!fs.existsSync(file)) {
                const prefix = path.basename(file).replace(/\.stylex\.(js|jsx|ts|tsx)$/, "");
                if (sources.has(prefix)) {
                    remove(prefix);
                    sources.delete(prefix);
                    clearTimeout(timer);
                    timer = setTimeout(write, 100);
                }
            }
        },
        buildEnd(error) {
            clearTimeout(timer);
            if (!error) write();
        },
        closeBundle() { clearTimeout(timer); },
    };
}
