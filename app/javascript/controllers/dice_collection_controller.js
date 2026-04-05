import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "label"]

  select(event) {
    const key = event.params.key
    this.inputTarget.value = key
    this._updatePreview(event.currentTarget)
    this._updateSelectedStyle(event.currentTarget)
  }

  _updatePreview(clickedEl) {
    const key = clickedEl.dataset.diceCollectionKeyParam
    if (key === "none") {
      this.previewTarget.classList.add("d-none")
      this.labelTarget.classList.remove("d-none")
      this.labelTarget.textContent = this.previewTarget.alt
    } else {
      // data-image-url にサーバー側で生成したダイジェスト付きURLを保持
      const imageUrl = clickedEl.dataset.imageUrl
      if (imageUrl) this.previewTarget.src = imageUrl
      this.previewTarget.classList.remove("d-none")
      this.labelTarget.classList.add("d-none")
    }
  }

  _updateSelectedStyle(clickedEl) {
    this.element.querySelectorAll(".dice-item").forEach(el => {
      el.classList.remove("selected")
    })
    clickedEl.closest(".dice-item").classList.add("selected")
  }
}
