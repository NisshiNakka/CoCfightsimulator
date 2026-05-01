import { Controller } from "@hotwired/stimulus"
import Shepherd from "shepherd.js"

export default class extends Controller {
  static values = { i18n: Object }

  connect() {
    this.tryStart()
    this.boundForceStart = () => this.forceStart()
    document.addEventListener("collection-tutorial:start", this.boundForceStart)
  }

  disconnect() {
    document.removeEventListener("collection-tutorial:start", this.boundForceStart)
    this.cleanupListeners()
    if (this.tour) this.tour.hide()
  }

  // ===== 起動制御 =====

  async tryStart() {
    const meta = document.querySelector('meta[name="collection-tutorial-step"]')
    if (!meta) return
    const step = parseInt(meta.content, 10)

    // ヘッダーのプロフィールリンク経由で /profile に到達した場合、
    // フェーズ1完了として扱いフェーズ2を起動する
    if (step === 1 && window.location.pathname === "/profile") {
      await this.advanceCollectionTutorial()
      this.startTour(2)
      return
    }

    if (!this.shouldShowTour(step)) return
    this.startTour(step)
  }

  // 既存チュートリアル完了/スキップ直後にカスタムイベント経由で起動（同一ページ上）
  forceStart() {
    this.startTour(1)
  }

  shouldShowTour(step) {
    const path = window.location.pathname
    if (step === 1) return true // どのページでもOK（ヘッダー要素は全ページに存在する）
    if (step === 2) return path === "/profile"
    return false
  }

  startTour(step) {
    const steps = step === 1 ? this.phase1Steps() : this.phase2Steps()
    if (steps.length === 0) return

    this.tour = new Shepherd.Tour({
      useModalOverlay: true,
      defaultStepOptions: {
        scrollTo: { behavior: "smooth", block: "center" },
        cancelIcon: { enabled: true },
        classes: "tutorial-step"
      }
    })
    steps.forEach(s => this.tour.addStep(s))
    this.tour.on("cancel", () => this.dismissTutorial())
    this.tour.start()
  }

  // ===== フェーズ1: モーダル操作 + 情報説明（任意のページ） =====

  phase1Steps() {
    const s = this.i18nValue
    const hasTickets = !!document.querySelector('button[data-bs-target="#rewardTicketModal"] .badge')

    const modalSteps = hasTickets ? this.modalInteractionSteps(s) : []
    return [...modalSteps, ...this.infoSteps(s)]
  }

  // モーダル操作ステップ（特典券バッジ → 使用 → ダイス入手確認）
  modalInteractionSteps(s) {
    return [
      // ステップ1: 🎫バッジをクリックするよう誘導
      {
        id: "ticket-click",
        title: s.step1?.ticket_click_title,
        text: s.step1?.ticket_click_text,
        attachTo: { element: 'button[data-bs-target="#rewardTicketModal"]', on: "bottom" },
        buttons: [],
        when: {
          show: () => {
            this.modalShownHandler = (e) => {
              if (e.target.id === "rewardTicketModal") {
                this.tour.next()
              }
            }
            document.addEventListener("shown.bs.modal", this.modalShownHandler)
          },
          hide: () => {
            document.removeEventListener("shown.bs.modal", this.modalShownHandler)
          }
        }
      },
      // ステップ2: 「特典券を使用する」ボタンをクリックするよう誘導 (ダイス入手モーダルが閉じられるまで表示し続ける)
      {
        id: "ticket-use",
        title: s.step1?.ticket_use_title,
        text: s.step1?.ticket_use_text,
        attachTo: { element: "#rewardTicketModal .btn-warning", on: "bottom" },
        buttons: [],
        when: {
          show: () => {
            this.lowerOverlayZIndex()

            // 「特典券を使用する」押下 → rewardTicketModal が閉じ始めた瞬間にステップ2を非表示にする
            // (attachTo 対象消失によるポップオーバーの宙浮きを防ぐ)
            this.rewardModalHideHandler = (e) => {
              if (e.target.id === "rewardTicketModal") {
                const currentStep = this.tour.getCurrentStep()
                if (currentStep && currentStep.el) {
                  currentStep.el.style.setProperty("visibility", "hidden", "important")
                }
              }
            }
            document.addEventListener("hide.bs.modal", this.rewardModalHideHandler)

            // ダイス入手モーダルが閉じられたらステップ4へ遷移
            this.diceModalHiddenHandler = (e) => {
              if (e.target.id === "diceAcquiredModal") {
                this.restoreOverlayZIndex()
                this.tour.next()
              }
            }
            document.addEventListener("hidden.bs.modal", this.diceModalHiddenHandler)
          },
          hide: () => {
            document.removeEventListener("hide.bs.modal", this.rewardModalHideHandler)
            document.removeEventListener("hidden.bs.modal", this.diceModalHiddenHandler)
            this.restoreOverlayZIndex()
          }
        }
      }
    ]
  }

  // 情報説明ステップ（サイトロゴ → 入手方法 → プロフィールへ遷移）
  infoSteps(s) {
    return [
      // ステップ4: サイトロゴの説明
      {
        id: "info-site-logo",
        title: s.step1?.site_logo_title,
        text: s.step1?.site_logo_text,
        attachTo: { element: "#logo-link", on: "bottom" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ],
      },
      // ステップ5: 特典券入手方法の説明（中央表示）
      {
        id: "info-how-to-earn",
        title: s.step1?.how_to_earn_title,
        text: s.step1?.how_to_earn_text,
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      // ステップ6: プロフィールへ遷移
      {
        id: "navigate-profile",
        title: s.step1?.navigate_title,
        text: s.step1?.navigate_text,
        attachTo: { element: 'a[href="/profile"]', on: "bottom" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          {
            text: s.go_to_profile,
            action: async () => {
              await this.advanceCollectionTutorial()
              window.location.href = "/profile"
            },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ===== フェーズ2: プロフィール画面（/profile） =====

  phase2Steps() {
    const s = this.i18nValue
    return [
      // ステップ7: ダイスコレクショングリッドの説明
      {
        id: "collection-grid",
        title: s.step2?.grid_title,
        text: s.step2?.grid_text,
        attachTo: { element: ".row.row-cols-4", on: "top" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      // ステップ8: アイコン変更方法の説明
      {
        id: "icon-change",
        title: s.step2?.icon_change_title,
        text: s.step2?.icon_change_text,
        attachTo: { element: 'input[type="submit"].btn-primary', on: "top" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      // ステップ9: 完了メッセージ
      {
        id: "complete",
        title: s.step2?.complete_title,
        text: s.step2?.complete_text,
        buttons: [
          {
            text: s.done,
            action: () => this.dismissTutorial(),
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ===== サーバー通信 =====

  async advanceCollectionTutorial() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    await fetch("/tutorial", {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
      body: JSON.stringify({ action_type: "advance_collection" })
    })
  }

  async dismissTutorial() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    await fetch("/tutorial", {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
      body: JSON.stringify({ action_type: "dismiss_collection" })
    })
    if (this.tour) this.tour.complete()
  }

  // ===== z-index 管理 =====

  lowerOverlayZIndex() {
    const overlay = document.querySelector(".shepherd-modal-overlay-container")
    if (overlay) overlay.style.setProperty("z-index", "1040", "important")
  }

  restoreOverlayZIndex() {
    const overlay = document.querySelector(".shepherd-modal-overlay-container")
    if (overlay) overlay.style.removeProperty("z-index")
  }

  // ===== イベントリスナークリーンアップ =====

  cleanupListeners() {
    if (this.modalShownHandler) {
      document.removeEventListener("shown.bs.modal", this.modalShownHandler)
    }
    if (this.rewardModalHideHandler) {
      document.removeEventListener("hide.bs.modal", this.rewardModalHideHandler)
    }
    if (this.diceModalHiddenHandler) {
      document.removeEventListener("hidden.bs.modal", this.diceModalHiddenHandler)
    }
    this.restoreOverlayZIndex()
  }
}
