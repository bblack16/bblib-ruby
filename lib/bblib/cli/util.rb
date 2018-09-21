require 'io/console'
require 'io/wait'

module BBLib
  module Console

    DEFAULT_FILE_EDITORS = %w{vim vi notepad++ notepad}.freeze

    # Simple method to open a file in a system text editor. The
    # text editor can be specified otherwise the first default
    # editor that can be found in the path will be used
    def self.edit_file(file, editor = default_editor)
      pid = spawn("#{editor} \"#{file}\"")
      Process.wait(pid)
    end

    def self.default_editor
      DEFAULT_FILE_EDITORS.find { |editor| OS.which(editor) }
    end

    def self.confirm?(message = 'Confirm?', yes: 'y', no: 'n', default: true, enter_is_default: true)
      response = nil
      until response == yes || response == no
        # TODO Support carriage return to overwrite line
        # print "\b" if response
        print "#{message} [#{default ? 'Y/n' : 'y/N'}]: "
        response = gets.chomp.downcase
        response = default ? yes : no if enter_is_default && response.empty?
      end
      response == yes
    end

    # TODO Fix this function. Currently requires two hits of enter to move on.
    def self.get(limit: nil)
      str = ''
      loop do
        char = STDIN.raw(&:getc)
        STDOUT.print char
        break if ["\r", "\n", "\r\n"].include?(char)
        str += char
      end
      str.chomp
    end

  end
end
