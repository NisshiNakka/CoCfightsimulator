require 'rails_helper'

RSpec.describe 'トップ画面', type: :system do
  let(:user) { create(:user) }
  before do
    visit root_path
  end

  it '正しい画面が表示されていること' do
    expect(page).to have_content("CoC fight simulator"), 'タイトル[CoC fight simulator]が表示されていません。'
  end

  describe '遷移確認' do
    context 'ログインしていない場合' do
      it '[さっそく始める]ボタンをクリックした場合ログインページへ遷移すること' do
        click_on('さっそく始める')
        expect(page).to have_current_path(new_user_session_path, ignore_query: true),
        '[さっそく始める]ボタンからログイン画面へ遷移できませんでした'
      end

      it 'タイトルロゴをクリックするとトップページへ遷移すること' do
        find('#logo-link').click
        expect(page).to have_current_path(root_path, ignore_query: true),
        'タイトルロゴからトップページへ遷移できませんでした'
      end

      it 'ユーザー登録ボタンをクリックした場合ユーザー登録ページへ遷移すること' do
        click_on('ユーザー登録')
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true),
        '[ユーザー登録]ボタンからユーザー登録画面へ遷移できませんでした'
      end

      xit '利用規約をクリックした場合利用規約ページへ遷移すること' do
        click_on('利用規約')
        expect(page).to have_current_path(xxx_path, ignore_query: true),
        '利用規約をクリックして利用規約ページへ遷移できませんでした'
      end

      xit 'プライバシーポリシーをクリックした場合プライバシーポリシーページへ遷移すること' do
        click_on('利用規約')
        expect(page).to have_current_path(xxx_path, ignore_query: true),
        'プライバシーポリシーをクリックしてプライバシーポリシーページへ遷移できませんでした'
      end
    end

    context 'ログインしている場合' do
      before do
        login_as(user)
      end
      it '[さっそく始める]ボタンをクリックした場合シミュレーションページへ遷移すること' do
        click_on('さっそく始める')
        expect(page).to have_current_path(new_simulations_path, ignore_query: true),
        '[さっそく始める]ボタンからシミュレーションページへ遷移できませんでした'
      end

      it '[キャラクター一覧]ボタンをクリックした場合キャラクター一覧ページへ遷移すること' do
        find('#header-character-menu').click
        within('.dropdown-menu') do
          click_on('キャラクター一覧')
        end
        expect(page).to have_current_path(characters_path, ignore_query: true),
        '[キャラクター一覧]ボタンからキャラクター一覧ページへ遷移できませんでした'
      end

      xit '[キャラクター詳細]ボタンをクリックした場合キャラクター詳細ページへ遷移すること' do
        find('#header-character-menu').click
        within('.dropdown-menu') do
          click_on('キャラクター詳細')
        end
        expect(page).to have_current_path(xxx_path, ignore_query: true),
        '[キャラクター詳細]ボタンからキャラクター詳細画面へ遷移できませんでした'
      end

      xit '[キャラクター登録]ボタンをクリックした場合キャラクター登録ページへ遷移すること' do
        find('#header-character-menu').click
        within('.dropdown-menu') do
          click_on('キャラクター登録')
        end
        expect(page).to have_current_path(xxx_path, ignore_query: true),
        '[キャラクター登録]ボタンからキャラクター登録画面へ遷移できませんでした'
      end

      it '[ユーザーページ]ボタンをクリックした場合ユーザーページへ遷移すること' do
        click_on("#{user.name}")
        expect(page).to have_current_path(edit_user_registration_path, ignore_query: true),
        '[ユーザーページ]ボタンからユーザーページへ遷移できませんでした'
      end
    end
  end
end
