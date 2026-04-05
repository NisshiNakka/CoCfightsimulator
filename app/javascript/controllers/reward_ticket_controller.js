import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  connect() {
    // モーダル非表示時にフォーカスを解除し aria-hidden 競合を防ぐ
    this.element.addEventListener("hide.bs.modal", () => {
      document.activeElement?.blur()
    })
  }

  // 「特典券を使用する」クリック時: モーダルを閉じてから Turbo にリクエストを委譲
  useTicket() {
    const modal = Modal.getInstance(this.element)
    if (modal) modal.hide()
    // event.preventDefault() を呼ばないので Turbo の POST リクエストはそのまま送信される
  }
}
