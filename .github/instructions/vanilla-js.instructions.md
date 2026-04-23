---
applyTo: "src/**/*.js"
---

# JavaScript Dependency Guidelines

- Use vanilla JavaScript whenever possible. Prefer built-in browser or Node.js APIs over third-party libraries.
- Keep the number of dependencies to an absolute minimum.
- Before introducing any new `npm` dependency, stop and ask the user for confirmation, explaining why it is needed and what alternatives were considered.
- Avoid adding packages that duplicate functionality already available in the standard library or runtime.
