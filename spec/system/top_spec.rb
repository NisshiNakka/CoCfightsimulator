require 'rails_helper'

RSpec.describe 'トップ画面', type: :system do
  let(:user) { create(:user) }
  before do
    visit root_path
  end

  it '正しいタイトルが表示されていること' do
    expect(page).to have_title("神話TRPG7版 戦闘シミュレーター | CoC Fight Simulator"), 'トップページのタイトルが正しくありません。'
  end

  describe 'ヘッダーUI確認' do
    context 'ロゴ表示' do
      it 'ロゴ画像が表示されること' do
        within('#logo-link') do
          expect(page).to have_css('img.header-logo'),
          'ヘッダーロゴ画像が表示されていません'
        end
      end

      it 'ロゴ画像にaltテキストが設定されていること' do
        within('#logo-link') do
          expect(page).to have_css('img[alt="CoC Fight Simulator ロゴ"]'),
          'ロゴ画像のaltテキストが設定されていません'
        end
      end

      it 'ロゴ画像のsrcにWebP画像が設定されていること' do
        within('#logo-link') do
          expect(page).to have_css('img[src*="logo_sumple"]'),
          'ロゴ画像にlogo_sumpleが使用されていません'
        end
      end

      it 'サイト名テキストがヘッダーロゴリンク内に含まれること' do
        within('#logo-link') do
          expect(page).to have_content('CoC Fight Simulator'),
          'サイト名テキストがヘッダーロゴリンク内に表示されていません'
        end
      end
    end

    context 'ナビリンク表示' do
      it '「使い方」リンクが表示されること' do
        within('#navbarSupportedContent') do
          expect(page).to have_link(I18n.t('header.how_to_use')),
          '使い方リンクが表示されていません'
        end
      end

      it 'ログインしていない場合「ログイン」リンクが表示されること' do
        within('#navbarSupportedContent') do
          expect(page).to have_link(I18n.t('header.login')),
          'ログインリンクが表示されていません'
        end
      end

      it 'ログインしていない場合「新規登録」リンクが表示されること' do
        within('#navbarSupportedContent') do
          expect(page).to have_link(I18n.t('header.registration')),
          '新規登録リンクが表示されていません'
        end
      end
    end

    context 'ログインしている場合のナビリンク表示' do
      before do
        sign_in user
        visit root_path
      end

      it '「キャラクターページ」ドロップダウントグルが表示されること' do
        within('#navbarSupportedContent') do
          expect(page).to have_css('#header-character-menu'),
          'キャラクターページドロップダウンが表示されていません'
        end
      end

      it '「ログアウト」リンクが表示されること' do
        within('#navbarSupportedContent') do
          expect(page).to have_link(I18n.t('header.logout')),
          'ログアウトリンクが表示されていません'
        end
      end

      it 'キャラクターページをクリックするとドロップダウンが表示されること' do
        find('#header-character-menu').click
        expect(page).to have_css('.dropdown-menu', visible: true),
        'ドロップダウンメニューが表示されませんでした'
      end
    end
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
