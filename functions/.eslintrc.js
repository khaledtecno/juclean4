module.exports = {
  env: {
    es2021: true,
    node: true,
  },
  extends: ["eslint:recommended"],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: "module",
  },
  rules: {
    quotes: ["error", "double"],
    "max-len": ["error", {code: 1000}],
    "object-curly-spacing": ["error", "never"],
    indent: ["error", 2],
    "no-multi-spaces": "error",
    "comma-dangle": ["error", "always-multiline"],
    "new-cap": "off",
  },
};
