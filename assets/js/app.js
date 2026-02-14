// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/ohmyword"
import topbar from "../vendor/topbar"

const Hooks = {
  CharInputGroup: {
    mounted() {
      this.setupInputs()
      if (this.el.dataset.autofocus === "true") {
        this.el.querySelector('[data-char-idx="0"]')?.focus()
      }
    },
    updated() {
      const readonly = this.el.dataset.readonly === "true"
      this.el.querySelectorAll('input[data-char-idx]').forEach(el => {
        el.readOnly = readonly
      })
    },
    getAdjacentGroup(direction) {
      const form = this.el.closest('form')
      if (!form) return null
      const groups = Array.from(form.querySelectorAll('[phx-hook="CharInputGroup"]'))
      const idx = groups.indexOf(this.el)
      return groups[idx + direction] || null
    },
    setupInputs() {
      const chars = this.el.querySelectorAll('input[data-char-idx]')
      const hidden = this.el.querySelector('input[type="hidden"]')

      const syncHidden = () => {
        hidden.value = Array.from(chars).map(c => c.value).join('')
      }

      chars.forEach((input, i) => {
        input.addEventListener('input', () => {
          if (input.value.length > 0) {
            input.value = input.value.slice(-1)
            syncHidden()
            if (i < chars.length - 1) {
              chars[i + 1].focus()
            } else {
              // Last char of word — jump to next word
              const next = this.getAdjacentGroup(1)
              if (next) next.querySelector('[data-char-idx="0"]')?.focus()
            }
          }
        })
        input.addEventListener('keydown', (e) => {
          if (e.key === 'Backspace') {
            if (input.value === '' && i > 0) {
              chars[i - 1].focus()
              chars[i - 1].value = ''
              syncHidden()
              e.preventDefault()
            } else if (input.value === '' && i === 0) {
              // First char of word — jump to previous word's last char
              const prev = this.getAdjacentGroup(-1)
              if (prev) {
                const prevChars = prev.querySelectorAll('input[data-char-idx]')
                const last = prevChars[prevChars.length - 1]
                if (last) {
                  last.focus()
                  last.value = ''
                  prev.querySelector('input[type="hidden"]').value =
                    Array.from(prevChars).map(c => c.value).join('')
                }
              }
              e.preventDefault()
            }
          }
          if (e.key === 'ArrowLeft') {
            if (i > 0) {
              chars[i - 1].focus()
            } else {
              const prev = this.getAdjacentGroup(-1)
              if (prev) {
                const prevChars = prev.querySelectorAll('input[data-char-idx]')
                prevChars[prevChars.length - 1]?.focus()
              }
            }
          }
          if (e.key === 'ArrowRight') {
            if (i < chars.length - 1) {
              chars[i + 1].focus()
            } else {
              const next = this.getAdjacentGroup(1)
              if (next) next.querySelector('[data-char-idx="0"]')?.focus()
            }
          }
        })
        input.addEventListener('focus', () => input.select())
      })
    }
  },
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...Hooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

