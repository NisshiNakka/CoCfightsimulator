require 'rails_helper'

RSpec.describe "Simulations", type: :system do
  let(:user) { create(:user) }
  let!(:character) { create(:character, user: user, name: "シミュレーション用キャラ") }
  let!(:attack) { create(:attack, character: character, name: "パンチ", success_probability: 70) }

  before do
    sign_in user
  end

  describe "キャラクター読み込み機能" do
    before do
      visit new_simulations_path
    end

    it "初期表示ではキャラクター選択を促すメッセージが表示されていること" do
      within "turbo-frame#character_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content character.name
      end
    end

    it "プルダウンからキャラクターを選択すると、そのキャラクターの情報が非同期で表示されること", js: true do
      select "シミュレーション用キャラ", from: "character_id"

      within "turbo-frame#character_display" do
        expect(page).not_to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).to have_content "シミュレーション用キャラ"
        expect(page).to have_content character.hitpoint
        expect(page).to have_content "パンチ"
        expect(page).to have_content "70%"
      end
    end

    it "他人のキャラクターはプルダウンの選択肢に表示されないこと" do
      other_user = create(:user)
      create(:character, user: other_user, name: "他人のキャラ")
      visit new_simulations_path
      expect(page).to have_content "シミュレーション用キャラ"
      expect(page).not_to have_content "他人のキャラ"
    end

    it "選択を解除（空を選択）すると、指示メッセージに戻ること", js: true do
      select "シミュレーション用キャラ", from: "character_id"
      within "turbo-frame#character_display" do
        expect(page).to have_content "シミュレーション用キャラ"
      end
      select I18n.t('simulations.new.not_select'), from: "character_id"
      within "turbo-frame#character_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "シミュレーション用キャラ"
      end
    end
  end
end
