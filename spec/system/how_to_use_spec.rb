require 'rails_helper'

RSpec.describe '使い方ページ', type: :system do
  let(:user) { create(:user) }

  describe 'アクセス確認' do
    context 'ログインしていない場合' do
      before { visit how_to_use_path }

      it '正しいタイトルが表示されていること' do
        expect(page).to have_title('使い方 | CoC Fight Simulator'), '使い方ページのタイトルが正しくありません。'
      end

      it '使い方ページへアクセスできること' do
        expect(page).to have_current_path(how_to_use_path, ignore_query: true),
        'ログインなしで使い方ページへアクセスできませんでした'
      end

      it 'ページタイトルが表示されること' do
        expect(page).to have_content I18n.t('static_pages.how_to_use.title')
      end

      it '各ステップのタイトルが表示されること' do
        expect(page).to have_content I18n.t('static_pages.how_to_use.step_1_title')
        expect(page).to have_content I18n.t('static_pages.how_to_use.step_2_title')
        expect(page).to have_content I18n.t('static_pages.how_to_use.step_3_title')
        expect(page).to have_content I18n.t('static_pages.how_to_use.step_4_title')
      end

      it '「新規登録」ボタンをクリックした場合ユーザー登録ページへ遷移すること' do
        within('#how-to-use-next-step') do
          click_on I18n.t('header.registration')
        end
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true),
        '[新規登録]ボタンからユーザー登録画面へ遷移できませんでした'
      end

      it '「ログイン」ボタンをクリックした場合ログインページへ遷移すること' do
        within('#how-to-use-next-step') do
          click_on I18n.t('header.login')
        end
        expect(page).to have_current_path(new_user_session_path, ignore_query: true),
        '[ログイン]ボタンからログイン画面へ遷移できませんでした'
      end
    end

    context 'ログインしている場合' do
      before do
        sign_in user
        visit how_to_use_path
      end

      it '使い方ページへアクセスできること' do
        expect(page).to have_current_path(how_to_use_path, ignore_query: true),
        'ログイン済みで使い方ページへアクセスできませんでした'
      end

      it '「シミュレーションする」ボタンをクリックした場合シミュレーションページへ遷移すること' do
        within('#how-to-use-next-step') do
          click_on I18n.t('defaults.go_simulation')
        end
        expect(page).to have_current_path(new_simulations_path, ignore_query: true),
        '[シミュレーションする]ボタンからシミュレーションページへ遷移できませんでした'
      end

      it '「キャラクター登録」ボタンをクリックした場合キャラクター登録ページへ遷移すること' do
        within('#how-to-use-next-step') do
          click_on I18n.t('characters.new.title')
        end
        expect(page).to have_current_path(new_character_path, ignore_query: true),
        '[キャラクター登録]ボタンからキャラクター登録画面へ遷移できませんでした'
      end
    end
  end

  describe 'ヘッダーからのナビゲーション確認' do
    context 'ログインしていない場合' do
      before { visit root_path }

      it 'ヘッダーの「使い方」リンクをクリックした場合使い方ページへ遷移すること' do
        within('#navbarSupportedContent') do
          click_on I18n.t('header.how_to_use')
        end
        expect(page).to have_current_path(how_to_use_path, ignore_query: true),
        'ヘッダーの[使い方]リンクから使い方ページへ遷移できませんでした'
      end
    end

    context 'ログインしている場合' do
      before do
        sign_in user
        visit root_path
      end

      it 'ヘッダーの「使い方」リンクをクリックした場合使い方ページへ遷移すること' do
        within('#navbarSupportedContent') do
          click_on I18n.t('header.how_to_use')
        end
        expect(page).to have_current_path(how_to_use_path, ignore_query: true),
        'ヘッダーの[使い方]リンクから使い方ページへ遷移できませんでした'
      end
    end
  end

  describe 'トップページからのナビゲーション確認' do
    before { visit root_path }

    it 'トップページの「詳しい使い方はこちら」リンクをクリックした場合使い方ページへ遷移すること' do
      click_on I18n.t('static_pages.top.how_to_use_link')
      expect(page).to have_current_path(how_to_use_path, ignore_query: true),
      '[詳しい使い方はこちら]リンクから使い方ページへ遷移できませんでした'
    end
  end
end
