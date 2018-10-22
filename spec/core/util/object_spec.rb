
describe BBLib do
  it 'creates a new class' do
    expect(defined?(BBLib::TestClass99) ? true : false).to eq false
    BBLib.class_create('BBLib::TestClass99')
    expect(defined?(BBLib::TestClass99) ? true : false).to eq true
    expect(BBLib::TestClass99.class).to eq Class
  end
end
