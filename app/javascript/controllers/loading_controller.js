import { Controller } from "@hotwired/stimulus"

// グローバルローディングオーバーレイの表示制御
// - Turbo のライフサイクルイベントを監視し、リクエスト中にオーバーレイを表示する
// - 高速レスポンス時のちらつき防止:
//   SHOW_DELAY_MS 以内に完了した場合は表示しない
//   一度表示した場合は MIN_DISPLAY_MS の最小表示時間を保証する
export default class extends Controller {
  static targets = ["overlay"]

  static SHOW_DELAY_MS = 200  // 表示までの遅延（高速レスポンスならスキップ）
  static MIN_DISPLAY_MS = 400 // 最小表示時間（ちらつき防止）

  connect() {
    this.showDelayTimer = null
    this.hideDelayTimer = null
    this.showRequestedAt = null

    this.boundShow = this.show.bind(this)
    this.boundHide = this.hide.bind(this)

    // フォーム送信（Turbo Stream 含む）
    document.addEventListener("turbo:submit-start", this.boundShow)
    document.addEventListener("turbo:submit-end", this.boundHide)

    // ページ遷移（Turbo Drive）
    document.addEventListener("turbo:before-fetch-request", this.boundShow)
    document.addEventListener("turbo:before-fetch-response", this.boundHide)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.boundShow)
    document.removeEventListener("turbo:submit-end", this.boundHide)
    document.removeEventListener("turbo:before-fetch-request", this.boundShow)
    document.removeEventListener("turbo:before-fetch-response", this.boundHide)
    clearTimeout(this.showDelayTimer)
    clearTimeout(this.hideDelayTimer)
  }

  show() {
    clearTimeout(this.showDelayTimer)
    clearTimeout(this.hideDelayTimer)
    this.showRequestedAt = Date.now()

    // SHOW_DELAY_MS 後に表示（高速レスポンス時はキャンセルされる）
    this.showDelayTimer = setTimeout(() => {
      this.overlayTarget.classList.add("loading-overlay--visible")
    }, this.constructor.SHOW_DELAY_MS)
  }

  hide() {
    clearTimeout(this.showDelayTimer)
    clearTimeout(this.hideDelayTimer)

    // まだ表示されていない場合（SHOW_DELAY_MS 以内）はタイマーキャンセルのみ
    if (!this.overlayTarget.classList.contains("loading-overlay--visible")) {
      this.showRequestedAt = null
      return
    }

    // 最小表示時間に満たない場合は残り時間だけ待ってから非表示にする
    const elapsed = Date.now() - this.showRequestedAt
    const remaining = Math.max(0, this.constructor.MIN_DISPLAY_MS - elapsed)

    this.hideDelayTimer = setTimeout(() => {
      this.overlayTarget.classList.remove("loading-overlay--visible")
      this.showRequestedAt = null
    }, remaining)
  }
}
