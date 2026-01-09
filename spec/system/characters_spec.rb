require 'rails_helper'

RSpec.describe "Characters", type: :system do
  let(:user) { create(:user) }
  let!(:character_by_me) { create(:character, user: user, name: "自分のキャラ") }
  let!(:character_by_others) { create(:character, name: "他人のキャラ") }

  before do
    sign_in user
  end

  describe "一覧表示機能" do
    let(:path) { characters_path }
    it_behaves_like 'require login'

    it '正しいタイトルが表示されていること' do
      visit characters_path
      expect(page).to have_content("キャラクター一覧"), 'キャラクター一覧ページのタイトルが表示されていません。'
    end

    it "ログインユーザーが作成したキャラクターのみが表示されること" do
      visit characters_path
      expect(page).to have_content "自分のキャラ"
      expect(page).to have_content character_by_me.hitpoint
      expect(page).to have_content character_by_me.dexterity
      expect(page).to_not have_content "他人のキャラ"
    end

    it "キャラクターが1つも存在しない場合、専用のメッセージが表示されること" do
      user.characters.destroy_all
      visit characters_path
      expect(page).to have_content I18n.t('characters.index.no_record')
    end

    it "作成日時の降順（新しい順）でキャラクターが表示されていること" do
      user.characters.destroy_all
      older_character = create(:character, user: user, name: "古いキャラ", created_at: 1.day.ago)
      newer_character = create(:character, user: user, name: "新しいキャラ", created_at: Time.current)
      visit characters_path
      expect(page.text).to match(/#{newer_character.name}.*#{older_character.name}/m)
    end

    describe "ページネーション機能" do
      context "21件以上だった場合" do
        before do
          user.characters.destroy_all
          create_list(:character, 20, user: user)
        end
        let!(:last_character) { create(:character, user: user, name: "21番目のキャラ", created_at: 1.month.ago) }

        it "1ページ目に20件表示されること" do
          visit characters_path
          expect(page).to have_selector('.card', count: 20)
        end

        it "21体目以降は2ページ目に表示されること" do
          visit characters_path
          expect(page).to_not have_content "21番目のキャラ"
          expect(page).to have_selector('.pagination')
          within '.pagination' do
            click_link '2'
          end
          expect(page).to have_content "21番目のキャラ"
          expect(page).to have_current_path(characters_path(page: 2))
        end
      end

      context "20件以下だった場合" do
        it "ページングが表示されないこと" do
          user.characters.destroy_all
          create_list(:character, 20, user: user)
          visit characters_path
          expect(page).not_to have_selector('.pagination')
        end
      end
    end

    describe "表示要素の確認" do
      it "各キャラクターに操作ボタン（詳細・編集・削除）が表示されていること" do
        visit characters_path
        within ".card" do
          expect(page).to have_link I18n.t('defaults.show')
          expect(page).to have_link I18n.t('defaults.edit')
          expect(page).to have_link I18n.t('defaults.delete')
         expect(page).to have_selector "img[alt='アイコン']"
        end
      end
    end
  end

  describe "キャラクター登録機能" do
    before do
      visit characters_path
      within ".gap-2" do
        click_on 'キャラクター登録'
      end
    end

    let(:path) { new_character_path }
    it_behaves_like 'require login'

    it '正しいタイトルが表示されていること' do
      expect(page).to have_content("キャラクター登録"), 'キャラクター登録ページのタイトルが表示されていません。'
    end

    context "入力値が正常な場合" do
      it "キャラクターの新規作成が成功し、一覧画面にリダイレクトされること" do
        fill_in "character_name", with: "新規キャラクター"
        fill_in "character_hitpoint", with: 10
        fill_in "character_dexterity", with: 50
        fill_in "character_evasion_rate", with: 20
        fill_in "character_evasion_correction", with: 1
        fill_in "character_armor", with: 1
        fill_in "character_damage_bonus", with: "1d6+1"
        fill_in "character_attacks_attributes_0_name", with: "新規技能"
        fill_in "character_attacks_attributes_0_success_probability", with: 50
        fill_in "character_attacks_attributes_0_dice_correction", with: 0
        fill_in "character_attacks_attributes_0_damage", with: "1d6"
        click_button I18n.t('characters.new.character_create')
        expect(page).to have_content I18n.t("defaults.flash_message.created", item: Character.model_name.human)
        expect(page).to have_content "新規キャラクター"
        expect(current_path).to eq characters_path
      end
    end

    context "入力値が不正な場合" do
      it "新規作成が失敗しフラッシュメッセージが表示されること" do
        fill_in "character_name", with: ""
        click_button I18n.t('characters.new.character_create')
        expect(current_path).to eq new_character_path
        expect(page).to have_content I18n.t("defaults.flash_message.not_created", item: Character.model_name.human)
        expect(page).to have_content "キャラクター名 を入力してください"
      end

      it "damage_bonusの形式が不正な場合、登録に失敗すること" do
        fill_in "character_damage_bonus", with: "不正なダイス"
        click_button I18n.t('characters.new.character_create')
        expect(page).to have_content I18n.t("defaults.flash_message.not_created", item: Character.model_name.human)
        expect(page).to have_content "ダメージボーナス は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）"
      end
    end
  end
end
