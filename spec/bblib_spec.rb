require_relative 'spec_helper'

describe BBLib do
  it 'has a version number' do
    expect(BBLib::VERSION).not_to be nil
  end

  # Hash Path

  thash = {a:1, b:2, c:{d:[3,4,5,{e:6}], f:7},g:8, 'test' => {'path' => 'here'}, e:5 }

  it 'navigates hash' do
    expect(thash.hash_path('a')).to eq [1]
    expect(thash.hash_path('..e')).to eq [6,5]
    expect(thash.hash_path('c.d[3].e')).to eq [6]
    expect(thash.hash_path('test.path')).to eq ['here']
  end

end
