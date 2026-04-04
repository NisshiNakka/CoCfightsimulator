import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "image", "label"]

  updatePreview() {
    const value = this.selectTarget.value

    if (value === "none") {
      this.imageTarget.classList.add("d-none")
      if (this.hasLabelTarget) {
        this.labelTarget.textContent = this.selectTarget.options[this.selectTarget.selectedIndex].text
        this.labelTarget.classList.remove("d-none")
      }
    } else if (value === "defaults") {
      this.imageTarget.src = this._assetPath("all_dice/logo_defaults.webp")
      this.imageTarget.classList.remove("d-none")
      if (this.hasLabelTarget) this.labelTarget.classList.add("d-none")
    } else {
      this.imageTarget.src = this._assetPath(`all_dice/${value}.webp`)
      this.imageTarget.classList.remove("d-none")
      if (this.hasLabelTarget) this.labelTarget.classList.add("d-none")
    }
  }

  _assetPath(path) {
    const meta = document.querySelector("meta[name='asset-path']")
    const base = meta ? meta.content : "/assets"
    return `${base}/${path}`
  }
}
