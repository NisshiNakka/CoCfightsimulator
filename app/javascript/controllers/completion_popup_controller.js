import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static values = { show: Boolean }

  connect() {
    if (this.showValue) {
      const modalEl = this.element.querySelector(".modal")
      if (modalEl) {
        const modal = new Modal(modalEl)
        modal.show()
      }
    }
  }
}
