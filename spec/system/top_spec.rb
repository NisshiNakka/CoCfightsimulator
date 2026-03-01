require 'rails_helper'

RSpec.describe 'トップ画面', type: :system do
  let(:user) { create(:user) }
  before do
    visit root_path
  end

  describe '遷移確認' do
    context 'ログインしていない場合' do
      it '「初めての方はこちら」という案内テキストが表示されること' do
        expect(page).to have_content I18n.t('static_pages.top.first_time')
      end

      it '「新規登録」ボタンをクリックした場合ユーザー登録ページへ遷移すること' do
        within('#top_navigation_buttons') do
          click_on I18n.t('header.registration')
        end
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true),
        '[新規登録]ボタンからユーザー登録画面へ遷移できませんでした'
      end

      it '「ログイン」ボタンをクリックした場合ログインページへ遷移すること' do
        within('#top_navigation_buttons') do
          click_on I18n.t('header.login')
        end
        expect(page).to have_current_path(new_user_session_path, ignore_query: true),
        '[ログイン]ボタンからログイン画面へ遷移できませんでした'
      end

      it 'ヘッダーの「ログイン」ボタンをクリックした場合ログインページへ遷移すること' do
        within('#navbarSupportedContent') do
          click_on I18n.t('header.login')
        end
        expect(page).to have_current_path(new_user_session_path, ignore_query: true),
        '[ログイン]ボタンからログイン画面へ遷移できませんでした'
      end

      it 'タイトルロゴをクリックするとトップページへ遷移すること' do
        find('#logo-link').click
        expect(page).to have_current_path(root_path, ignore_query: true),
        'タイトルロゴからトップページへ遷移できませんでした'
      end

      it 'ヘッダーの新規登録ボタンをクリックした場合ユーザー登録ページへ遷移すること' do
        within('#navbarSupportedContent') do
          click_on(I18n.t('header.registration'))
        end
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true),
        '[新規登録]ボタンから新規登録画面へ遷移できませんでした'
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
        sign_in user
        visit root_path
      end

      it '「キャラクター登録」ボタンをクリックした場合キャラクター登録ページへ遷移すること' do
        within('#top_navigation_buttons') do
          click_on I18n.t('characters.new.title')
        end
        expect(page).to have_current_path(new_character_path, ignore_query: true),
        '[キャラクター登録]ボタンからキャラクター登録画面へ遷移できませんでした'
      end

      it '「シミュレーションする」ボタンをクリックした場合シミュレーションページへ遷移すること' do
        click_on I18n.t('defaults.go_simulation')
        expect(page).to have_current_path(new_simulations_path, ignore_query: true),
        '[シミュレーションする]ボタンからシミュレーションページへ遷移できませんでした'
      end

      it '[キャラクター一覧]ボタンをクリックした場合キャラクター一覧ページへ遷移すること' do
        find('#header-character-menu').click
        within('.dropdown-menu') do
          click_on('キャラクター一覧')
        end
        expect(page).to have_current_path(characters_path, ignore_query: true),
        '[キャラクター一覧]ボタンからキャラクター一覧ページへ遷移できませんでした'
      end

      it '[キャラクター登録]ボタンをクリックした場合キャラクター登録ページへ遷移すること' do
        find('#header-character-menu').click
        within('.dropdown-menu') do
          click_on('キャラクター登録')
        end
        expect(page).to have_current_path(new_character_path, ignore_query: true),
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
