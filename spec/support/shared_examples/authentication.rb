RSpec.shared_examples 'require login' do
  it 'ログインページにリダイレクトされること' do
    visit root_path
    sign_out user
    visit path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true),
      'ログイン画面へ遷移していません'
  end
end
