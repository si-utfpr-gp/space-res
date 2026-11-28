import { Controller } from '@hotwired/stimulus'

// A GET filter form whose results live in a Turbo Frame. The results follow the fields as the
// person types or chooses, the focus stays in the field, and the new count is read out by a live
// region that stays on the page (one inserted with the new results is not always announced).
// Connects to data-controller="ui--filter-form"
export default class extends Controller {
    static targets = ['submit', 'status']
    static values = { frame: String, delay: { type: Number, default: 300 } }

    connect() {
        // Without JavaScript the button submits the form.
        this.submitTarget.classList.add('hidden')
    }

    disconnect() {
        clearTimeout(this.timeout)
    }

    submit() {
        clearTimeout(this.timeout)
        this.element.requestSubmit()
    }

    submitLater() {
        clearTimeout(this.timeout)
        this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
    }

    announce(event) {
        if (event.target.id !== this.frameValue) return

        const count = event.target.querySelector('[data-filter-count]')
        if (count) this.statusTarget.textContent = count.textContent.trim()
    }
}
