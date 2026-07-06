import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="dropdown"
export default class extends Controller {
    static targets = ['menu']

    connect() {
        this.menuTarget.addEventListener("click",    this.handleMenuClick.bind(this));
    }

    disconnect() {
        this.menuTarget.removeEventListener("click", this.handleMenuClick.bind(this));
    }

    handleMenuClick(event) {
        this.menuTarget.classList.toggle("hidden");
    }

    toggle() {
        this.menuTarget.classList.toggle('hidden')
    }

    close(event) {
        if (!this.element.contains(event.target)) {
            this.menuTarget.classList.add('hidden')
        }
    }
}