// Translates the Trix toolbar with the texts from config/locales (meta tag in the layout head).
// Trix defines its elements on the next tick and builds the toolbar from Trix.config.lang,
// so the object must be updated in place right after `import "trix"`.
const meta = document.querySelector('meta[name="rich-text-editor-lang"]')

if (meta && window.Trix) {
  Object.assign(window.Trix.config.lang, JSON.parse(meta.content))
}
