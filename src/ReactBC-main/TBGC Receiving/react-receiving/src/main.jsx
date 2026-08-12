import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import App from './App.jsx';

window.mountReceivingApp = function () {
  console.log('mountReceivingApp called');
  let rootElement = document.getElementById('root');

  if (!rootElement) {
    console.log('root element not found, creating it');
    rootElement = document.createElement('div');
    rootElement.id = 'root';
    rootElement.style.width = '100%';
    rootElement.style.height = '100%';
    rootElement.style.display = 'flex';
    rootElement.style.flexDirection = 'column';

    const controlAddIn = document.getElementById('controlAddIn');
    if (controlAddIn) {
      console.log('controlAddIn found, appending root');
      controlAddIn.style.width = '100%';
      controlAddIn.style.height = '100%';
      controlAddIn.style.display = 'flex';
      controlAddIn.style.flexDirection = 'column';
      controlAddIn.appendChild(rootElement);
    } else {
      console.log('controlAddIn not found, appending to body');
      document.body.appendChild(rootElement);
    }
  }

  console.log('Creating React root and rendering');
  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
};

// Auto-mount if not in Business Central (for local dev)
if (!window.Microsoft || !window.Microsoft.Dynamics) {
  console.log('Not in BC, auto-mounting');
  window.mountReceivingApp();
}
