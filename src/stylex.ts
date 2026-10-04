// The maintained adapter and validator are not in the 1.0.0 tag. Pin the
// published main commit until a tagged release provides both. Only the root
// requirement pins the source reference; the sitepackage requires its branch.
export const STYLEX_CONNECTOR_VERSION = "dev-main";
export const STYLEX_CONNECTOR_REQUIREMENT =
  "skom/stylex-connector:dev-main#701d870b9ae55e8c434af24532b95c10f7e54ef2";

export const STYLEX_VALIDATE_ARGS = [
  "typo3", "stylex:validate", "--required-key", "Site.shell", "--required-key", "Site.content",
];
