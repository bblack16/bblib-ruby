require_relative 'spec_helper'
require 'rspec'

describe BBLib do
  it 'has a version number' do
    expect(BBLib::VERSION).not_to be nil
  end

  # String

  it 'drops symbols from string' do
    expect('t.e,{s(t_)}'.drop_symbols).to eq 'test'
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
    expect(({a:1,b:2,c:4,d:{e:5}}).reverse).to eq ({:d=>{:e=>5}, :c=>4, :b=>2, :a=>1})
  end

  it 'deep merges a hash' do
    a = {a:1, b:[2,3], c:{d:{e:4, f:[5,6,7]}}}
    b = {b:[8], c:{d:{e:9, f:'test', g:0}}}
    expect(a.deep_merge b).to eq ({:a=>1, :b=>[2, 3, 8], :c=>{:d=>{:e=>9, :f=>"test", :g=>0}}})
    expect(a.deep_merge b, merge_arrays: false).to eq ({:a=>1, :b=>[8], :c=>{:d=>{:e=>9, :f=>"test", :g=>0}}})
    expect(a.deep_merge b, overwrite_vals: false).to eq ({:a=>1, :b=>[2, 3, 8], :c=>{:d=>{:e=>[4, 9], :f=>[5, 6, 7, "test"], :g=>0}}})
  end

  # Hash Path

  thash = {a:1, b:2, c:{d:[3,4,5,{e:6}], f:7},g:8, 'test' => {'path' => 'here'}, e:5 }

  it 'navigates hash' do
    expect(thash.hash_path('a')).to eq [1]
    expect(thash.hash_path('..e')).to eq [6,5]
    expect(thash.hash_path('c.d[3].e')).to eq [6]
    expect(thash.hash_path('test.path')).to eq ['here']

    nhash = {a:[1,2], b:{ a: 3}}
    expect(nhash.hash_path('..a')).to eq [[1,2],3]
    expect(nhash.hash_path('a')).to eq [[1,2]]
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

end
