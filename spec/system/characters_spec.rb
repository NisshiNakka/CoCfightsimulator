require 'rails_helper'

RSpec.describe "Characters", type: :system do
  let(:user) { create(:user) }
  let!(:character_by_me) { create(:character, user: user, name: "自分のキャラ") }
  let!(:character_by_others) { create(:character, name: "他人のキャラ") }

  before do
    sign_in user
  end

  describe "一覧表示画面" do
    let(:path) { characters_path }
    it_behaves_like 'require login'

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

    describe "キャラクター削除機能" do
    let!(:character_by_me) { create(:character, user: user, name: "削除テストのキャラ") }

      it "キャラクターを削除できること" do
        visit characters_path
        accept_confirm do
          click_link "button-delete-#{character_by_me.id}"
        end
        expect(page).to have_content I18n.t("defaults.flash_message.deleted", item: Character.model_name.human)
        expect(page).not_to have_content "削除テストのキャラ"
        expect(Character.where(id: character_by_me.id)).not_to exist
      end
    end

    describe "画面遷移" do
      it 'キャラクター登録ボタンからキャラクター登録画面へ遷移できること' do
        visit characters_path
        within ".gap-2" do
          click_on I18n.t('characters.new.title')
        end
        expect(page).to have_current_path(new_character_path, ignore_query: true),
        '[キャラクター登録]ボタンからキャラクター登録画面へ遷移できませんでした'
      end

      it '「シミュレーションする」ボタンからシミュレーション画面へ遷移できること' do
        visit characters_path
        within ".gap-2" do
          click_on I18n.t('defaults.go_simulation')
        end
        expect(page).to have_current_path(new_simulations_path, ignore_query: true),
        '[シミュレーションする]ボタンからシミュレーション画面へ遷移できませんでした'
      end
    end
  end

  describe "登録機能" do
    before do
      visit new_character_path
    end

    let(:path) { new_character_path }
    it_behaves_like 'require login'

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
        click_button I18n.t('characters.form.character_create')
        expect(page).to have_content I18n.t("defaults.flash_message.created", item: Character.model_name.human)
        expect(page).to have_content "新規キャラクター"
        expect(current_path).to eq characters_path
        new_character = Character.last
        expect(new_character.attacks.count).to eq 1
        expect(new_character.attacks.first.name).to eq "新規技能"
      end
    end

    context "入力値が不正な場合" do
      it "新規作成が失敗しフラッシュメッセージが表示されること" do
        fill_in "character_name", with: ""
        click_button I18n.t('characters.form.character_create')
        expect(current_path).to eq new_character_path
        expect(page).to have_content I18n.t("defaults.flash_message.not_created", item: Character.model_name.human)
        expect(page).to have_selector '#error_explanation'
      end

      it "攻撃技能の名前が空の場合、登録に失敗しエラーメッセージが表示されること" do
        fill_in "character_attacks_attributes_0_name", with: ""
        click_button I18n.t('characters.form.character_create')
        expect(page).to have_content I18n.t("defaults.flash_message.not_created", item: Character.model_name.human)
        expect(page).to have_selector '#error_explanation'
      end

      it "damage_bonusの形式が不正な場合、登録に失敗すること" do
        fill_in "character_damage_bonus", with: "不正なダイス"
        click_button I18n.t('characters.form.character_create')
        expect(page).to have_content I18n.t("defaults.flash_message.not_created", item: Character.model_name.human)
        expect(page).to have_selector '#error_explanation'
      end

      it "攻撃技能のダメージ形式が不正な場合、登録に失敗すること" do
        fill_in "character_attacks_attributes_0_damage", with: "不適切な形式"
        click_button I18n.t('characters.form.character_create')
        expect(page).to have_content I18n.t("defaults.flash_message.not_created", item: Character.model_name.human)
        expect(page).to have_selector '#error_explanation'
      end
    end
  end

  describe "詳細表示機能" do
    let!(:attack) { create(:attack, character: character_by_me, name: "パンチ", success_probability: 50, damage: "1d3") }

    let(:path) { character_path(character_by_me) }
    it_behaves_like 'require login'

    it "キャラクターの詳細情報と攻撃技能が表示されること" do
      visit characters_path
      click_link character_by_me.name
      expect(page).to have_content I18n.t('characters.show.title')
      expect(page).to have_content character_by_me.name
      expect(page).to have_content "#{character_by_me.evasion_rate}%"
      expect(page).to have_content I18n.t('activerecord.models.attack')
      expect(page).to have_content "パンチ"
      expect(page).to have_content "50%"
      expect(page).to have_link I18n.t('defaults.back_index'), href: characters_path
    end

    it "詳細画面からキャラクターを削除できること", js: true do
      visit character_path(character_by_me)

      accept_confirm do
        click_link I18n.t('defaults.delete')
      end

      expect(page).to have_content I18n.t("defaults.flash_message.deleted", item: Character.model_name.human)
      expect(current_path).to eq characters_path
    end

    it "詳細画面からシミュレーションページへ遷移できること" do
      visit character_path(character_by_me)
      click_on I18n.t('defaults.go_simulation')
      expect(page).to have_current_path(new_simulations_path, ignore_query: true),
      "[シミュレーションする]ボタンからキャラクター登録画面へ遷移できませんでした"
    end
  end

  describe "編集機能" do
    let!(:attack) { create(:attack, character: character_by_me, name: "パンチ", success_probability: 50) }

    let(:path) { edit_character_path(character_by_me) }
    it_behaves_like 'require login'

    context "入力値が正常な場合" do
      it "キャラクター情報を更新でき、詳細画面にリダイレクトされること" do
        visit character_path(character_by_me)
        click_link I18n.t('defaults.edit')
        fill_in "character_name", with: "更新後のキャラ名"
        fill_in "character_hitpoint", with: 15
        fill_in "character_attacks_attributes_0_name", with: "強烈なパンチ"
        fill_in "character_attacks_attributes_0_success_probability", with: 60
        click_button I18n.t('characters.form.character_update')
        expect(page).to have_content I18n.t("defaults.flash_message.updated", item: Character.model_name.human)
        expect(page).to have_content "更新後のキャラ名"
        expect(page).to have_content "15"
        expect(page).to have_content "強烈なパンチ"
        expect(page).to have_content "60%"
        expect(current_path).to eq character_path(character_by_me)
      end
    end

    context "入力値が不正な場合" do
      it "名前を空にすると更新に失敗し、エラーメッセージが表示されること" do
        visit edit_character_path(character_by_me)
        fill_in "character_name", with: ""
        click_button I18n.t('characters.form.character_update')
        expect(page).to have_content I18n.t("defaults.flash_message.not_updated", item: Character.model_name.human)
        expect(page).to have_selector '#error_explanation'
        expect(current_path).to eq edit_character_path(character_by_me)
      end

      it "技能名を空にすると更新に失敗し、エラーメッセージが表示されること" do
        visit edit_character_path(character_by_me)
        fill_in "character_attacks_attributes_0_name", with: ""
        click_button I18n.t('characters.form.character_update')
        expect(page).to have_content I18n.t("defaults.flash_message.not_updated", item: Character.model_name.human)
        expect(page).to have_selector '#error_explanation'
        expect(current_path).to eq edit_character_path(character_by_me)
      end
    end

    it "詳細画面からキャラクターを削除できること", js: true do
      visit edit_character_path(character_by_me)

      accept_confirm do
        click_link I18n.t('defaults.delete')
      end

      expect(page).to have_content I18n.t("defaults.flash_message.deleted", item: Character.model_name.human)
      expect(current_path).to eq characters_path
    end
  end
end
