import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="sidebar"
export default class extends Controller {
    static targets = ['sidebar', 'backdrop', 'button']

    connect() {
        // Tailwind's lg breakpoint, where the sidebar is always on screen.
        this.wideScreen = window.matchMedia('(min-width: 64rem)')
        this.syncInert = this.syncInert.bind(this)
        this.wideScreen.addEventListener('change', this.syncInert)
        this.syncInert()
    }

    disconnect() {
        this.wideScreen.removeEventListener('change', this.syncInert)
    }

    toggle() {
        this.setOpen(!this.isOpen)
    }

    close() {
        if (!this.isOpen) return

        this.setOpen(false)
        this.buttonTarget.focus()
    }

    closeOnOutsideClick(event) {
        if (
            !this.sidebarTarget.contains(event.target) &&
            !this.buttonTarget.contains(event.target)
        ) {
            this.setOpen(false)
        }
    }

    setOpen(open) {
        this.sidebarTarget.classList.toggle('-translate-x-full', !open)
        this.buttonTarget.setAttribute('aria-expanded', open)

        if (this.hasBackdropTarget) {
            this.backdropTarget.classList.toggle('hidden', !open)
        }

        this.syncInert()
    }

    // The closed sidebar is only moved off screen, so inert keeps keyboard and
    // screen reader users out of it.
    syncInert() {
        this.sidebarTarget.inert = !this.wideScreen.matches && !this.isOpen
    }

    get isOpen() {
        return !this.sidebarTarget.classList.contains('-translate-x-full')
    }
}
