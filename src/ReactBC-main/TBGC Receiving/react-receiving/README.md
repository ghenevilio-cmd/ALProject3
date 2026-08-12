TBGC Receiving React UI

Folder guide:
- `package.json`: frontend build dependencies and scripts
- `vite.config.js`: build output configuration
- `startup.js`: Business Central startup bridge
- `src/main.jsx`: React mount entry
- `src/App.jsx`: main Receiving module screen
- `src/components/`: reusable UI pieces
- `src/data/`: local mock data for browser testing
- `dist/`: generated build output used by the AL control add-in

Build commands:
- `npm install`
- `npm run build`

Important:
- Use the `package.json` in this folder
- Ignore `src/package.json`; it is not the build entry for this app
