import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

console.error("==== REACT BUNDLE IS EXECUTING ====");

window.mountReactApp = function () {
  console.error("==== mountReactApp CALLED ====");
  let rootElement = document.getElementById('root');
  if (!rootElement) {
    rootElement = document.createElement('div');
    rootElement.id = 'root';
    rootElement.style.height = '100%';

    // BC provides a container with id 'controlAddIn'
    const controlAddIn = document.getElementById('controlAddIn');
    if (controlAddIn) {
      controlAddIn.appendChild(rootElement);
    } else {
      document.body.appendChild(rootElement);
    }
  }

  // 2. Mount React
  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
};

// Automatically inject mock data and mount if we're not inside the BC iframe
if (!window.Microsoft || !window.Microsoft.Dynamics) {
  window.mountReactApp();
  injectMockDataLocally();
}
