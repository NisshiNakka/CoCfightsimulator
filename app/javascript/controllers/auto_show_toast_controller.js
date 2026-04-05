import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

// ページロード時に自動表示するトースト（flash 経由の通知に使用）
export default class extends Controller {
  connect() {
    const toast = new Toast(this.element)
    toast.show()
  }
}
