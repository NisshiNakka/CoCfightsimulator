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
  // 全セクションのアニメーション完了後に "simulation-result:ready" イベントをディスパッチし、
  // tutorial_controller と競合しないよう連携する
  //
  // transitionend は prefers-reduced-motion 等の環境で発火しない場合があるため、
  // 固定タイムアウト（最終遅延 + CSSトランジション時間 + バッファ）でイベントを発火する
  animateSections() {
    const sections = this.sectionTargets
    const STAGGER_MS = 150     // セクション間の遅延（CSS の 150ms と一致）
    const TRANSITION_MS = 500  // CSSトランジション時間（_simulation.scss の 0.5s と一致）

    sections.forEach((el, index) => {
      requestAnimationFrame(() => {
        setTimeout(() => {
          el.classList.add("fade-in-active")
        }, index * STAGGER_MS)
      })
    })

    // 全セクションのアニメーション完了後にイベントを発火
    // 計算式: (最後のセクションの遅延) + (トランジション時間) + (バッファ 50ms)
    const totalMs = (sections.length - 1) * STAGGER_MS + TRANSITION_MS + 50
    setTimeout(() => {
      document.dispatchEvent(new CustomEvent("simulation-result:ready"))
    }, totalMs)
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
