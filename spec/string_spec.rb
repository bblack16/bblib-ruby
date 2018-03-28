
describe BBLib do
  it 'makes a clean sym' do
    expect('test   one'.to_clean_sym).to eq :test_one
    expect('TTesST!!& tw$%o'.to_clean_sym).to eq :TTesST_tw_o
    expect(:already_a_sym.to_clean_sym).to eq :already_a_sym
    expect('Test This'.to_sym.to_clean_sym).to eq :Test_This
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
    expect('End, the'.move_articles).to eq 'The End'
    expect('the end'.move_articles(:back)).to eq 'end, The'
    expect('the best'.move_articles(:none)).to eq 'best'
    expect('best, an'.move_articles(:none)).to eq 'best'
    t = 'the test'
    t.move_articles!(:back)
    expect(t).to eq 'test, The'
  end

  it 'multi splits a string and array' do
    expect('Test|test,test.test'.msplit(',', '.', '|')).to eq %w(Test test test test)
    expect(['Test|test', 'test.test'].msplit(',', '.', '|')).to eq %w(Test test test test)
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
    expect(sent.method_case).to eq 'this_is_a_casing_test__o_k'
    expect(sent.camel_case(:upper)).to eq 'ThisIsACasingTestOk'
    expect(sent.delimited_case('=')).to eq 'This=is=a=casing=test=OK'
  end

  it 'verifies if a string is encapsulated by a char or string' do
    expect('(test)'.encap_by?('(')).to eq true
    expect('<test>'.encap_by?('<')).to eq true
    expect('[test]'.encap_by?('[')).to eq true
    expect('{test}'.encap_by?('{')).to eq true
    expect('1test1'.encap_by?('1')).to eq true
    expect('testtesttest'.encap_by?('test')).to eq true
    expect('hello test hello'.encap_by?('hello')).to eq true
    expect('(test'.encap_by?('(')).to eq false
    expect('[test'.encap_by?('[')).to eq false
  end

  it 'removes encapsulated characters or strings from a string' do
    expect('(test)'.uncapsulate('(')).to eq 'test'
    expect('<test>'.uncapsulate('<')).to eq 'test'
    expect('[test]'.uncapsulate('[')).to eq 'test'
    expect('{test}'.uncapsulate('{')).to eq 'test'
    expect('1test1'.uncapsulate('1')).to eq 'test'
    expect('testtesttest'.uncapsulate('test')).to eq 'test'
    expect('hello test hello'.uncapsulate('hello')).to eq ' test '
    expect('(test'.uncapsulate('(')).to eq 'test'
    expect('[test'.uncapsulate('[')).to eq 'test'
  end

  it 'converts roman numerals' do
    expect(2.to_roman).to eq 'II'
    expect('Toy story 3'.to_roman).to eq 'Toy story III'
    expect('Left IV Dead'.from_roman).to eq 'Left 4 Dead'
    expect('lIVe IIn fear'.to_roman).to eq 'lIVe IIn fear'
    t = 'Donkey Kong Country 3'
    expect(t.to_roman).to eq 'Donkey Kong Country III'
    t = 'Title VII'
    expect(t.from_roman).to eq 'Title 7'
  end

  it 'converts a string to a regular expression' do
    expect(/test/i).to eq '/test/i'.to_regex
    expect(/\:example\s\d\w/mix.inspect.to_regex).to eq /\:example\s\d\w/mix
  end

  it 'matches similarity between strings' do
    expect('test'.levenshtein_similarity('test')).to eq 100
    expect('test'.levenshtein_similarity('')).to eq 0
    expect('test'.levenshtein_similarity('te')).to eq 50
    expect('t'.levenshtein_distance('s')).to eq 1

    expect('test'.composition_similarity('test')).to eq 100
    expect('test'.composition_similarity('sett')).to eq 100
    expect('ruby'.composition_similarity('java')).to eq 0
    expect('ruby'.composition_similarity('rails')).to eq 20.0

    expect('Quake 3'.numeric_similarity('Quake 2')).to eq 50
    expect('Toy Story 3'.numeric_similarity('Star Trek 3')).to eq 100
    expect('Test'.numeric_similarity('D2').to_i).to eq 33

    expect('Quake 3'.phrase_similarity('Quake 2')).to eq 50
    expect('Toy Story 3'.phrase_similarity('Star Trek 3').to_i).to eq 33
    expect('Hello'.phrase_similarity('Hi').to_i).to eq 0

    expect('a'.qwerty_distance('s')).to eq 1
    expect('a'.qwerty_distance('ss')).to eq 11
  end
end
