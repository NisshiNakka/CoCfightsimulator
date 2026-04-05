import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static values = { show: Boolean }

  connect() {
    if (this.showValue) {
      const modalEl = this.element.querySelector(".modal")
      if (modalEl) {
        // モーダルが閉じられたら showValue を false にし、
        // Turbo Drive のキャッシュ復元時に再表示されないようにする
        modalEl.addEventListener("hidden.bs.modal", () => {
          this.showValue = false
        }, { once: true })

        const modal = new Modal(modalEl)
        modal.show()
      }
    }
  }
}
