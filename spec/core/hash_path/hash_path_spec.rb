
describe BBLib do
  thash = { a: 1, b: 2, c: { d: [3, 4, 5, { e: 6 }], f: 7 }, g: 8, 'test' => { 'path' => 'here' }, e: 5 }

  myarray = [
    { title: 'Catan', cost: 41.99 },
    { title: 'Mouse Trap', cost: 5.50 },
    { title: 'Chess', cost: 25.99 }
  ]

  it 'navigates hash' do
    expect(thash.hash_path('a')).to eq [1]
    expect(thash.hash_path('..e')).to eq [6, 5]
    expect(thash.hash_path('c.d.[3].e')).to eq [6]
    expect(thash.hash_path('test.path')).to eq ['here']
    expect(myarray.hpath('[0..-1]($[:cost] > 10).title')).to eq %w(Catan Chess)

    nhash = { a: [1, 2], b: { a: 3 } }
    expect(nhash.hash_path('..a')).to eq [[1, 2], 3]
    expect(nhash.hash_path('a')).to eq [[1, 2]]
  end
end
