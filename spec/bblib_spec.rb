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

  it 'squishes hash' do
    expect(thash.squish).to eq ({"a"=>1, "b"=>2, "c.d[0]"=>3, "c.d[1]"=>4, "c.d[2]"=>5, "c.d[3].e"=>6, "c.f"=>7, "g"=>8, "test.path"=>"here", "e"=>5})
  end

  squished = thash.squish

  it 'expands hash' do
    expect(squished.expand).to eq thash.keys_to_sym
  end

  it 'converts keys to strings' do
    expect(thash.keys_to_s).to eq ({"a"=>1, "b"=>2, "c"=>{"d"=>[3, 4, 5, {"e"=>6}], "f"=>7}, "g"=>8, "test"=>{"path"=>"here"}, "e"=>5})
  end

  it 'converts keys to symbols' do
    expect(thash.keys_to_sym).to eq ({:a=>1, :b=>2, :c=>{:d=>[3, 4, 5, {:e=>6}], :f=>7}, :g=>8, :test=>{:path=>"here"}, :e=>5})
  end

end
