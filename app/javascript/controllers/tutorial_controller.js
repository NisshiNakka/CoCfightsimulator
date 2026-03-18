import { Controller } from "@hotwired/stimulus"
import Shepherd from "shepherd.js"

export default class extends Controller {
  static values = { i18n: Object }

  connect() {
    const meta = document.querySelector('meta[name="tutorial-step"]')
    if (!meta) return

    const step = parseInt(meta.content, 10)
    if (!this.shouldShowTour(step)) return

    this.startTour(step)
  }

  disconnect() {
    if (this.tour) {
      this.tour.hide()
    }
    if (this.diceResultObserver) {
      this.diceResultObserver.disconnect()
      this.diceResultObserver = null
    }
  }

  // ステップと現在のURLの組み合わせが一致するかチェック
  shouldShowTour(step) {
    const path = window.location.pathname
    const stepPageMap = {
      1: "/characters/new",
      2: "/characters",
      3: "/characters/new",
      4: "/characters",
      5: "/simulations/new",
      6: "/simulations/new"
    }

    // step 2, 4 は /characters 完全一致（/characters/new と区別）
    if (step === 2 || step === 4) {
      return path === "/characters"
    }

    const expectedPath = stepPageMap[step]
    if (!expectedPath) return false

    return path.startsWith(expectedPath)
  }

  startTour(step) {
    const steps = this.stepsForPage(step)
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

    // step 6: Turbo Stream で描画される #dice_result を MutationObserver で待機
    if (step === 6) {
      this.waitForDiceResultAndStart()
    } else {
      this.tour.start()
    }
  }

  // #dice_result の内容が描画されたらツアーを開始する
  waitForDiceResultAndStart() {
    const diceResult = document.getElementById("dice_result")
    if (!diceResult) return

    // Turboキャッシュ等で既にコンテンツがある場合はすぐに開始
    if (diceResult.children.length > 0) {
      this.tour.start()
      return
    }

    this.diceResultObserver = new MutationObserver(() => {
      const el = document.getElementById("dice_result")
      if (el && el.children.length > 0) {
        this.diceResultObserver.disconnect()
        this.diceResultObserver = null
        this.tour.start()
      }
    })

    this.diceResultObserver.observe(diceResult, { childList: true, subtree: true })
  }

  // ステップ5→6は同一ページ上の遷移のため、connect()を経由せず直接ステップ6をセットアップ
  setupStep6Tour() {
    this.tour = new Shepherd.Tour({
      useModalOverlay: true,
      defaultStepOptions: {
        scrollTo: { behavior: "smooth", block: "center" },
        cancelIcon: { enabled: true },
        classes: "tutorial-step"
      }
    })
    this.step6Steps().forEach(s => this.tour.addStep(s))
    this.tour.on("cancel", () => this.dismissTutorial())
    this.waitForDiceResultAndStart()
  }

  stepsForPage(step) {
    switch (step) {
      case 1: return this.step1Steps()
      case 2: return this.step2Steps()
      case 3: return this.step3Steps()
      case 4: return this.step4Steps()
      case 5: return this.step5Steps()
      case 6: return this.step6Steps()
      default: return []
    }
  }

  // ステップ1: 1体目のキャラクター作成（/characters/new）
  step1Steps() {
    const s = this.i18nValue
    return [
      {
        id: "step1-name",
        title: s.step1?.welcome_title,
        text: s.step1?.welcome_text,
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step1-characters",
        title: s.step1?.characters_title,
        text: s.step1?.characters_text,
        attachTo: { element: ".character-parameters", on: "top" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step1-attacks",
        title: s.step1?.attacks_title,
        text: s.step1?.attacks_text,
        attachTo: { element: ".attack-items", on: "top" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step1-submit",
        title: s.step1?.submit_title,
        text: s.step1?.submit_text,
        attachTo: { element: 'input[type="submit"].btn-primary', on: "top" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          {
            text: s.done,
            action: () => { this.advanceTutorial(); this.tour.complete() },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ステップ2: キャラクター一覧（1体目作成後）— 閲覧/編集ボタン紹介 → 対戦相手作成へ誘導
  step2Steps() {
    const s = this.i18nValue
    return [
      {
        id: "step2-list",
        title: s.step2?.list_title,
        text: s.step2?.list_text,
        attachTo: { element: ".border-start.border-end.border-bottom", on: "top" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step2-show",
        title: s.step2?.show_title,
        text: s.step2?.show_text,
        attachTo: { element: 'a.btn-outline-success[id^="button-show-"]', on: "right" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step2-edit",
        title: s.step2?.edit_title,
        text: s.step2?.edit_text,
        attachTo: { element: 'a.btn-outline-primary[id^="button-edit-"]', on: "right" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step2-create-opponent",
        title: s.step2?.create_opponent_title,
        text: s.step2?.create_opponent_text,
        attachTo: { element: "#index-buttons a.btn-primary", on: "bottom" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          {
            text: s.go_to_create,
            action: () => { this.advanceTutorial(); this.tour.complete() },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ステップ3: 2体目のキャラクター作成（/characters/new）— 簡略版
  step3Steps() {
    const s = this.i18nValue
    return [
      {
        id: "step3-form",
        title: s.step3?.form_title,
        text: s.step3?.form_text,
        attachTo: { element: "form.shadow-sm", on: "right" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step3-submit",
        title: s.step3?.submit_title,
        text: s.step3?.submit_text,
        attachTo: { element: 'input[type="submit"].btn-primary', on: "top" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          {
            text: s.done,
            action: () => { this.advanceTutorial(); this.tour.complete() },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ステップ4: キャラクター一覧（2体目作成後）— シミュレーションへ誘導
  step4Steps() {
    const s = this.i18nValue
    return [
      {
        id: "step4-list",
        title: s.step4?.list_title,
        text: s.step4?.list_text,
        attachTo: { element: ".border-start.border-end.border-bottom", on: "top" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step4-simulation",
        title: s.step4?.simulation_title,
        text: s.step4?.simulation_text,
        attachTo: { element: "#index-buttons a.btn-success", on: "bottom" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          {
            text: s.go_to_simulation,
            action: () => { this.advanceTutorial(); this.tour.complete() },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ステップ5: シミュレーションページ（/simulations/new）
  step5Steps() {
    const s = this.i18nValue
    return [
      {
        id: "step5-enemy",
        title: s.step5?.enemy_title,
        text: s.step5?.enemy_text,
        attachTo: { element: ".card.border-danger", on: "right" },
        buttons: [
          { text: s.skip, action: () => this.dismissTutorial(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step5-ally",
        title: s.step5?.ally_title,
        text: s.step5?.ally_text,
        attachTo: { element: ".card.border-primary", on: "left" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          { text: s.next, action: () => this.tour.next(), classes: "shepherd-button-primary" }
        ]
      },
      {
        id: "step5-start",
        title: s.step5?.start_title,
        text: s.step5?.start_text,
        attachTo: { element: "#dice_roll_area", on: "top" },
        buttons: [
          { text: s.back, action: () => this.tour.back(), classes: "shepherd-button-secondary" },
          {
            text: s.done,
            action: async () => {
              await this.advanceTutorial()
              this.tour.complete()
              // ステップ5→6は同一ページ上の遷移のため、connect()を経由せず直接セットアップ
              this.setupStep6Tour()
            },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  // ステップ6: 戦闘結果（combat_roll 後）
  step6Steps() {
    const s = this.i18nValue
    return [
      {
        id: "step6-result",
        title: s.step6?.result_title,
        text: s.step6?.result_text,
        attachTo: { element: "#dice_result", on: "top" },
        buttons: [
          {
            text: s.done,
            action: () => { this.dismissTutorial(); this.tour.complete() },
            classes: "shepherd-button-primary"
          }
        ]
      }
    ]
  }

  async advanceTutorial() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    await fetch("/tutorial", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ action_type: "advance" })
    })
  }

  async dismissTutorial() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    await fetch("/tutorial", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ action_type: "dismiss" })
    })
    if (this.tour) this.tour.complete()
  }
}
