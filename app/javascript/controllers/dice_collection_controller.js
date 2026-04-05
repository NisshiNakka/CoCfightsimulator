import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "label"]

  select(event) {
    const key = event.params.key
    this.inputTarget.value = key
    this._updatePreview(key)
    this._updateSelectedStyle(event.currentTarget)
  }

  _updatePreview(key) {
    if (key === "none") {
      this.previewTarget.classList.add("d-none")
      this.labelTarget.classList.remove("d-none")
      this.labelTarget.textContent = this.previewTarget.alt
    } else if (key === "defaults") {
      this.previewTarget.src = this._assetPath("all_dice/logo_defaults.webp")
      this.previewTarget.classList.remove("d-none")
      this.labelTarget.classList.add("d-none")
    } else {
      this.previewTarget.src = this._assetPath(`all_dice/${key}.webp`)
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

  _assetPath(path) {
    const meta = document.querySelector('meta[name="asset-path"]')
    const base = meta ? meta.content : "/assets"
    return `${base}/${path}`
  }
}
