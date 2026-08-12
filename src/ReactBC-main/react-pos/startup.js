// startup.js
console.log("BC StartupScript executed. Mounting React App...");

if (typeof window.mountReactApp === 'function') {
    window.mountReactApp();
} else {
    console.error("React app bundle not found. Ensures Scripts property is correct in AL.");
}

// Note: We do NOT call ControlAddInReady here.
// It is called from inside App.jsx's useEffect to ensure React is fully mounted first.
