import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui--filtered-select"
//
// Narrows the options of a select (the "select" target) to the ones whose data-filter-key matches the
// value chosen in another field (the "source" target). Options without data-filter-key, such as the
// blank one, always stay. With no value chosen in the source, every option is offered.
export default class extends Controller {
    static targets = ["source", "select"]

    connect() {
        // Options are removed and put back, not hidden: iOS Safari does not hide <option>.
        this.original = Array.from(this.selectTarget.children, (node) => node.cloneNode(true))
        // Turbo caches the page as it is; the cached copy must hold every option to be filtered again.
        this.restoreBeforeCache = () => this.show(this.original)
        document.addEventListener("turbo:before-cache", this.restoreBeforeCache)
        this.filter()
    }

    disconnect() {
        document.removeEventListener("turbo:before-cache", this.restoreBeforeCache)
    }

    filter() {
        const key = this.sourceTarget.value

        this.show(key ? this.original.flatMap((node) => this.matching(node, key)) : this.original)
    }

    // Keeps the chosen option when it is still offered; otherwise falls back to the blank one.
    show(nodes) {
        const chosen = this.selectTarget.value

        this.selectTarget.replaceChildren(...nodes.map((node) => node.cloneNode(true)))
        const offered = Array.from(this.selectTarget.options).some((option) => option.value === chosen)
        this.selectTarget.value = offered ? chosen : ""
    }

    matching(node, key) {
        const options = node.tagName === "OPTGROUP" ? Array.from(node.children) : [node]

        return options.filter((option) => !option.dataset.filterKey || option.dataset.filterKey === key)
    }
}
