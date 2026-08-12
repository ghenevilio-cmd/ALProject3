console.log('BC StartupScript executed. Mounting Receiving React App...');

function tryMountApp() {
  if (typeof window.mountReceivingApp === 'function') {
    console.log('mountReceivingApp found, mounting...');
    window.mountReceivingApp();
  } else {
    console.warn('Receiving app bundle not loaded yet, retrying in 100ms...');
    setTimeout(tryMountApp, 100);
  }
}

// Start trying to mount the app
tryMountApp();
