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
end
