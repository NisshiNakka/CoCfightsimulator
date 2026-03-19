import { Controller } from "@hotwired/stimulus"

// シミュレーション結果の表示制御
// - フェードインアニメーション（段階的表示）
// - シミュレーションボタンのテキスト切り替え（初回/2回目以降）
export default class extends Controller {
  static targets = ["section", "button"]

  connect() {
    this.animateSections()
    this.markAsSimulated()
  }

  // 結果セクションを段階的にフェードイン表示する
  animateSections() {
    this.sectionTargets.forEach((el, index) => {
      el.classList.add("fade-in-ready")
      requestAnimationFrame(() => {
        setTimeout(() => {
          el.classList.add("fade-in-active")
        }, index * 150) // 150ms ずつ遅延して段階的に表示
      })
    })
  }

  // シミュレーション実行済みフラグをボタンに伝える
  // ボタンテキストはサーバー側（Turbo Stream）で変更するため、
  // このメソッドはフラグのマークのみ行う
  markAsSimulated() {
    if (this.hasButtonTarget) {
      this.buttonTarget.dataset.simulated = "true"
    }
  }
}
