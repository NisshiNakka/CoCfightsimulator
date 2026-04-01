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
