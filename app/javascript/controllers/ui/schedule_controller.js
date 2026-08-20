import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["unica", "recorrente"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const tipo = this.element.querySelector("select[name='schedule[tipo_reserva]']").value

    this.unicaTarget.classList.toggle("hidden", tipo !== "unica")
    this.recorrenteTarget.classList.toggle("hidden", tipo !== "recorrente")
  }
}