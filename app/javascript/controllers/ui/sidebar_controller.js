import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="sidebar"
export default class extends Controller {
    static targets = ['sidebar', 'backdrop', 'button']

    toggle() {
        this.setOpen(this.sidebarTarget.classList.contains('-translate-x-full'))
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
    }
}
