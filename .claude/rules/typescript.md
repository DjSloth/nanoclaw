---
paths:
  - src/**
  - container/**
---
# TypeScript Rules

- Strict mode is enabled — zero `any` types, use `unknown` + type guards
- No default exports
- All async functions must handle errors explicitly
- Run `npm run build` after every change to verify zero TypeScript errors
- Do not add type annotations to code you didn't change
