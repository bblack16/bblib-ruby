require_relative 'spec_helper'
require 'rspec'

describe BBLib do
  it 'has a version number' do
    expect(BBLib::VERSION).not_to be nil
  end

  # String

  it 'makes a clean sym' do
    expect('test   one'.to_clean_sym).to eq :test_one
    expect('TTesST!!& tw$%o'.to_clean_sym).to eq :TTesST_tw_o
    expect(:already_a_sym.to_clean_sym).to eq :already_a_sym
    expect("Test This".to_sym.to_clean_sym).to eq :Test_This
  end

  it 'drops symbols from string' do
    expect('t.e,{s(t_)}'.drop_symbols).to eq 'test'
    t = 't!e@s#%t'
    t.drop_symbols!
    expect(t).to eq 'test'
  end

  it 'extracts numbers from string' do
    t = '1 2 3.4 5.67 .8 9.0 1231.12123'
    expect(t.extract_numbers).to eq [1, 2, 3.4, 5.67, 8, 9.0, 1231.12123]
    expect(t.extract_floats).to eq [3.4, 5.67, 9.0, 1231.12123]
    expect(t.extract_integers).to eq [1, 2, 8]
  end

  it 'move articles in string' do
    expect('End, the'.move_articles).to eq "The End"
    expect('the end'.move_articles :back).to eq "end, The"
    expect('the best'.move_articles :none).to eq "best"
    expect('best, an'.move_articles :none).to eq "best"
    t = 'the test'
    t.move_articles!(:back)
    expect(t).to eq 'test, The'
  end

  it 'multi splits a string and array' do
    expect('Test|test,test.test'.msplit ',', '.', '|').to eq ["Test", "test", "test", "test"]
    expect(['Test|test','test.test'].msplit ',', '.', '|').to eq ["Test", "test", "test", "test"]
  end

  it 'converts a sentence to casings' do
    sent = 'This is a casing-test. OK?'
    expect(sent.title_case).to eq 'This Is a Casing-Test. Ok?'
    expect(sent.title_case(first_only: true)).to eq 'This Is a Casing-Test. OK?'
    expect(sent.start_case).to eq 'This Is A Casing-Test. Ok?'
    expect(sent.start_case(first_only: true)).to eq 'This Is A Casing-Test. OK?'
    expect(sent.snake_case).to eq 'This_is_a_casing_test_OK'
    expect(sent.spinal_case).to eq 'This-is-a-casing-test-OK'
    expect(sent.train_case).to eq 'This-Is-A-Casing-Test-Ok'
    expect(sent.camel_case).to eq 'thisIsACasingTestOk'
    expect(sent.camel_case(:upper)).to eq 'ThisIsACasingTestOk'
    expect(sent.delimited_case('=')).to eq 'This=is=a=casing=test=OK'
  end

  it 'verifies if a string is encapsulated by a char or string' do
    expect("(test)".encap_by?("(")).to eq true
    expect("<test>".encap_by?("<")).to eq true
    expect("[test]".encap_by?("[")).to eq true
    expect("{test}".encap_by?("{")).to eq true
    expect("1test1".encap_by?("1")).to eq true
    expect("testtesttest".encap_by?("test")).to eq true
    expect("hello test hello".encap_by?("hello")).to eq true
    expect("(test".encap_by?("(")).to eq false
    expect("[test".encap_by?("[")).to eq false
  end

  it 'removes encapsulated characters or strings from a string' do
    expect("(test)".uncapsulate("(")).to eq 'test'
    expect("<test>".uncapsulate("<")).to eq 'test'
    expect("[test]".uncapsulate("[")).to eq 'test'
    expect("{test}".uncapsulate("{")).to eq 'test'
    expect("1test1".uncapsulate("1")).to eq 'test'
    expect("testtesttest".uncapsulate("test")).to eq 'test'
    expect("hello test hello".uncapsulate("hello")).to eq ' test '
    expect("(test".uncapsulate("(")).to eq 'test'
    expect("[test".uncapsulate("[")).to eq 'test'
  end

  it 'converts roman numerals' do
    expect(2.to_roman).to eq 'II'
    expect("Toy story 3".to_roman).to eq 'Toy story III'
    expect('Left IV Dead'.from_roman).to eq 'Left 4 Dead'
    expect('lIVe IIn fear'.to_roman).to eq 'lIVe IIn fear'
    t = 'Donkey Kong Country 3'
    t.to_roman!
    expect(t).to eq 'Donkey Kong Country III'
    t = 'Title VII'
    t.from_roman!
    expect(t).to eq 'Title 7'
  end

  # Number

  it 'keep number between min and max' do
    expect(BBLib.keep_between(2, 1, 10)).to eq 2
    expect(BBLib.keep_between(-2, 1, 10)).to eq 1
    expect(BBLib.keep_between(12, 1, 10)).to eq 10
    expect(BBLib.keep_between(-100, nil, 10)).to eq -100
    expect(BBLib.keep_between(2000, 1, nil)).to eq 2000
    expect(BBLib.keep_between(1.5, 1.6, 10.123)).to eq 1.6
    expect(BBLib.keep_between(0, nil, nil)).to eq 0
  end

  # Hash

  it 'reverses hash keys' do
    hash = {a:1,b:2,c:4,d:{e:5}}
    expect(hash.reverse).to eq ({:d=>{:e=>5}, :c=>4, :b=>2, :a=>1})
    hash.reverse!
    expect(hash).to eq ({:d=>{:e=>5}, :c=>4, :b=>2, :a=>1})
  end

  it 'deep merges a hash' do
    a = {a:1, b:[2,3], c:{d:{e:4, f:[5,6,7]}}}
    b = {b:[8], c:{d:{e:9, f:'test', g:0}}}
    expect(a.deep_merge b).to eq ({:a=>1, :b=>[2, 3, 8], :c=>{:d=>{:e=>9, :f=>"test", :g=>0}}})
    expect(a.deep_merge b, merge_arrays: false).to eq ({:a=>1, :b=>[8], :c=>{:d=>{:e=>9, :f=>"test", :g=>0}}})
    expect(a.deep_merge b, overwrite: false).to eq ({:a=>1, :b=>[2, 3, 8], :c=>{:d=>{:e=>[4, 9], :f=>[5, 6, 7, "test"], :g=>0}}})
    a.deep_merge! b
    expect(a).to eq ({:a=>1, :b=>[2, 3, 8], :c=>{:d=>{:e=>9, :f=>"test", :g=>0}}})
  end

  it 'places a key at the beginning of a hash (unshift)' do
    a = {b: 2}
    a.unshift(a: 1)
    expect(a).to eq ({a:1, b:2})
  end

  # Hash Path

  thash = {a:1, b:2, c:{d:[3,4,5,{e:6}], f:7},g:8, 'test' => {'path' => 'here'}, e:5 }
  myarray = [
    {title: 'Catan', cost: 41.99},
    {title: 'Mouse Trap', cost: 5.50},
    {title: 'Chess', cost: 25.99}
  ]

  it 'navigates hash' do
    expect(thash.hash_path('a')).to eq [1]
    expect(thash.hash_path('..e')).to eq [6,5]
    expect(thash.hash_path('c.d.[3].e')).to eq [6]
    expect(thash.hash_path('test.path')).to eq ['here']
    expect(myarray.hpath('[0..-1]($[:cost] > 10).title')).to eq ["Catan", "Chess"]

    nhash = {a:[1,2], b:{ a: 3}}
    expect(nhash.hash_path('..a')).to eq [[1,2],3]
    expect(nhash.hash_path('a')).to eq [[1,2]]
  end

  it 'squishes hash' do
    expect(thash.squish).to eq ({"a"=>1, "b"=>2, "c.d.[0]"=>3, "c.d.[1]"=>4, "c.d.[2]"=>5, "c.d.[3].e"=>6, "c.f"=>7, "g"=>8, "test.path"=>"here", "e"=>5})
  end

  squished = thash.squish

  it 'expands hash' do
    expect(squished.expand).to eq thash.keys_to_sym
  end

  it 'converts keys to strings' do
    expect(thash.keys_to_s).to eq ({"a"=>1, "b"=>2, "c"=>{"d"=>[3, 4, 5, {"e"=>6}], "f"=>7}, "g"=>8, "test"=>{"path"=>"here"}, "e"=>5})
    bhash = thash.clone
    bhash.keys_to_s!
    expect(bhash).to eq ({"a"=>1, "b"=>2, "c"=>{"d"=>[3, 4, 5, {"e"=>6}], "f"=>7}, "g"=>8, "test"=>{"path"=>"here"}, "e"=>5})
  end

  it 'converts keys to symbols' do
    expect(thash.keys_to_sym).to eq ({:a=>1, :b=>2, :c=>{:d=>[3, 4, 5, {:e=>6}], :f=>7}, :g=>8, :test=>{:path=>"here"}, :e=>5})
    bhash = thash.clone
    bhash.keys_to_sym!
    expect(bhash).to eq ({:a=>1, :b=>2, :c=>{:d=>[3, 4, 5, {:e=>6}], :f=>7}, :g=>8, :test=>{:path=>"here"}, :e=>5})
  end

  # Hash Path Proc

  th = {test: 'This is', 'two' => 'a test'}

  it 'appends or prepends to hash' do
    expect(th.hash_path_proc(:prepend, 'two', 'This is ')).to eq ({test: 'This is', 'two' => 'This is a test'})
    expect(th.hash_path_proc(:append, 'test', ' a test')).to eq ({test: 'This is a test', 'two' => 'This is a test'})
  end

  it 'evals a hash' do
    expect( ({a: {b: 2 } }).hash_path_proc(:eval, 'a.b', '$ * 10') ).to eq ({a: {b: 20 } })
    expect( ({a: {'test' => 'TEST' } }).hash_path_proc(:eval, 'a.test', '"$".downcase + " passed"') ).to eq ({a: {'test' => 'test passed' } })
  end

  it 'splits a hash value' do
    expect( ({'test' => 'this,is,a,list'}).hash_path_proc(:split, 'test', ',') ).to eq ({'test' => ['this','is','a','list']})
    expect( ({'test' => 'this,is|another.list'}).hash_path_proc(:split, 'test', [',', '.', '|']) ).to eq ({'test' => ['this','is','another','list']})
  end

  # Time

  it 'converts integers to duration strings' do
    expect(166.to_duration).to eq '2 mins 46 secs'
    expect(166.to_duration(input: :min)).to eq '2 hrs 46 mins'
  end

  it 'parses time from string' do
    expect('1min'.parse_duration output: :sec).to eq 60.0
    expect('1min 1min 2min'.parse_duration output: :sec).to eq 240.0
    expect('3.5s 1m 2h'.parse_duration output: :sec).to eq 7263.5
    expect('1day 2 min'.parse_duration output: :sec).to eq 86520.0
    expect('1.25year'.parse_duration output: :sec).to eq 39420000.0
    expect('3mo 3 days'.parse_duration output: :sec).to eq 8035200.0
    expect('1506 seconds'.parse_duration output: :sec).to eq 1506.0
    expect('5000123 mil'.parse_duration output: :sec).to eq 5000.123
    expect('55hrs'.parse_duration output: :sec).to eq 198000.0
    expect('1year 1month 1day 1hour 1 min 1 sec 1 mil'.parse_duration output: :sec).to eq 34218061.001
    expect('01:30'.parse_duration).to eq 90.0

    expect('1min'.parse_duration output: :min).to eq 1.0
    expect('1min 1min 2min'.parse_duration output: :min).to eq 4.0
    expect('3.5s 1m 2h'.parse_duration output: :min).to eq 121.05833333333334
    expect('1day 2 min'.parse_duration output: :min).to eq 1442.0
    expect('1.25year'.parse_duration output: :min).to eq 657000.0
    expect('3mo 3 days'.parse_duration output: :min).to eq 133920.0
    expect('1506 seconds'.parse_duration output: :min).to eq 25.1
    expect('5000123 mil'.parse_duration output: :min).to eq 83.33538333333334
    expect('55hrs'.parse_duration output: :min).to eq 3300.0
    expect('1year 1month 1day 1hour 1 min 1 sec 1 mil'.parse_duration output: :min).to eq 570301.0166833333

    expect('1min'.parse_duration output: :hour).to eq 0.016666666666666666
    expect('1min 1min 2min'.parse_duration output: :hour).to eq 0.06666666666666667
    expect('3.5s 1m 2h'.parse_duration output: :hour).to eq 2.017638888888889
    expect('1day 2 min'.parse_duration output: :hour).to eq 24.033333333333335
    expect('1.25year'.parse_duration output: :hour).to eq 10950.0
    expect('3mo 3 days'.parse_duration output: :hour).to eq 2232.0
    expect('1506 seconds'.parse_duration output: :hour).to eq 0.41833333333333333
    expect('5000123 mil'.parse_duration output: :hour).to eq 1.3889230555555556
    expect('55hrs'.parse_duration output: :hour).to eq 55.0
    expect('1year 1month 1day 1hour 1 min 1 sec 1 mil'.parse_duration output: :hour).to eq 9505.016944722222
  end

  # Array

  it 'interleaves array' do
    a, b = [1,3,5], [2, 4, 6]
    expect(a.interleave(b)).to eq [1, 2, 3, 4, 5, 6]
    a, b = [1,3,5], [2, 4, 6, 7, 8, 9]
    expect(a.interleave(b)).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9]
  end

  it 'multi splits arrays and strings' do
    expect('1&2||3,4TEST56666'.msplit('&', '||', ',', /6{3}/, /test/i)).to eq ['1','2','3','4','5','6']
    a = ['1&2||', '3,4', '56666']
    expect(a.msplit('&', '||', ',', /6{3}/, /test/i)).to eq ['1','2','3','4','5','6']
  end

  it 'gets diff of arrays' do
    expect([1,2,3,5].diff([1,2,4])).to eq [3,5,4]
    expect([1,2,3,5,'test'].diff([1,2,4,nil, :test])).to eq [3, 5, "test", 4, nil, :test]
  end

  it 'converts a hash to xml' do
    expect(({test: [1,2], name: 'John', data: { id: 4, title: 'Something'}}).to_xml).to eq "<test>\n\t1\n</test>\n<test>\n\t2\n</test>\n<name>\n\tJohn\n</name>\n<data>\n\t<id>\n\t\t4\n\t</id>\n\t<title>\n\t\tSomething\n\t</title>\n</data>"
  end

  # Cron

  # TODO - Better Cron testing
  it 'parses cron syntax' do
    expect(BBLib::Cron.next('*/5 * * * * *') > Time.now).to eq true
    expect(BBLib::Cron.prev('*/5 * * * * *') < Time.now).to eq true
  end

end
