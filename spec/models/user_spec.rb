require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe 'バリデーション' do
    context '正常系' do
      it 'ユーザー名、メールアドレスがあり、パスワードは6文字以上であれば有効であること' do
        expect(user).to be_valid
        expect(user.errors).to be_empty
      end
    end

    context '異常系' do
      describe '必須項目のチェック' do
        it 'ユーザー名、メールアドレス、パスワードは必須項目であること' do
          user.email = nil
          user.name = nil
          user.password = nil
          user.valid?
          expect(user.errors[:email]).to include('を入力してください')
          expect(user.errors[:name]).to include('を入力してください')
          expect(user.errors[:password]).to include('を入力してください')
        end
      end

      describe 'ユニーク制約のチェック' do
        it 'メールアドレスが重複している場合、無効であること' do
          user1 = create(:user)
          user2 = build(:user, email: user1.email)
          expect(user2).to be_invalid
          expect(user2.errors[:email]).to include('このメールアドレスは登録できません')
        end
      end

      describe 'メールアドレスの形式チェック' do
        it '@がない場合、無効であること' do
          user.email = 'aaaa'
          expect(user).to be_invalid
          expect(user.errors[:email]).to include('は不正な値です')
        end

        it '@のみの場合、無効であること' do
          user.email = '@'
          expect(user).to be_invalid
          expect(user.errors[:email]).to include('は不正な値です')
        end

        it 'ローカル部のみの場合、無効であること' do
          user.email = 'aaaa@'
          expect(user).to be_invalid
          expect(user.errors[:email]).to include('は不正な値です')
        end

        it 'ドメイン部のみの場合、無効であること' do
          user.email = '@aaaa'
          expect(user).to be_invalid
          expect(user.errors[:email]).to include('は不正な値です')
        end
      end

      describe '文字数制限のチェック' do
        it 'ユーザー名が51文字の場合、無効であること' do
          user.name = 'a' * 51
          expect(user).to be_invalid
          expect(user.errors[:name]).to include('は50文字以内で入力してください')
        end

        it 'パスワードが5文字の場合、無効であること' do
          user.password = 'a' * 5
          expect(user).to be_invalid
          expect(user.errors[:password]).to include('は6文字以上で入力してください')
        end

        it 'パスワードが129文字の場合、無効であること' do
          user.password = 'a' * 129
          expect(user).to be_invalid
          expect(user.errors[:password]).to include('は128文字以内で入力してください')
        end
      end
    end
  end

  describe 'Google OmniAuth 連携' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "123456789",
        info: OmniAuth::AuthHash::InfoHash.new(
          email: "google_user@example.com",
          name: "Google User"
        )
      )
    end

    describe '.from_omniauth' do
      context '該当する provider + uid のユーザーが存在しない場合' do
        it '新規ユーザーを作成すること' do
          expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
        end

        it 'Google から取得したメールアドレスが設定されること' do
          user = User.from_omniauth(auth)
          expect(user.email).to eq "google_user@example.com"
        end

        it 'Google から取得した名前が設定されること' do
          user = User.from_omniauth(auth)
          expect(user.name).to eq "Google User"
        end

        it 'provider が google_oauth2 に設定されること' do
          user = User.from_omniauth(auth)
          expect(user.provider).to eq "google_oauth2"
        end

        it 'uid が設定されること' do
          user = User.from_omniauth(auth)
          expect(user.uid).to eq "123456789"
        end
      end

      context '同じ provider + uid のユーザーが既に存在する場合' do
        let!(:existing_user) { create(:user, provider: "google_oauth2", uid: "123456789", email: "google_user@example.com") }

        it '新規ユーザーを作成しないこと' do
          expect { User.from_omniauth(auth) }.not_to change(User, :count)
        end

        it '既存ユーザーを返すこと' do
          user = User.from_omniauth(auth)
          expect(user.id).to eq existing_user.id
        end
      end

      context '同じメールアドレスで email/password ユーザーが既に存在する場合' do
        let!(:existing_user) { create(:user, email: "google_user@example.com", provider: nil, uid: nil) }

        it '新規ユーザーが作成されないこと' do
          expect { User.from_omniauth(auth) }.not_to change(User, :count)
        end

        it '既存ユーザーに provider と uid が紐づけられること' do
          User.from_omniauth(auth)
          existing_user.reload
          expect(existing_user.provider).to eq "google_oauth2"
          expect(existing_user.uid).to eq "123456789"
        end

        it '既存ユーザーを返すこと' do
          user = User.from_omniauth(auth)
          expect(user.id).to eq existing_user.id
        end
      end
    end

    describe '#password_required?' do
      context 'provider が設定されていない通常ユーザーの場合' do
        it 'パスワードが必須であること' do
          user = build(:user, provider: nil, password: nil)
          user.valid?
          expect(user.errors[:password]).to include('を入力してください')
        end
      end

      context 'provider が設定されている OAuth ユーザーの場合' do
        it 'パスワードなしでも有効であること' do
          user = build(:user, provider: "google_oauth2", uid: "123456789", password: nil, password_confirmation: nil)
          expect(user).to be_valid
        end
      end
    end

    describe '#update_without_current_password' do
      let(:oauth_user) { create(:user, provider: "google_oauth2", uid: "123456789") }

      it '名前を更新できること' do
        oauth_user.update_without_current_password({ name: "新しい名前" })
        expect(oauth_user.reload.name).to eq "新しい名前"
      end

      it 'password が空の場合、パスワード変更なしで更新されること' do
        original_password = oauth_user.encrypted_password
        oauth_user.update_without_current_password({ name: "新しい名前", password: "", password_confirmation: "" })
        expect(oauth_user.reload.encrypted_password).to eq original_password
      end
    end
  end

  describe 'サイトアイコン' do
    describe '定数' do
      describe 'SPECIAL_ICONS' do
        it '"defaults" が含まれること' do
          expect(User::SPECIAL_ICONS).to include("defaults")
        end

        it '"none" が含まれること' do
          expect(User::SPECIAL_ICONS).to include("none")
        end

        it '2種類のみであること' do
          expect(User::SPECIAL_ICONS.size).to eq 2
        end
      end

      describe 'COLLECTABLE_DICE_KEYS' do
        it '22種類のダイス画像が含まれること' do
          expect(User::COLLECTABLE_DICE_KEYS.size).to eq 22
        end

        it '"defaults" が含まれないこと' do
          expect(User::COLLECTABLE_DICE_KEYS).not_to include("defaults")
        end

        it '"none" が含まれないこと' do
          expect(User::COLLECTABLE_DICE_KEYS).not_to include("none")
        end
      end

      describe 'MAX_TICKETS' do
        it 'COLLECTABLE_DICE_KEYS の数と一致すること' do
          expect(User::MAX_TICKETS).to eq User::COLLECTABLE_DICE_KEYS.size
        end
      end
    end

    describe 'バリデーション' do
      context '正常系' do
        it '"defaults"（デフォルト値）は有効であること' do
          user.site_icon = "defaults"
          expect(user).to be_valid
        end

        it '"none"（表示しない）は有効であること' do
          user.site_icon = "none"
          expect(user).to be_valid
        end

        it '解放済みのダイス画像は有効であること' do
          persisted_user = create(:user)
          create(:user_dice_unlock, user: persisted_user, dice_key: "cat/cat_azuki_webp")
          persisted_user.site_icon = "cat/cat_azuki_webp"
          expect(persisted_user).to be_valid
        end
      end

      context '異常系' do
        it '未解放のダイス画像は無効であること' do
          persisted_user = create(:user)
          persisted_user.site_icon = "cat/cat_azuki_webp"
          expect(persisted_user).to be_invalid
          expect(persisted_user.errors[:site_icon]).to be_present
        end

        it '許可リスト外の値は無効であること' do
          user.site_icon = "invalid/path"
          expect(user).to be_invalid
          expect(user.errors[:site_icon]).to be_present
        end

        it '空文字列は無効であること' do
          user.site_icon = ""
          expect(user).to be_invalid
        end
      end
    end

    describe '#site_icon_path' do
      it '"defaults" のとき logo_defaults.webp のパスを返すこと' do
        user.site_icon = "defaults"
        expect(user.site_icon_path).to eq "all_dice/logo_defaults.webp"
      end

      it '"none" のとき nil を返すこと' do
        user.site_icon = "none"
        expect(user.site_icon_path).to be_nil
      end

      it 'ダイス画像を選択したとき正しいパスを返すこと' do
        user.site_icon = "cat/cat_azuki_webp"
        expect(user.site_icon_path).to eq "all_dice/cat/cat_azuki_webp.webp"
      end

      it '別のダイス画像でも正しいパスを返すこと' do
        user.site_icon = "cthulhu/cthulhu_webp"
        expect(user.site_icon_path).to eq "all_dice/cthulhu/cthulhu_webp.webp"
      end
    end
  end

  describe 'ダイスコレクション' do
    let(:user) { create(:user) }

    describe '#unlocked_dice_keys' do
      it '解放済みダイスのキー一覧を返すこと' do
        create(:user_dice_unlock, user: user, dice_key: "cat/cat_azuki_webp")
        create(:user_dice_unlock, user: user, dice_key: "color/black")
        expect(user.unlocked_dice_keys).to contain_exactly("cat/cat_azuki_webp", "color/black")
      end

      it '解放済みダイスがない場合は空の配列を返すこと' do
        expect(user.unlocked_dice_keys).to eq []
      end
    end

    describe '#available_site_icons' do
      it '新規ユーザーは SPECIAL_ICONS のみ選択可能であること' do
        expect(user.available_site_icons).to match_array(User::SPECIAL_ICONS)
      end

      it '解放済みダイスが追加されること' do
        create(:user_dice_unlock, user: user, dice_key: "cat/cat_azuki_webp")
        expect(user.available_site_icons).to include("cat/cat_azuki_webp")
        expect(user.available_site_icons).to include("defaults")
        expect(user.available_site_icons).to include("none")
      end
    end

    describe '#dice_unlocked?' do
      it '解放済みのダイスに対して true を返すこと' do
        create(:user_dice_unlock, user: user, dice_key: "cat/cat_azuki_webp")
        expect(user.dice_unlocked?("cat/cat_azuki_webp")).to be true
      end

      it '未解放のダイスに対して false を返すこと' do
        expect(user.dice_unlocked?("cat/cat_azuki_webp")).to be false
      end
    end

    describe '#all_dice_collected?' do
      it '未収集のダイスがある場合は false を返すこと' do
        expect(user.all_dice_collected?).to be false
      end

      it '全ダイスを収集した場合は true を返すこと' do
        User::COLLECTABLE_DICE_KEYS.each do |key|
          create(:user_dice_unlock, user: user, dice_key: key)
        end
        expect(user.all_dice_collected?).to be true
      end
    end

    describe '#use_ticket!' do
      context 'チケットがあり、未収集ダイスがある場合' do
        before { user.update!(reward_tickets: 1) }

        it 'ランダムにダイスを解放すること' do
          expect { user.use_ticket! }.to change { user.dice_unlocks.count }.by(1)
        end

        it 'チケットを1枚消費すること' do
          expect { user.use_ticket! }.to change { user.reload.reward_tickets }.by(-1)
        end

        it '解放したダイスのキーを返すこと' do
          result = user.use_ticket!
          expect(User::COLLECTABLE_DICE_KEYS).to include(result)
        end

        it '同じダイスを二重解放しないこと' do
          user.update!(reward_tickets: 22)
          22.times { user.use_ticket! }
          expect(user.dice_unlocks.pluck(:dice_key).uniq.size).to eq 22
        end
      end

      context 'チケットがない場合' do
        before { user.update!(reward_tickets: 0) }

        it 'InsufficientTicketsError を発生させること' do
          expect { user.use_ticket! }.to raise_error(User::InsufficientTicketsError)
        end

        it 'ダイスが解放されないこと' do
          expect { user.use_ticket! rescue nil }.not_to change { user.dice_unlocks.count }
        end
      end

      context '全ダイスを収集済みの場合' do
        before do
          user.update!(reward_tickets: 1)
          User::COLLECTABLE_DICE_KEYS.each do |key|
            create(:user_dice_unlock, user: user, dice_key: key)
          end
        end

        it 'AllDiceCollectedError を発生させること' do
          expect { user.use_ticket! }.to raise_error(User::AllDiceCollectedError)
        end
      end
    end
  end

  describe 'チュートリアル' do
    let(:user) { create(:user) }

    describe '#tutorial_active?' do
      context 'tutorial_step が 0 の場合' do
        it 'false を返すこと' do
          user.update!(tutorial_step: 0)
          expect(user.tutorial_active?).to be false
        end
      end

      context 'tutorial_step が 1 以上の場合' do
        it 'tutorial_step=1 のとき true を返すこと' do
          user.update!(tutorial_step: 1)
          expect(user.tutorial_active?).to be true
        end

        it 'tutorial_step=6 のとき true を返すこと' do
          user.update!(tutorial_step: 6)
          expect(user.tutorial_active?).to be true
        end
      end
    end

    describe '#advance_tutorial!' do
      it 'tutorial_step を 1 インクリメントすること' do
        user.update!(tutorial_step: 1)
        expect { user.advance_tutorial! }.to change { user.reload.tutorial_step }.from(1).to(2)
      end

      it 'tutorial_step=5 のとき 6 に進むこと' do
        user.update!(tutorial_step: 5)
        user.advance_tutorial!
        expect(user.reload.tutorial_step).to eq 6
      end

      it 'tutorial_step=6（最終ステップ）のとき 0 にリセットすること' do
        user.update!(tutorial_step: 6)
        user.advance_tutorial!
        expect(user.reload.tutorial_step).to eq 0
      end
    end

    describe '#dismiss_tutorial!' do
      it 'tutorial_step を 0 にすること' do
        user.update!(tutorial_step: 3)
        user.dismiss_tutorial!
        expect(user.reload.tutorial_step).to eq 0
      end

      it 'tutorial_step がすでに 0 のとき 0 のままであること' do
        user.update!(tutorial_step: 0)
        user.dismiss_tutorial!
        expect(user.reload.tutorial_step).to eq 0
      end
    end
  end
end
