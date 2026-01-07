require 'rails_helper'

RSpec.describe "Characters", type: :system do
  let(:user) { create(:user) }
  let!(:character_by_me) { create(:character, user: user, name: "自分のキャラ") }
  let!(:character_by_others) { create(:character, name: "他人のキャラ") }

  before do
    sign_in user
  end

  describe "一覧表示機能" do
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
  end

  describe "ページネーション機能" do
    before do
      create_list(:character, 19, user: user)
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
