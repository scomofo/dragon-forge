import globals from 'globals';

// Focused lint gate: catch the RUNTIME-CRASH class the build/tests miss — namely
// undefined identifiers (no-undef) like the `companionLockedUntilAct` ReferenceError
// that blanked the Hatchery Ring, and undefined JSX components. Deliberately NOT a
// full style ruleset, so CI fails only on real "this will throw at runtime" bugs.
export default [
  {
    files: ['src/**/*.{js,jsx}', 'scripts/**/*.{js,mjs}', '*.config.js'],
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'module',
      parserOptions: { ecmaFeatures: { jsx: true } },
      globals: {
        ...globals.browser,
        ...globals.node,
        // Vitest globals used in *.test.js
        describe: 'readonly',
        it: 'readonly',
        expect: 'readonly',
        vi: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly',
      },
    },
    rules: {
      'no-undef': 'error',
    },
  },
];
