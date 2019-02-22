require_relative 'spec_helper'
require 'rspec'

require_relative 'core_spec'

describe BBLib do
  it 'has a version number' do
    expect(BBLib::VERSION).not_to be nil
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
    hash = { a: 1, b: 2, c: 4, d: { e: 5 } }
    expect(hash.reverse).to eq(d: { e: 5 }, c: 4, b: 2, a: 1)
    hash.reverse!
    expect(hash).to eq(d: { e: 5 }, c: 4, b: 2, a: 1)
  end

  it 'deep merges a hash' do
    a = { a: 1, b: [2, 3], c: { d: { e: 4, f: [5, 6, 7] } } }
    b = { b: [8], c: { d: { e: 9, f: 'test', g: 0 } } }
    expect(a.deep_merge(b)).to eq(a: 1, b: [2, 3, 8], c: { d: { e: 9, f: 'test', g: 0 } })
    expect(a.deep_merge(b, merge_arrays: false)).to eq(a: 1, b: [8], c: { d: { e: 9, f: 'test', g: 0 } })
    expect(a.deep_merge(b, overwrite: false)).to eq(a: 1, b: [2, 3, 8], c: { d: { e: [4, 9],
                                                                                  f: [5, 6, 7, 'test'], g: 0 } })
    a.deep_merge! b
    expect(a).to eq(a: 1, b: [2, 3, 8], c: { d: { e: 9, f: 'test', g: 0 } })
  end

  it 'places a key at the beginning of a hash (unshift)' do
    a = { b: 2 }
    a.unshift(a: 1)
    expect(a).to eq(a: 1, b: 2)
  end

  thash = { a: 1, b: 2, c: { d: [3, 4, 5, { e: 6 }], f: 7 }, g: 8, 'test' => { 'path' => 'here' }, e: 5 }


  it 'squishes hash' do
    expect(thash.squish).to eq('a'=>1, 'b'=>2, 'c.d.[0]'=>3, 'c.d.[1]'=>4, 'c.d.[2]'=>5, 'c.d.[3].e'=>6, 'c.f'=>7,
                               'g'=>8, 'test.path'=>'here', 'e'=>5)
  end

  squished = thash.squish

  it 'expands hash' do
    expect(squished.expand).to eq thash.keys_to_sym
  end

  it 'converts keys to strings' do
    expect(thash.keys_to_s).to eq('a'=>1, 'b'=>2, 'c'=>{ 'd'=>[3, 4, 5, { 'e'=>6 }], 'f'=>7 }, 'g'=>8, 'test'=>{ 'path'=>'here' }, 'e'=>5)
    bhash = thash.clone
    bhash.keys_to_s!
    expect(bhash).to eq('a'=>1, 'b'=>2, 'c'=>{ 'd'=>[3, 4, 5, { 'e'=>6 }], 'f'=>7 }, 'g'=>8, 'test'=>{ 'path'=>'here' }, 'e'=>5)
  end

  it 'converts keys to symbols' do
    expect(thash.keys_to_sym).to eq(a: 1, b: 2, c: { d: [3, 4, 5, { e: 6 }], f: 7 }, g: 8, test: { path: 'here' }, e: 5)
    bhash = thash.clone
    bhash.keys_to_sym!
    expect(bhash).to eq(a: 1, b: 2, c: { d: [3, 4, 5, { e: 6 }], f: 7 }, g: 8, test: { path: 'here' }, e: 5)
  end

  # Time

  it 'converts integers to duration strings' do
    expect(166.to_duration).to eq '2 mins 46 secs'
    expect(166.to_duration(input: :min)).to eq '2 hrs 46 mins'
  end

  it 'parses time from string' do
    expect('1min'.parse_duration(output: :sec)).to eq 60.0
    expect('1min 1min 2min'.parse_duration(output: :sec)).to eq 240.0
    expect('3.5s 1m 2h'.parse_duration(output: :sec)).to eq 7263.5
    expect('1day 2 min'.parse_duration(output: :sec)).to eq 86_520.0
    expect('1.25year'.parse_duration(output: :sec)).to eq 39_420_000.0
    expect('3mo 3 days'.parse_duration(output: :sec)).to eq 8_035_200.0
    expect('1506 seconds'.parse_duration(output: :sec)).to eq 1506.0
    expect('5000123 mil'.parse_duration(output: :sec)).to eq 5000.123
    expect('55hrs'.parse_duration(output: :sec)).to eq 198_000.0
    expect('1year 1month 1day 1hour 1 min 1 sec 1 mil'.parse_duration(output: :sec)).to eq 34_218_061.001
    expect('01:30'.parse_duration).to eq 90.0

    expect('1min'.parse_duration(output: :min)).to eq 1.0
    expect('1min 1min 2min'.parse_duration(output: :min)).to eq 4.0
    expect('3.5s 1m 2h'.parse_duration(output: :min)).to eq 121.05833333333334
    expect('1day 2 min'.parse_duration(output: :min)).to eq 1442.0
    expect('1.25year'.parse_duration(output: :min)).to eq 657_000.0
    expect('3mo 3 days'.parse_duration(output: :min)).to eq 133_920.0
    expect('1506 seconds'.parse_duration(output: :min)).to eq 25.1
    expect('5000123 mil'.parse_duration(output: :min)).to eq 83.33538333333334
    expect('55hrs'.parse_duration(output: :min)).to eq 3300.0
    expect('1year 1month 1day 1hour 1 min 1 sec 1 mil'.parse_duration(output: :min)).to eq 570_301.0166833333

    expect('1min'.parse_duration(output: :hour)).to eq 0.016666666666666666
    expect('1min 1min 2min'.parse_duration(output: :hour)).to eq 0.06666666666666667
    expect('3.5s 1m 2h'.parse_duration(output: :hour)).to eq 2.017638888888889
    expect('1day 2 min'.parse_duration(output: :hour)).to eq 24.033333333333335
    expect('1.25year'.parse_duration(output: :hour)).to eq 10_950.0
    expect('3mo 3 days'.parse_duration(output: :hour)).to eq 2232.0
    expect('1506 seconds'.parse_duration(output: :hour)).to eq 0.41833333333333333
    expect('5000123 mil'.parse_duration(output: :hour)).to eq 1.3889230555555556
    expect('55hrs'.parse_duration(output: :hour)).to eq 55.0
    expect('1year 1month 1day 1hour 1 min 1 sec 1 mil'.parse_duration(output: :hour)).to eq 9505.016944722222
  end

  # Array

  it 'interleaves array' do
    a = [1, 3, 5]
    b = [2, 4, 6]
    expect(a.interleave(b)).to eq [1, 2, 3, 4, 5, 6]
    a = [1, 3, 5]
    b = [2, 4, 6, 7, 8, 9]
    expect(a.interleave(b)).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9]
  end

  it 'multi splits arrays and strings' do
    expect('1&2||3,4TEST56666'.msplit('&', '||', ',', /6{3}/, /test/i)).to eq %w(1 2 3 4 5 6)
    a = ['1&2||', '3,4', '56666']
    expect(a.msplit('&', '||', ',', /6{3}/, /test/i)).to eq %w(1 2 3 4 5 6)
  end

  it 'gets diff of arrays' do
    expect([1, 2, 3, 5].diff([1, 2, 4])).to eq [3, 5, 4]
    expect([1, 2, 3, 5, 'test'].diff([1, 2, 4, nil, :test])).to eq [3, 5, 'test', 4, nil, :test]
  end

  # Cron

  # TODO: - Better Cron testing
  it 'parses cron syntax' do
    expect(BBLib::Cron.next('*/5 * * * * *') > Time.now).to eq true
    expect(BBLib::Cron.prev('*/5 * * * * *') < Time.now).to eq true
  end
end
