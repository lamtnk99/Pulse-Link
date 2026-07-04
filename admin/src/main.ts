import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

// Monkey-patch window.fetch to automatically inject the Sanctum API token
const originalFetch = window.fetch
window.fetch = async (input, init) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    init = init || {}
    const headers = new Headers(init.headers || {})
    if (!headers.has('Authorization')) {
      headers.set('Authorization', `Bearer ${token}`)
    }
    init.headers = headers
  }
  return originalFetch(input, init)
}

createApp(App).mount('#app')
